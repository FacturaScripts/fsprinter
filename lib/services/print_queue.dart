import 'dart:async';
import 'dart:typed_data';

import '../models/link_status.dart';
import '../models/ticket_job.dart';
import '../printing/printer_driver.dart';
import 'fs_api_client.dart';
import 'unconfirmed_store.dart';

/// Cola de impresión de un vínculo.
///
/// Garantías:
/// - Un ticket no se procesa dos veces a la vez (set de ids en vuelo).
/// - Los trabajos hacia una misma impresora física se serializan aunque
///   vengan de vínculos distintos (mutex global por [PrinterRef.key]).
/// - Si la impresora falla se reintenta con backoff y NO se marca como
///   impreso: quedará pendiente para el siguiente aviso o polling.
/// - Si se imprime pero falla la confirmación (`printed=1`), el id queda
///   apuntado como no-confirmado para no reimprimirlo después.
class PrintQueue {
  /// Mutex global por impresora física, compartido entre vínculos.
  static final Map<String, Future<void>> _printerLocks = {};

  static const _escInit = [0x1B, 0x40]; // ESC @

  final PrinterDriver driver;
  final FsApiClient api;
  final UnconfirmedStore unconfirmed;
  final bool sendInit;
  final List<Duration> retryDelays;
  final void Function(JobLogEntry entry)? onJob;

  final Set<int> _inFlight = {};

  PrintQueue({
    required this.driver,
    required this.api,
    required this.unconfirmed,
    this.sendInit = true,
    this.retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    this.onJob,
  });

  /// Procesa un ticket. Devuelve true si quedó impreso (aunque la
  /// confirmación haya fallado).
  Future<bool> process(TicketJob job) async {
    if (_inFlight.contains(job.id)) {
      return false;
    }
    _inFlight.add(job.id);

    try {
      // Ya impreso en una ejecución anterior: solo falta confirmarlo.
      if (await unconfirmed.contains(job.id)) {
        await _confirm(job);
        return true;
      }

      final attempts = await _withPrinterLock(() => _print(job));
      if (attempts == 0) {
        return false;
      }

      await _confirm(job, attempts: attempts);
      return true;
    } finally {
      _inFlight.remove(job.id);
    }
  }

  /// Imprime con reintentos. Devuelve el número de intento que tuvo éxito,
  /// o 0 si se agotaron todos.
  Future<int> _print(TicketJob job) async {
    final body = job.bodyBytes;
    final bytes = sendInit
        ? Uint8List.fromList([..._escInit, ...body])
        : body;

    Object? lastError;
    final maxAttempts = retryDelays.length + 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await driver.sendRaw(bytes);
        return attempt;
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelays[attempt - 1]);
        }
      }
    }

    _log(job, success: false, attempts: maxAttempts, message: '$lastError');
    return 0;
  }

  Future<void> _confirm(TicketJob job, {int attempts = 1}) async {
    try {
      await api.markPrinted(job.id);
      await unconfirmed.remove(job.id);
      _log(job, success: true, attempts: attempts);
    } catch (e) {
      // Impreso pero sin confirmar: apuntarlo para no reimprimir.
      await unconfirmed.add(job.id);
      _log(job,
          success: true,
          attempts: attempts,
          message: 'impreso, pendiente de confirmar: $e');
    }
  }

  Future<T> _withPrinterLock<T>(Future<T> Function() action) async {
    final key = driver.printer.key;
    final previous = _printerLocks[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _printerLocks[key] = completer.future;

    await previous;
    try {
      return await action();
    } finally {
      completer.complete();
      if (identical(_printerLocks[key], completer.future)) {
        _printerLocks.remove(key);
      }
    }
  }

  void _log(TicketJob job,
      {required bool success, int attempts = 1, String message = ''}) {
    onJob?.call(JobLogEntry(
      ticketId: job.id,
      time: DateTime.now(),
      success: success,
      attempts: attempts,
      message: message,
    ));
  }
}
