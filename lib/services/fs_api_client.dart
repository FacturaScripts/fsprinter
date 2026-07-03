import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/ticket_job.dart';

/// Error de comunicación con la API de FacturaScripts.
class FsApiException implements Exception {
  final String message;
  final int? statusCode;

  const FsApiException(this.message, {this.statusCode});

  @override
  String toString() => 'FsApiException: $message'
      '${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Cliente de la API REST del plugin Tickets de FacturaScripts.
///
/// Replica las llamadas de mc20printer: autenticación con cabecera `Token`,
/// localización de la impresora por su API key, descarga de tickets
/// pendientes, marcado como impreso y heartbeat de actividad.
class FsApiClient {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;
  final Duration timeout;

  FsApiClient({
    required String apiUrl,
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : baseUrl = _stripTrailingSlash(apiUrl.trim()),
        _client = client ?? http.Client();

  Map<String, String> get _headers => {'Token': apiKey};

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  /// Busca en `/api/3/ticketprinteres` el registro cuya `apikey` coincide
  /// con la configurada y devuelve su id, o null si no existe.
  Future<int?> fetchPrinterId() async {
    final printers = await _getList('/api/3/ticketprinteres');
    for (final item in printers) {
      if (item is Map<String, dynamic> && item['apikey'] == apiKey) {
        return TicketJob.fromJson({'id': item['id']}).id;
      }
    }
    return null;
  }

  /// Tickets pendientes de imprimir para la impresora indicada.
  Future<List<TicketJob>> fetchPendingTickets(int printerId) async {
    final list = await _getList('/api/3/ticketes', {
      'filter[printed]': '0',
      'filter[idprinter]': '$printerId',
    });
    return list
        .whereType<Map<String, dynamic>>()
        .map(TicketJob.fromJson)
        .toList();
  }

  /// Marca un ticket como impreso.
  Future<void> markPrinted(int ticketId) async {
    await _put('/api/3/ticketes/$ticketId', {'printed': '1'});
  }

  /// Heartbeat: actualiza `lastactivity` y `linelen` de la impresora.
  /// El plugin considera activa una impresora si su última actividad es de
  /// hace menos de 600 segundos.
  Future<void> heartbeat(int printerId, int lineLen, {DateTime? now}) async {
    final dateStr =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(now ?? DateTime.now());
    await _put('/api/3/ticketprinteres/$printerId', {
      'lastactivity': dateStr,
      'linelen': '$lineLen',
    });
  }

  /// Prueba de conexión: valida URL y API key resolviendo el id de la
  /// impresora. Lanza [FsApiException] si algo falla; devuelve el id.
  Future<int> testConnection() async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const FsApiException('La URL debe empezar por http:// o https://');
    }
    if (apiKey.isEmpty) {
      throw const FsApiException('Falta la API key');
    }

    final printerId = await fetchPrinterId();
    if (printerId == null) {
      throw const FsApiException(
          'Conexión correcta, pero ninguna impresora tiene esta API key');
    }
    return printerId;
  }

  Future<List<dynamic>> _getList(String path,
      [Map<String, String>? query]) async {
    final http.Response response;
    try {
      response =
          await _client.get(_uri(path, query), headers: _headers).timeout(timeout);
    } on FsApiException {
      rethrow;
    } catch (e) {
      throw FsApiException('No se pudo conectar: $e');
    }

    if (response.statusCode != 200) {
      throw FsApiException('Error al consultar $path',
          statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw FsApiException('Respuesta inesperada de $path (no es una lista)');
    }
    return decoded;
  }

  Future<void> _put(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await _client
          .put(_uri(path), headers: _headers, body: body)
          .timeout(timeout);
    } catch (e) {
      throw FsApiException('No se pudo conectar: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FsApiException('Error al actualizar $path',
          statusCode: response.statusCode);
    }
  }

  void close() => _client.close();
}
