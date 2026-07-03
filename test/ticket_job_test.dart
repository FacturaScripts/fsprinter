import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/ticket_job.dart';

void main() {
  group('TicketJob.fromJson', () {
    test('parsea un ticket típico de la API', () {
      final job = TicketJob.fromJson({
        'id': 7,
        'body': 'SG9sYQ==',
        'base64': true,
        'appversion': 1,
        'printed': false,
        'title': 'FacturaCliente F-1',
      });

      expect(job.id, 7);
      expect(job.base64, isTrue);
      expect(job.appVersion, 1.0);
      expect(job.printed, isFalse);
      expect(job.title, 'FacturaCliente F-1');
    });

    test('tolera booleanos como cadena o número', () {
      expect(TicketJob.fromJson({'id': '1', 'base64': '1'}).base64, isTrue);
      expect(TicketJob.fromJson({'id': 1, 'base64': 0}).base64, isFalse);
      expect(TicketJob.fromJson({'id': 1, 'printed': 'true'}).printed, isTrue);
      expect(TicketJob.fromJson({'id': '9'}).id, 9);
      expect(TicketJob.fromJson({'id': 1, 'appversion': '1.5'}).appVersion, 1.5);
    });
  });

  group('TicketJob.bodyBytes', () {
    test('decodifica base64', () {
      final job = TicketJob(
        id: 1,
        body: base64Encode([0x1B, 0x40, 0x48, 0x6F, 0x6C, 0x61]),
        base64: true,
      );
      expect(job.bodyBytes, [0x1B, 0x40, 0x48, 0x6F, 0x6C, 0x61]);
    });

    test('body en texto plano se convierte byte a byte (latin1)', () {
      // Comandos ESC/POS embebidos como caracteres en la cadena, igual que
      // los tickets antiguos sin base64.
      final job = TicketJob(id: 1, body: '\x1B\x40Hola\x1B\x6D');
      expect(job.bodyBytes,
          [0x1B, 0x40, 0x48, 0x6F, 0x6C, 0x61, 0x1B, 0x6D]);
    });

    test('ignora espacios alrededor del base64', () {
      final job = TicketJob(id: 1, body: ' SG9sYQ== \n', base64: true);
      expect(utf8.decode(job.bodyBytes), 'Hola');
    });
  });
}
