import 'dart:async';
import 'dart:convert';

import '../models/link_config.dart';
import '../models/link_status.dart';
import 'connection_manager.dart';

typedef ManagerFactory = ConnectionManager Function(
    LinkConfig config, void Function(LinkStatus status) onStatus);

/// Mantiene un [ConnectionManager] en marcha por cada vínculo activo y
/// publica sus estados. Al sincronizar con la lista de vínculos arranca
/// los nuevos, reinicia los que cambiaron de configuración y para los
/// eliminados o pausados.
class ConnectionRegistry {
  final ManagerFactory factory;

  final Map<String, ConnectionManager> _managers = {};
  final Map<String, String> _signatures = {};
  final Map<String, LinkStatus> _latest = {};
  final _controller = StreamController<(String, LinkStatus)>.broadcast();
  bool _disposed = false;

  ConnectionRegistry({required this.factory});

  Future<void> sync(List<LinkConfig> links) async {
    if (_disposed) {
      return;
    }

    final wanted = <String, LinkConfig>{
      for (final link in links)
        if (link.enabled && link.apiUrl.isNotEmpty) link.id: link,
    };

    // Parar los eliminados, pausados o con configuración cambiada.
    for (final id in _managers.keys.toList()) {
      final config = wanted[id];
      if (config != null && _signature(config) == _signatures[id]) {
        continue;
      }
      final manager = _managers.remove(id)!;
      _signatures.remove(id);
      await manager.dispose();
      if (config == null) {
        _latest.remove(id);
        _emit(id, const LinkStatus());
      }
    }

    // Arrancar los nuevos o reiniciados.
    for (final entry in wanted.entries) {
      if (_managers.containsKey(entry.key)) {
        continue;
      }
      final id = entry.key;
      final manager = factory(entry.value, (status) => _emit(id, status));
      _managers[id] = manager;
      _signatures[id] = _signature(entry.value);
      manager.start();
    }
  }

  /// Estado en vivo de un vínculo: emite el último conocido y después
  /// cada cambio.
  Stream<LinkStatus> watch(String id) async* {
    yield _latest[id] ?? const LinkStatus();
    yield* _controller.stream
        .where((event) => event.$1 == id)
        .map((event) => event.$2);
  }

  ConnectionManager? managerFor(String id) => _managers[id];

  void _emit(String id, LinkStatus status) {
    if (_disposed) {
      return;
    }
    _latest[id] = status;
    _controller.add((id, status));
  }

  // La firma incluye la API key: cualquier cambio de configuración
  // reinicia el manager del vínculo.
  String _signature(LinkConfig config) =>
      '${jsonEncode(config.toJson())}:${config.apiKey}';

  Future<void> dispose() async {
    _disposed = true;
    for (final manager in _managers.values) {
      await manager.dispose();
    }
    _managers.clear();
    await _controller.close();
  }
}
