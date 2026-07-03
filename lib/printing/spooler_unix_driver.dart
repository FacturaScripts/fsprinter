import 'dart:io';
import 'dart:typed_data';

import '../models/printer_ref.dart';
import 'printer_driver.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);

/// Impresión vía spooler de CUPS en macOS y Linux: escribe los bytes a un
/// fichero temporal y lo envía con `lp -d <impresora> -o raw`. Cubre
/// cualquier impresora ya instalada en el sistema (USB, red o Bluetooth).
class SpoolerUnixDriver implements PrinterDriver {
  @override
  final PrinterRef printer;

  final ProcessRunner _run;

  const SpoolerUnixDriver(this.printer, {ProcessRunner runner = Process.run})
      : _run = runner;

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    // Fichero temporal único por trabajo, para evitar colisiones entre
    // impresiones concurrentes.
    final dir = await Directory.systemTemp.createTemp('fsprinter_');
    final file = File('${dir.path}/job.bin');
    try {
      await file.writeAsBytes(bytes, flush: true);

      // `-o raw` evita que CUPS filtre/reinterprete los comandos ESC/POS.
      final result = await _run(
        'lp',
        ['-d', printer.address, '-o', 'raw', file.path],
      );
      if (result.exitCode != 0) {
        throw PrinterException(
            'lp falló para "${printer.address}": ${result.stderr}'.trim());
      }
    } on ProcessException catch (e) {
      throw PrinterException('No se pudo ejecutar lp: ${e.message}');
    } finally {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _run('lpstat', ['-e']);
      if (result.exitCode != 0) {
        return false;
      }
      return parseLpstatPrinters('${result.stdout}')
          .contains(printer.address);
    } on ProcessException {
      return false;
    }
  }

  /// Parsea la salida de `lpstat -e`: un nombre de impresora por línea.
  static List<String> parseLpstatPrinters(String output) {
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

/// Descubrimiento de impresoras instaladas en el sistema (macOS/Linux).
class SpoolerUnixDiscovery implements PrinterDiscovery {
  final ProcessRunner _run;

  const SpoolerUnixDiscovery({ProcessRunner runner = Process.run})
      : _run = runner;

  @override
  Future<List<PrinterRef>> discover() async {
    try {
      final result = await _run('lpstat', ['-e']);
      if (result.exitCode != 0) {
        return [];
      }
      return SpoolerUnixDriver.parseLpstatPrinters('${result.stdout}')
          .map((name) => PrinterRef(
                type: PrinterType.spooler,
                address: name,
                label: name,
              ))
          .toList();
    } on ProcessException {
      return [];
    }
  }
}
