import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/printing/network_printer_driver.dart';
import 'package:fsprinter/printing/printer_driver.dart';

void main() {
  test('sendRaw entrega los bytes tal cual por TCP', () async {
    final received = <int>[];
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final done = server.first.then((client) async {
      await client.forEach(received.addAll);
    });

    final driver = NetworkPrinterDriver(PrinterRef(
      type: PrinterType.network,
      address: '127.0.0.1',
      port: server.port,
    ));

    final payload = Uint8List.fromList([0x1B, 0x40, 0x48, 0x6F, 0x6C, 0x61]);
    await driver.sendRaw(payload);

    await done.timeout(const Duration(seconds: 5));
    await server.close();

    expect(received, payload);
  });

  test('sendRaw lanza PrinterException si no hay nadie escuchando', () async {
    // Puerto reservado y cerrado inmediatamente: nadie escucha ahí.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final freePort = server.port;
    await server.close();

    final driver = NetworkPrinterDriver(
      PrinterRef(
        type: PrinterType.network,
        address: '127.0.0.1',
        port: freePort,
      ),
      connectTimeout: const Duration(seconds: 2),
    );

    expect(driver.sendRaw(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<PrinterException>()));
    expect(await driver.isAvailable(), isFalse);
  });

  test('isAvailable devuelve true si la impresora acepta conexiones',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((client) => client.destroy());

    final driver = NetworkPrinterDriver(PrinterRef(
      type: PrinterType.network,
      address: '127.0.0.1',
      port: server.port,
    ));

    expect(await driver.isAvailable(), isTrue);
    await server.close();
  });
}
