import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/link_status.dart';

/// Escucha el canal WebSocket del relay de impresión.
///
/// El contenido de los mensajes es irrelevante: cualquier mensaje recibido
/// significa "hay trabajos nuevos, ve a buscarlos" y dispara [onNudge].
/// No se envía nada por el socket. Si la conexión se cae se reintenta a los
/// 5 segundos, igual que mc20printer.
class WsListener {
  final String url;
  final void Function() onNudge;
  final Duration reconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _attempt = 0;

  final _stateController = StreamController<WsState>.broadcast();
  WsState _state = WsState.disconnected;

  WsListener({
    required this.url,
    required this.onNudge,
    this.reconnectDelay = const Duration(seconds: 5),
  });

  WsState get state => _state;

  Stream<WsState> get stateStream => _stateController.stream;

  void connect() {
    if (_disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final attempt = ++_attempt;
    _teardownChannel();
    _setState(WsState.connecting);

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;

      // El primer evento (o la finalización del handshake) confirma la
      // conexión; ready completa cuando el servidor acepta el socket.
      channel.ready.then((_) {
        if (attempt == _attempt && !_disposed) {
          _setState(WsState.connected);
        }
      }).catchError((_) {
        // El error se gestiona en onError/onDone del stream.
      });

      _subscription = channel.stream.listen(
        (_) {
          if (attempt != _attempt || _disposed) {
            return;
          }
          onNudge();
        },
        onError: (_) {
          if (attempt != _attempt || _disposed) {
            return;
          }
          _setState(WsState.error);
          _scheduleReconnect();
        },
        onDone: () {
          if (attempt != _attempt || _disposed) {
            return;
          }
          _setState(WsState.disconnected);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _setState(WsState.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) {
      return;
    }
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectTimer = null;
      connect();
    });
  }

  void _setState(WsState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _teardownChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Cierre intencional: no se reintenta la conexión.
  Future<void> dispose() async {
    _disposed = true;
    _attempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _teardownChannel();
    _setState(WsState.disconnected);
    await _stateController.close();
  }
}
