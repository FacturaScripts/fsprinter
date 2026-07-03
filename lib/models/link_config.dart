import 'printer_ref.dart';

/// Configuración de un vínculo instalación de FacturaScripts ↔ impresora.
///
/// Un mismo dispositivo puede tener varios vínculos, cada uno con su URL,
/// su API key (la de la impresora registrada en el plugin Tickets) y su
/// impresora física asignada. La API key no se serializa aquí: se guarda
/// aparte en almacenamiento seguro, indexada por [id].
class LinkConfig {
  final String id;
  final String name;
  final String apiUrl;
  final String apiKey;
  final PrinterRef? printer;
  final int lineLen;

  /// Segundos entre pulls de respaldo; 0 = solo WebSocket/push.
  final int pollingSeconds;

  /// Anteponer `ESC @` (inicializar impresora) al cuerpo de cada trabajo,
  /// como hace mc20printer. Desactivar para formatos como ZPL.
  final bool sendInit;

  final bool enabled;

  const LinkConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    required this.apiKey,
    this.printer,
    this.lineLen = 48,
    this.pollingSeconds = 0,
    this.sendInit = true,
    this.enabled = true,
  });

  LinkConfig copyWith({
    String? name,
    String? apiUrl,
    String? apiKey,
    PrinterRef? printer,
    int? lineLen,
    int? pollingSeconds,
    bool? sendInit,
    bool? enabled,
  }) {
    return LinkConfig(
      id: id,
      name: name ?? this.name,
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      printer: printer ?? this.printer,
      lineLen: lineLen ?? this.lineLen,
      pollingSeconds: pollingSeconds ?? this.pollingSeconds,
      sendInit: sendInit ?? this.sendInit,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Serialización SIN la API key (va en almacenamiento seguro).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'apiUrl': apiUrl,
        'printer': printer?.toJson(),
        'lineLen': lineLen,
        'pollingSeconds': pollingSeconds,
        'sendInit': sendInit,
        'enabled': enabled,
      };

  factory LinkConfig.fromJson(Map<String, dynamic> json, {String apiKey = ''}) {
    return LinkConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      apiUrl: json['apiUrl'] as String? ?? '',
      apiKey: apiKey,
      printer: json['printer'] == null
          ? null
          : PrinterRef.fromJson(json['printer'] as Map<String, dynamic>),
      lineLen: json['lineLen'] as int? ?? 48,
      pollingSeconds: json['pollingSeconds'] as int? ?? 0,
      sendInit: json['sendInit'] as bool? ?? true,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
