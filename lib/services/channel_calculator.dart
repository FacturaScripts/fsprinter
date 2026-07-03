import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Cálculo del canal del relay de impresión.
///
/// Debe producir EXACTAMENTE el mismo resultado que el plugin Tickets
/// (`Lib/Mc20Printer.php`) y que mc20printer (`src/index.js`), porque el
/// canal es el punto de encuentro entre la instalación y la app:
///
///   canal = md5(url_normalizada)
///   canal = md5(url_normalizada + ':' + apikey)   si el host es local
///
/// Normalización: esquema y host en minúsculas, sin puertos por defecto
/// (80/443), se conserva el path y se elimina la barra final.
class ChannelCalculator {
  static const relayBaseUrl = 'https://ai.factura.city/mc20printer/';
  static const relayWsBaseUrl = 'wss://ai.factura.city/mc20printer/';

  static const _localHosts = ['localhost', '127.0.0.1', '[::1]', '::1'];

  /// Réplica de `Mc20Printer::normalize()`. Si la URL no tiene esquema o
  /// host se devuelve tal cual (recortada), igual que el PHP.
  static String normalize(String url) {
    final trimmed = url.trim();

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException {
      return trimmed;
    }
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      return trimmed;
    }

    final scheme = uri.scheme.toLowerCase();
    // Uri.host devuelve las IPv6 sin corchetes; hay que restaurarlos para
    // producir la misma cadena que JS/PHP.
    var host = uri.host.toLowerCase();
    if (host.contains(':')) {
      host = '[$host]';
    }

    var result = '$scheme://$host';

    if (uri.hasPort) {
      final isDefault = (scheme == 'http' && uri.port == 80) ||
          (scheme == 'https' && uri.port == 443);
      if (!isDefault) {
        result += ':${uri.port}';
      }
    }

    result += uri.path;

    if (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// Réplica de `Mc20Printer::isLocalhost()`.
  static bool isLocalhost(String url) {
    final Uri uri;
    try {
      uri = Uri.parse(url.trim());
    } on FormatException {
      return false;
    }
    if (uri.host.isEmpty) {
      return false;
    }

    var host = uri.host.toLowerCase();
    if (host.contains(':') && !host.startsWith('[')) {
      host = '[$host]';
    }
    return _localHosts.contains(host) || _localHosts.contains(uri.host);
  }

  /// Canal md5 para una instalación. En hosts locales se añade la API key
  /// para desambiguar instalaciones que comparten hostname.
  static String channel(String apiUrl, String apiKey) {
    var input = normalize(apiUrl);
    if (isLocalhost(input) && apiKey.isNotEmpty) {
      input += ':$apiKey';
    }
    return md5.convert(utf8.encode(input)).toString();
  }

  /// URL del WebSocket del relay para una instalación.
  static String wsUrl(String apiUrl, String apiKey) {
    return relayWsBaseUrl + channel(apiUrl, apiKey);
  }
}
