import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import '../models/link_config.dart';
import '../models/link_status.dart';
import '../printing/driver_factory.dart';
import '../platform/android_service.dart';
import '../services/app_settings_repository.dart';
import '../services/connection_manager.dart';
import '../services/connection_registry.dart';
import '../services/fs_api_client.dart';
import '../services/push_listener.dart';
import '../services/settings_repository.dart';
import '../services/stores.dart';
import '../services/unconfirmed_store.dart';

/// Almacenes reales; los tests los sobrescriben con versiones en memoria.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) => PrefsStore());

final secretStoreProvider = Provider<SecretStore>((ref) {
  // En escritorio el llavero del sistema (macOS) requiere firmar con un
  // certificado de desarrollo; para no depender de ello, las API keys se
  // guardan en el almacén clave-valor. En móvil (iOS/Android) sí se usa el
  // llavero seguro del sistema.
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return KeyValueSecretStore(ref.watch(keyValueStoreProvider));
  }
  return SecureSecretStore();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    store: ref.watch(keyValueStoreProvider),
    secrets: ref.watch(secretStoreProvider),
  );
});

final registryProvider = Provider<ConnectionRegistry>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  final registry = ConnectionRegistry(
    factory: (config, onStatus) => buildConnectionManager(config, onStatus, store),
  );
  ref.onDispose(registry.dispose);
  return registry;
});

/// Fábrica por defecto de managers: cliente API real, driver según el
/// transporte configurado y registro de no-confirmados persistente.
ConnectionManager buildConnectionManager(
  LinkConfig config,
  void Function(LinkStatus) onStatus,
  KeyValueStore store,
) {
  final api = FsApiClient(apiUrl: config.apiUrl, apiKey: config.apiKey);
  final printer = config.printer;
  return ConnectionManager(
    config: config,
    api: api,
    onStatus: onStatus,
    driver: printer == null ? null : driverFor(printer),
    unconfirmed: printer == null
        ? null
        : UnconfirmedStore(store: store, linkId: config.id),
  );
}

/// Lista de vínculos configurados. Cada mutación se persiste y se
/// sincroniza con el registro de conexiones.
class LinksNotifier extends AsyncNotifier<List<LinkConfig>> {
  @override
  Future<List<LinkConfig>> build() async {
    final links = await ref.watch(settingsRepositoryProvider).loadLinks();
    await ref.read(registryProvider).sync(links);
    return links;
  }

  Future<void> save(LinkConfig link) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveLink(link);
    await _reload(repo);
  }

  Future<void> remove(String id) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.deleteLink(id);
    await _reload(repo);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final current = state.value ?? [];
    final index = current.indexWhere((l) => l.id == id);
    if (index < 0) {
      return;
    }
    await save(current[index].copyWith(enabled: enabled));
  }

  /// Exporta la configuración completa (con API keys) como JSON.
  Future<String> exportConfig() {
    return ref.read(settingsRepositoryProvider).exportLinks();
  }

  /// Importa una configuración exportada. Devuelve cuántos vínculos se
  /// importaron; lanza [FormatException] si el texto no es válido.
  Future<int> importConfig(String raw) async {
    final repo = ref.read(settingsRepositoryProvider);
    final count = await repo.importLinks(raw);
    await _reload(repo);
    return count;
  }

  Future<void> _reload(SettingsRepository repo) async {
    final links = await repo.loadLinks();
    await ref.read(registryProvider).sync(links);
    await ref.read(pushListenerProvider).syncLinks(links);
    state = AsyncData(links);
  }
}

final linksProvider =
    AsyncNotifierProvider<LinksNotifier, List<LinkConfig>>(LinksNotifier.new);

/// Estado en vivo de un vínculo concreto.
final linkStatusProvider =
    StreamProvider.family<LinkStatus, String>((ref, linkId) {
  return ref.watch(registryProvider).watch(linkId);
});

/// Despertador push FCM (móvil). En escritorio queda inerte.
final pushListenerProvider = Provider<PushListener>((ref) {
  return PushListener(onNudge: () {
    final links = ref.read(linksProvider).value ?? [];
    final registry = ref.read(registryProvider);
    for (final link in links) {
      registry.managerFor(link.id)?.pullNow();
    }
  });
});

final androidServiceProvider =
    Provider<AndroidService>((ref) => AndroidService());

/// Arranque de los servicios de móvil (push FCM + foreground service).
/// Se observa desde la Home para ejecutarse una sola vez.
final mobileBootstrapProvider = FutureProvider<void>((ref) async {
  final links = await ref.watch(linksProvider.future);

  if (PushListener.isSupported) {
    final push = ref.read(pushListenerProvider);
    await push.init();
    await push.syncLinks(links);
  }

  if (AndroidService.isSupported) {
    final service = ref.read(androidServiceProvider);
    await service.init();
    await service.start();
  }

  // Modo kiosco: aplicar el wakelock guardado al arrancar (móvil).
  if (Platform.isAndroid || Platform.isIOS) {
    final settings = await ref.watch(appSettingsProvider.future);
    if (settings.kioskMode) {
      await WakelockPlus.enable();
    }
  }
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(store: ref.watch(keyValueStoreProvider));
});

/// Ajustes globales de la app (autoarranque, arrancar oculto).
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(appSettingsRepositoryProvider).load();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    // El registro en el SO solo aplica en escritorio.
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    }
    await _save((s) => s.copyWith(launchAtStartup: enabled));
  }

  Future<void> setStartHidden(bool enabled) async {
    await _save((s) => s.copyWith(startHidden: enabled));
  }

  Future<void> setKioskMode(bool enabled) async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    }
    await _save((s) => s.copyWith(kioskMode: enabled));
  }

  Future<void> _save(AppSettings Function(AppSettings) update) async {
    final current = state.value ?? const AppSettings();
    final updated = update(current);
    await ref.read(appSettingsRepositoryProvider).save(updated);
    state = AsyncData(updated);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
        AppSettingsNotifier.new);
