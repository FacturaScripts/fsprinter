import 'dart:async';

import '../models/link_config.dart';
import '../models/link_status.dart';
import '../printing/printer_driver.dart';
import 'channel_calculator.dart';
import 'fs_api_client.dart';
import 'print_queue.dart';
import 'unconfirmed_store.dart';
import 'ws_listener.dart';

typedef WsListenerFactory = WsListener Function(
    String url, void Function() onNudge);

/// Ciclo completo de un vínculo instalación↔impresora:
/// aviso WebSocket + polling de respaldo + pull por API + cola de
/// impresión + heartbeat de actividad. Cada vínculo tiene su propio
/// manager, sin estado compartido con los demás.
class ConnectionManager {
  /// Versión de protocolo de tickets que esta app sabe imprimir. Si un
  /// ticket pide una versión superior no se imprime y se avisa en la UI.
  static const supportedAppVersion = 2.0;

  static const _maxRecentJobs = 50;

  final LinkConfig config;
  final FsApiClient api;
  final void Function(LinkStatus status) onStatus;
  final Duration heartbeatInterval;

  final WsListenerFactory _wsFactory;
  PrintQueue? _queue;

  WsListener? _ws;
  StreamSubscription<WsState>? _wsSub;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;

  LinkStatus _status = const LinkStatus();
  int? _printerId;
  bool _pulling = false;
  bool _pendingPull = false;
  bool _disposed = false;

  ConnectionManager({
    required this.config,
    required this.api,
    required this.onStatus,
    PrinterDriver? driver,
    UnconfirmedStore? unconfirmed,
    List<Duration>? retryDelays,
    WsListenerFactory? wsFactory,
    this.heartbeatInterval = const Duration(seconds: 60),
  }) : _wsFactory = wsFactory ??
            ((url, onNudge) => WsListener(url: url, onNudge: onNudge)) {
    if (driver != null && unconfirmed != null) {
      _queue = PrintQueue(
        driver: driver,
        api: api,
        unconfirmed: unconfirmed,
        sendInit: config.sendInit,
        retryDelays: retryDelays ??
            const [
              Duration(seconds: 2),
              Duration(seconds: 5),
              Duration(seconds: 10),
            ],
        onJob: _addJobLog,
      );
    }
  }

  LinkStatus get status => _status;

  void start() {
    if (_disposed) {
      return;
    }

    final ws = _wsFactory(
      ChannelCalculator.wsUrl(config.apiUrl, config.apiKey),
      pullNow,
    );
    _ws = ws;
    _wsSub = ws.stateStream.listen((state) {
      _update(_status.copyWith(wsState: state));
    });
    ws.connect();

    pullNow();

    if (config.pollingSeconds > 0) {
      _pollTimer = Timer.periodic(
        Duration(seconds: config.pollingSeconds),
        (_) => pullNow(),
      );
    }

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      unawaited(_heartbeat());
    });
  }

  /// Dispara un pull inmediato. Si ya hay uno en marcha se encola como
  /// máximo una repetición (colapsa ráfagas de avisos, como mc20printer).
  void pullNow() {
    unawaited(_pull());
  }

  Future<void> _pull() async {
    if (_disposed) {
      return;
    }
    if (_pulling) {
      _pendingPull = true;
      return;
    }
    _pulling = true;

    try {
      do {
        _pendingPull = false;
        await _pullOnce();
      } while (_pendingPull && !_disposed);
    } finally {
      _pulling = false;
    }
  }

  Future<void> _pullOnce() async {
    try {
      _printerId ??= await api.fetchPrinterId();
      if (_printerId == null) {
        _update(_status.copyWith(
            lastError: 'Ninguna impresora de la instalación tiene esta API key'));
        return;
      }

      final jobs = await api.fetchPendingTickets(_printerId!);
      for (final job in jobs) {
        if (_disposed) {
          return;
        }

        if (job.appVersion > supportedAppVersion) {
          _update(_status.copyWith(updateRequired: true));
          _addJobLog(JobLogEntry(
            ticketId: job.id,
            time: DateTime.now(),
            success: false,
            message: 'Requiere una versión más reciente de fsprinter',
          ));
          continue;
        }

        final queue = _queue;
        if (queue == null) {
          _update(_status.copyWith(
              lastError: 'El vínculo no tiene impresora configurada'));
          return;
        }
        await queue.process(job);
      }

      await _heartbeat();
      _update(_status.copyWith(
        printerId: _printerId,
        lastActivity: DateTime.now(),
        lastError: '',
      ));
    } catch (e) {
      _update(_status.copyWith(lastError: '$e'));
    }
  }

  Future<void> _heartbeat() async {
    if (_printerId == null || _disposed) {
      return;
    }
    try {
      await api.heartbeat(_printerId!, config.lineLen);
    } catch (e) {
      _update(_status.copyWith(lastError: 'Heartbeat: $e'));
    }
  }

  void _addJobLog(JobLogEntry entry) {
    final jobs = [entry, ..._status.recentJobs];
    if (jobs.length > _maxRecentJobs) {
      jobs.removeRange(_maxRecentJobs, jobs.length);
    }
    _update(_status.copyWith(recentJobs: jobs));
  }

  void _update(LinkStatus status) {
    if (_disposed) {
      return;
    }
    _status = status;
    onStatus(status);
  }

  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _wsSub?.cancel();
    await _ws?.dispose();
    api.close();
  }
}
