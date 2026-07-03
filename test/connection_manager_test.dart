import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/link_config.dart';
import 'package:fsprinter/models/link_status.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/printing/printer_driver.dart';
import 'package:fsprinter/services/connection_manager.dart';
import 'package:fsprinter/services/fs_api_client.dart';
import 'package:fsprinter/services/stores.dart';
import 'package:fsprinter/services/unconfirmed_store.dart';
import 'package:fsprinter/services/ws_listener.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// API falsa de FacturaScripts: sirve impresoras y tickets pendientes,
/// y registra los PUT recibidos.
class FakeFsServer {
  final String apiKey;
  List<Map<String, dynamic>> pendingTickets = [];
  final List<http.Request> puts = [];

  FakeFsServer({required this.apiKey});

  http.Client get client => MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/api/3/ticketprinteres') {
          return http.Response(
              jsonEncode([
                {'id': 5, 'apikey': apiKey}
              ]),
              200);
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/3/ticketes') {
          return http.Response(jsonEncode(pendingTickets), 200);
        }
        if (request.method == 'PUT') {
          puts.add(request);
          if (request.url.path.startsWith('/api/3/ticketes/')) {
            final id = int.parse(request.url.pathSegments.last);
            pendingTickets.removeWhere((t) => t['id'] == id);
          }
          return http.Response('{}', 200);
        }
        return http.Response('not found', 404);
      });
}

class CapturingDriver implements PrinterDriver {
  @override
  final PrinterRef printer = const PrinterRef(
      type: PrinterType.network, address: 'fake', port: 9100);

  final List<Uint8List> sent = [];

  @override
  Future<void> sendRaw(Uint8List bytes) async => sent.add(bytes);

  @override
  Future<bool> isAvailable() async => true;
}

/// Relay WebSocket falso en localhost.
class FakeRelay {
  late HttpServer _server;
  final _sockets = <WebSocket>[];

  int get port => _server.port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      _sockets.add(socket);
      socket.listen((_) {});
    });
  }

  void broadcast(String message) {
    for (final socket in _sockets) {
      socket.add(message);
    }
  }

  Future<void> stop() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

void main() {
  const apiKey = 'clave';

  ConnectionManager buildManager({
    required FakeFsServer server,
    required CapturingDriver driver,
    required List<LinkStatus> statuses,
    required WsListenerFactory wsFactory,
    int pollingSeconds = 0,
  }) {
    final config = LinkConfig(
      id: 'l1',
      name: 'Test',
      apiUrl: 'https://example.com',
      apiKey: apiKey,
      printer: driver.printer,
      pollingSeconds: pollingSeconds,
    );
    return ConnectionManager(
      config: config,
      api: FsApiClient(
        apiUrl: config.apiUrl,
        apiKey: apiKey,
        client: server.client,
      ),
      onStatus: statuses.add,
      driver: driver,
      unconfirmed: UnconfirmedStore(store: MemoryStore(), linkId: 'l1'),
      retryDelays: const [Duration(milliseconds: 10)],
      wsFactory: wsFactory,
    );
  }

  test('aviso por WebSocket → pull → imprime → confirma → heartbeat',
      () async {
    final relay = FakeRelay();
    await relay.start();

    final server = FakeFsServer(apiKey: apiKey);
    final driver = CapturingDriver();
    final statuses = <LinkStatus>[];

    final manager = buildManager(
      server: server,
      driver: driver,
      statuses: statuses,
      // El manager calcula la URL real del relay; el test la sustituye
      // por el relay local conservando el resto del ciclo.
      wsFactory: (url, onNudge) => WsListener(
        url: 'ws://127.0.0.1:${relay.port}/mc20printer/x',
        onNudge: onNudge,
      ),
    );

    manager.start();

    // Espera al pull inicial (sin tickets pendientes).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(driver.sent, isEmpty);

    // Llega un ticket nuevo y el relay avisa.
    server.pendingTickets = [
      {'id': 9, 'body': 'SG9sYQ==', 'base64': true, 'appversion': 1},
    ];
    relay.broadcast('{"action":"print"}');

    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(driver.sent, hasLength(1), reason: 'debe imprimir el ticket');
    final printedPut = server.puts
        .where((r) => r.url.path == '/api/3/ticketes/9')
        .toList();
    expect(printedPut, hasLength(1));
    expect(printedPut.single.bodyFields, {'printed': '1'});

    final heartbeats = server.puts
        .where((r) => r.url.path == '/api/3/ticketprinteres/5')
        .toList();
    expect(heartbeats, isNotEmpty,
        reason: 'cada pull termina con heartbeat');
    expect(heartbeats.last.bodyFields['linelen'], '48');

    final last = statuses.last;
    expect(last.printerId, 5);
    expect(last.lastActivity, isNotNull);
    expect(last.recentJobs.single.success, isTrue);

    await manager.dispose();
    await relay.stop();
  });

  test('un ticket de versión futura no se imprime y queda avisado',
      () async {
    final relay = FakeRelay();
    await relay.start();

    final server = FakeFsServer(apiKey: apiKey);
    server.pendingTickets = [
      {'id': 4, 'body': 'SG9sYQ==', 'base64': true, 'appversion': 99},
    ];
    final driver = CapturingDriver();
    final statuses = <LinkStatus>[];

    final manager = buildManager(
      server: server,
      driver: driver,
      statuses: statuses,
      wsFactory: (url, onNudge) => WsListener(
        url: 'ws://127.0.0.1:${relay.port}/mc20printer/x',
        onNudge: onNudge,
      ),
    );

    manager.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(driver.sent, isEmpty);
    expect(
        server.puts.where((r) => r.url.path == '/api/3/ticketes/4'), isEmpty,
        reason: 'no debe marcarse impreso');
    final entry = statuses.last.recentJobs.single;
    expect(entry.success, isFalse);
    expect(entry.message, contains('versión más reciente'));
    expect(statuses.last.updateRequired, isTrue,
        reason: 'la UI debe mostrar el aviso de actualización');

    await manager.dispose();
    await relay.stop();
  });
}
