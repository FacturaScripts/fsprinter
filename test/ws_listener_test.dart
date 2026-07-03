import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/link_status.dart';
import 'package:fsprinter/services/ws_listener.dart';

/// Servidor WebSocket local mínimo para los tests.
class _FakeRelay {
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

  Future<void> closeClients() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
  }

  Future<void> stop() async {
    await closeClients();
    await _server.close(force: true);
  }
}

void main() {
  test('cualquier mensaje recibido dispara onNudge', () async {
    final relay = _FakeRelay();
    await relay.start();

    final nudges = <int>[];
    final listener = WsListener(
      url: 'ws://127.0.0.1:${relay.port}/mc20printer/abc',
      onNudge: () => nudges.add(1),
    );

    listener.connect();
    await listener.stateStream.firstWhere((s) => s == WsState.connected);

    relay.broadcast('{"action":"print"}');
    relay.broadcast('cualquier cosa');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(nudges, hasLength(2),
        reason: 'el contenido del mensaje es irrelevante: todo aviso cuenta');

    await listener.dispose();
    await relay.stop();
  });

  test('reconecta tras perder la conexión', () async {
    final relay = _FakeRelay();
    await relay.start();

    final listener = WsListener(
      url: 'ws://127.0.0.1:${relay.port}/mc20printer/abc',
      onNudge: () {},
      reconnectDelay: const Duration(milliseconds: 100),
    );

    final states = <WsState>[];
    listener.stateStream.listen(states.add);

    listener.connect();
    await listener.stateStream.firstWhere((s) => s == WsState.connected);

    // El servidor cierra la conexión: la app debe reconectar sola.
    await relay.closeClients();
    await listener.stateStream
        .firstWhere((s) => s == WsState.connected)
        .timeout(const Duration(seconds: 5));

    expect(states.where((s) => s == WsState.connected).length,
        greaterThanOrEqualTo(2));

    await listener.dispose();
    await relay.stop();
  });

  test('dispose es un cierre intencional: no reconecta', () async {
    final relay = _FakeRelay();
    await relay.start();

    var nudges = 0;
    final listener = WsListener(
      url: 'ws://127.0.0.1:${relay.port}/mc20printer/abc',
      onNudge: () => nudges++,
      reconnectDelay: const Duration(milliseconds: 50),
    );

    listener.connect();
    await listener.stateStream.firstWhere((s) => s == WsState.connected);
    await listener.dispose();

    // Si hubiese reconectado, este broadcast dispararía un nudge.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    relay.broadcast('mensaje');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(nudges, 0);
    expect(listener.state, WsState.disconnected);

    await relay.stop();
  });
}
