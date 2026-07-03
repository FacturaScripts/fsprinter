import 'dart:typed_data';

import '../models/printer_ref.dart';

/// Error al enviar datos a una impresora.
class PrinterException implements Exception {
  final String message;

  const PrinterException(this.message);

  @override
  String toString() => 'PrinterException: $message';
}

/// Contrato de todos los transportes de impresión.
///
/// El cuerpo de los trabajos son bytes opacos (ESC/POS hoy, ZPL mañana):
/// el driver no interpreta el contenido, solo lo entrega a la impresora.
abstract class PrinterDriver {
  PrinterRef get printer;

  /// Envía los bytes tal cual a la impresora. Lanza [PrinterException]
  /// si la entrega falla.
  Future<void> sendRaw(Uint8List bytes);

  /// Comprobación rápida de disponibilidad (para la UI y el asistente).
  Future<bool> isAvailable();
}

/// Descubrimiento de impresoras para un transporte concreto.
abstract class PrinterDiscovery {
  Future<List<PrinterRef>> discover();
}
