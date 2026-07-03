import 'dart:convert';
import 'dart:typed_data';

/// Genera el ticket de prueba ESC/POS completo, equivalente al de
/// mc20printer: cabecera, líneas de ejemplo, código de barras Code128,
/// código QR, corte parcial y (opcionalmente) apertura de cajón.
Uint8List buildTestTicket({
  int lineLen = 48,
  String linkName = '',
  bool openDrawer = false,
}) {
  const esc = 0x1B;
  const gs = 0x1D;
  const lf = 0x0A;

  final bytes = BytesBuilder();

  void text(String value) => bytes.add(latin1.encode(value));
  void line([String value = '']) {
    text(value);
    bytes.addByte(lf);
  }

  bytes.add([esc, 0x40]); // ESC @ — inicializar

  // Cabecera: negrita + doble alto + doble ancho (ESC ! 56).
  bytes.add([esc, 0x21, 0x38]);
  line('PRUEBA');
  line();
  bytes.add([esc, 0x21, 0x00]); // fuente normal

  if (linkName.isNotEmpty) {
    line(linkName);
    line();
  }

  // Líneas de ejemplo.
  line('COOKIES                   5.00');
  line('MILK 65 Fl oz             3.78');
  line();
  line('SUBTOTAL                  8.78');
  line('TAX 5%                    0.44');
  line('TOTAL                     9.22');
  line('CASH TEND                10.00');
  line('CASH DUE                  0.78');
  line();

  // Código de barras Code128, centrado y con texto legible debajo.
  bytes.add([esc, 0x61, 0x01]); // centrado
  line('CODIGO DE BARRAS:');
  bytes.add([gs, 0x68, 0x50]); // altura 80 puntos
  bytes.add([gs, 0x77, 0x02]); // ancho 2
  bytes.add([gs, 0x48, 0x02]); // HRI debajo
  const barcodeData = '1234567890123';
  bytes.add([gs, 0x6B, 0x49, barcodeData.length]); // GS k 73 (CODE128)
  text(barcodeData);
  line();
  line();

  // Código QR (funciones GS ( k).
  line('CODIGO QR:');
  bytes.add([gs, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]); // modelo 2
  bytes.add([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x08]); // tamaño 8
  bytes.add([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30]); // corrección L
  const qrData = 'https://facturascripts.com';
  final qrLen = qrData.length + 3;
  bytes.add([gs, 0x28, 0x6B, qrLen % 256, qrLen ~/ 256, 0x31, 0x50, 0x30]);
  text(qrData); // almacenar datos
  bytes.add([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]); // imprimir QR
  line();
  line();

  bytes.add([esc, 0x61, 0x00]); // alineación izquierda
  line();
  line();

  bytes.add([esc, 0x6D]); // ESC m — corte parcial
  bytes.addByte(lf);

  if (openDrawer) {
    bytes.add([esc, 0x70, 0x30, 0x37, 0x79]); // ESC p 0 55 121
    bytes.addByte(lf);
  }

  return bytes.toBytes();
}
