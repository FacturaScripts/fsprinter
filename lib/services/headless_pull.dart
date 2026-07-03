import '../printing/driver_factory.dart';
import 'connection_manager.dart';
import 'fs_api_client.dart';
import 'print_queue.dart';
import 'settings_repository.dart';
import 'stores.dart';
import 'unconfirmed_store.dart';

/// Pull e impresión de una sola pasada, sin UI ni managers.
///
/// Se usa cuando la app es despertada en segundo plano (push FCM en un
/// isolate propio): carga la configuración, y para cada vínculo activo
/// descarga los tickets pendientes, los imprime y los confirma.
Future<void> runHeadlessPull() async {
  final repo = SettingsRepository(
    store: PrefsStore(),
    secrets: SecureSecretStore(),
  );

  final links = await repo.loadLinks();
  for (final link in links) {
    if (!link.enabled || link.printer == null || link.apiUrl.isEmpty) {
      continue;
    }

    final api = FsApiClient(apiUrl: link.apiUrl, apiKey: link.apiKey);
    try {
      final printerId = await api.fetchPrinterId();
      if (printerId == null) {
        continue;
      }

      final queue = PrintQueue(
        driver: driverFor(link.printer!),
        api: api,
        unconfirmed: UnconfirmedStore(store: PrefsStore(), linkId: link.id),
        sendInit: link.sendInit,
        // En background el tiempo de ejecución es limitado (~30 s en
        // iOS): un único reintento rápido.
        retryDelays: const [Duration(seconds: 2)],
      );

      final jobs = await api.fetchPendingTickets(printerId);
      for (final job in jobs) {
        if (job.appVersion > ConnectionManager.supportedAppVersion) {
          continue;
        }
        await queue.process(job);
      }

      await api.heartbeat(printerId, link.lineLen);
    } catch (_) {
      // Sin UI a la que informar; el siguiente pull lo reintentará.
    } finally {
      api.close();
    }
  }
}
