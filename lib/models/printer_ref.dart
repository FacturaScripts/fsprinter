/// Tipos de transporte soportados para conectar con una impresora.
enum PrinterType {
  /// Socket TCP directo (normalmente puerto 9100).
  network,

  /// Impresora instalada en el sistema operativo (spooler): lp/lpstat en
  /// macOS y Linux, winspool en Windows.
  spooler,

  /// Impresora Bluetooth (clásico en Android, BLE en iOS).
  bluetooth,

  /// Impresora USB conectada directamente (Android).
  usb,
}

/// Referencia a una impresora física: transporte + dirección.
///
/// Según el tipo, [address] contiene la IP/host (network), el nombre de la
/// impresora en el SO (spooler), la MAC (bluetooth) o el identificador del
/// dispositivo (usb).
class PrinterRef {
  final PrinterType type;
  final String address;
  final int port;
  final String label;

  const PrinterRef({
    required this.type,
    required this.address,
    this.port = 9100,
    this.label = '',
  });

  /// Clave única para agrupar trabajos que van a la misma impresora física,
  /// aunque la usen varios vínculos.
  String get key => '${type.name}:$address:$port';

  factory PrinterRef.fromJson(Map<String, dynamic> json) {
    return PrinterRef(
      type: PrinterType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PrinterType.network,
      ),
      address: json['address'] as String? ?? '',
      port: json['port'] as int? ?? 9100,
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'address': address,
        'port': port,
        'label': label,
      };

  @override
  String toString() => label.isNotEmpty ? label : key;
}
