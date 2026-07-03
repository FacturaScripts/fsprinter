import 'dart:io';
import 'dart:typed_data';

import '../models/printer_ref.dart';
import 'printer_driver.dart';

/// Impresión por socket TCP directo (RAW 9100), disponible en todas las
/// plataformas. Es la vía recomendada para impresoras térmicas de red.
class NetworkPrinterDriver implements PrinterDriver {
  @override
  final PrinterRef printer;

  final Duration connectTimeout;

  const NetworkPrinterDriver(
    this.printer, {
    this.connectTimeout = const Duration(seconds: 5),
  });

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    final Socket socket;
    try {
      socket = await Socket.connect(
        printer.address,
        printer.port,
        timeout: connectTimeout,
      );
    } catch (e) {
      throw PrinterException(
          'No se pudo conectar con ${printer.address}:${printer.port}: $e');
    }

    try {
      socket.add(bytes);
      await socket.flush();
    } catch (e) {
      throw PrinterException(
          'Error enviando datos a ${printer.address}:${printer.port}: $e');
    } finally {
      socket.destroy();
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final socket = await Socket.connect(
        printer.address,
        printer.port,
        timeout: connectTimeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
