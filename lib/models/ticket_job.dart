import 'dart:convert';
import 'dart:typed_data';

/// Trabajo de impresión pendiente, tal y como lo devuelve la API del plugin
/// Tickets (`GET /api/3/ticketes`).
///
/// El cuerpo son bytes opacos (hoy ESC/POS, en el futuro ZPL): la app no
/// interpreta el contenido, solo lo envía tal cual a la impresora.
class TicketJob {
  final int id;
  final String body;
  final bool base64;
  final double appVersion;
  final bool printed;
  final String title;

  const TicketJob({
    required this.id,
    required this.body,
    this.base64 = false,
    this.appVersion = 1.0,
    this.printed = false,
    this.title = '',
  });

  factory TicketJob.fromJson(Map<String, dynamic> json) {
    return TicketJob(
      id: _parseInt(json['id']),
      body: json['body'] as String? ?? '',
      base64: _parseBool(json['base64']),
      appVersion: _parseDouble(json['appversion'], 1.0),
      printed: _parseBool(json['printed']),
      title: json['title'] as String? ?? '',
    );
  }

  /// Bytes a enviar a la impresora. Si el ticket viene en base64 se
  /// decodifica; si viene en texto plano se codifica byte a byte (latin1)
  /// para preservar los comandos ESC/POS, igual que hace mc20printer con
  /// `atob()` / la cadena cruda.
  Uint8List get bodyBytes {
    if (base64) {
      return base64Decode(body.trim());
    }
    return Uint8List.fromList(latin1.encode(body));
  }

  // La API puede devolver los booleanos como bool, int o cadena '0'/'1'.
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
