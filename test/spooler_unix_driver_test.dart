import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/printing/printer_driver.dart';
import 'package:fsprinter/printing/spooler_unix_driver.dart';

ProcessResult _result(int code, {String stdout = '', String stderr = ''}) =>
    ProcessResult(0, code, stdout, stderr);

void main() {
  const printer = PrinterRef(
    type: PrinterType.spooler,
    address: 'EPSON_TM_T20',
    label: 'EPSON_TM_T20',
  );

  test('sendRaw escribe los bytes a un fichero y llama a lp -o raw',
      () async {
    List<String>? capturedArgs;
    List<int>? fileContent;
    String? filePath;

    final driver = SpoolerUnixDriver(printer, runner: (cmd, args) async {
      expect(cmd, 'lp');
      capturedArgs = args;
      filePath = args.last;
      fileContent = await File(args.last).readAsBytes();
      return _result(0);
    });

    final payload = Uint8List.fromList([0x1B, 0x40, 0x48, 0x6F, 0x6C, 0x61]);
    await driver.sendRaw(payload);

    expect(capturedArgs!.sublist(0, 4),
        ['-d', 'EPSON_TM_T20', '-o', 'raw']);
    expect(fileContent, payload,
        reason: 'el fichero temporal debe contener los bytes exactos');
    expect(File(filePath!).existsSync(), isFalse,
        reason: 'el fichero temporal debe borrarse tras imprimir');
  });

  test('sendRaw lanza PrinterException si lp devuelve error', () async {
    final driver = SpoolerUnixDriver(printer, runner: (cmd, args) async {
      return _result(1, stderr: 'lp: The printer does not exist.');
    });

    expect(
      driver.sendRaw(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<PrinterException>()),
    );
  });

  test('parseLpstatPrinters extrae un nombre por línea', () {
    const output = 'EPSON_TM_T20\nHP_LaserJet\n\nZebra_GK420d\n';
    expect(SpoolerUnixDriver.parseLpstatPrinters(output),
        ['EPSON_TM_T20', 'HP_LaserJet', 'Zebra_GK420d']);
  });

  test('isAvailable comprueba la impresora contra lpstat -e', () async {
    final driver = SpoolerUnixDriver(printer, runner: (cmd, args) async {
      expect(cmd, 'lpstat');
      expect(args, ['-e']);
      return _result(0, stdout: 'OTRA\nEPSON_TM_T20\n');
    });
    expect(await driver.isAvailable(), isTrue);

    final missing = SpoolerUnixDriver(printer, runner: (cmd, args) async {
      return _result(0, stdout: 'OTRA\n');
    });
    expect(await missing.isAvailable(), isFalse);
  });

  test('discovery devuelve PrinterRef de tipo spooler', () async {
    final discovery = SpoolerUnixDiscovery(runner: (cmd, args) async {
      return _result(0, stdout: 'EPSON_TM_T20\nZebra_GK420d\n');
    });

    final printers = await discovery.discover();

    expect(printers, hasLength(2));
    expect(printers.first.type, PrinterType.spooler);
    expect(printers.first.address, 'EPSON_TM_T20');
    expect(printers.map((p) => p.address), contains('Zebra_GK420d'));
  });
}
