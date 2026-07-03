import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/printing/test_ticket.dart';

bool _containsSequence(List<int> haystack, List<int> needle) {
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var found = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      return true;
    }
  }
  return false;
}

void main() {
  test('el ticket de prueba contiene los bloques ESC/POS esperados', () {
    final ticket = buildTestTicket(linkName: 'Caja 1');

    // Inicialización al principio.
    expect(ticket.sublist(0, 2), [0x1B, 0x40]);

    // Código de barras Code128 (GS k 73).
    expect(_containsSequence(ticket, [0x1D, 0x6B, 0x49]), isTrue);

    // QR: almacenar datos (GS ( k ... 1 P 0) e imprimir (1 Q 0).
    expect(_containsSequence(ticket, [0x31, 0x50, 0x30]), isTrue);
    expect(
        _containsSequence(ticket, [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]),
        isTrue);

    // Corte parcial (ESC m).
    expect(_containsSequence(ticket, [0x1B, 0x6D]), isTrue);

    // Nombre del vínculo incluido como texto.
    expect(_containsSequence(ticket, 'Caja 1'.codeUnits), isTrue);
  });

  test('el cajón solo se abre si se pide', () {
    const drawerCmd = [0x1B, 0x70, 0x30, 0x37, 0x79];

    expect(_containsSequence(buildTestTicket(), drawerCmd), isFalse);
    expect(_containsSequence(buildTestTicket(openDrawer: true), drawerCmd),
        isTrue);
  });
}
