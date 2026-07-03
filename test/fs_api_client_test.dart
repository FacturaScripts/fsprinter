import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/services/fs_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const apiKey = 'clave-secreta';

  group('FsApiClient.fetchPrinterId', () {
    test('devuelve el id de la impresora con la apikey configurada', () async {
      http.Request? captured;
      final client = FsApiClient(
        apiUrl: 'https://example.com/',
        apiKey: apiKey,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode([
              {'id': 1, 'apikey': 'otra'},
              {'id': 5, 'apikey': apiKey},
            ]),
            200,
          );
        }),
      );

      final id = await client.fetchPrinterId();

      expect(id, 5);
      expect(captured!.url.toString(),
          'https://example.com/api/3/ticketprinteres');
      expect(captured!.headers['Token'], apiKey,
          reason: 'la autenticación es la cabecera Token');
    });

    test('devuelve null si ninguna impresora coincide', () async {
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((_) async => http.Response(jsonEncode([]), 200)),
      );

      expect(await client.fetchPrinterId(), isNull);
    });

    test('lanza FsApiException si la API devuelve error', () async {
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((_) async => http.Response('nope', 403)),
      );

      expect(client.fetchPrinterId(), throwsA(isA<FsApiException>()));
    });
  });

  group('FsApiClient.fetchPendingTickets', () {
    test('consulta con los filtros de mc20printer y parsea los tickets',
        () async {
      http.Request? captured;
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode([
              {'id': 3, 'body': 'SG9sYQ==', 'base64': true, 'appversion': 1},
            ]),
            200,
          );
        }),
      );

      final tickets = await client.fetchPendingTickets(5);

      expect(captured!.url.path, '/api/3/ticketes');
      expect(captured!.url.queryParameters['filter[printed]'], '0');
      expect(captured!.url.queryParameters['filter[idprinter]'], '5');
      expect(tickets, hasLength(1));
      expect(tickets.first.id, 3);
      expect(utf8.decode(tickets.first.bodyBytes), 'Hola');
    });
  });

  group('FsApiClient.markPrinted', () {
    test('hace PUT con printed=1', () async {
      http.Request? captured;
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
      );

      await client.markPrinted(3);

      expect(captured!.method, 'PUT');
      expect(captured!.url.path, '/api/3/ticketes/3');
      expect(captured!.bodyFields, {'printed': '1'});
    });
  });

  group('FsApiClient.heartbeat', () {
    test('envía lastactivity en formato YYYY-MM-DD HH:MM:SS y linelen',
        () async {
      http.Request? captured;
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
      );

      await client.heartbeat(5, 48, now: DateTime(2026, 7, 2, 9, 5, 3));

      expect(captured!.method, 'PUT');
      expect(captured!.url.path, '/api/3/ticketprinteres/5');
      expect(captured!.bodyFields, {
        'lastactivity': '2026-07-02 09:05:03',
        'linelen': '48',
      });
    });
  });

  group('FsApiClient.testConnection', () {
    test('rechaza URLs sin http/https y API key vacía', () {
      final badUrl = FsApiClient(
        apiUrl: 'ftp://example.com',
        apiKey: apiKey,
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(badUrl.testConnection(), throwsA(isA<FsApiException>()));

      final noKey = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: '',
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(noKey.testConnection(), throwsA(isA<FsApiException>()));
    });

    test('falla si la API responde pero ninguna impresora tiene la key',
        () async {
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((_) async => http.Response(
            jsonEncode([
              {'id': 1, 'apikey': 'otra'}
            ]),
            200)),
      );

      expect(client.testConnection(), throwsA(isA<FsApiException>()));
    });

    test('devuelve el id de impresora si todo es correcto', () async {
      final client = FsApiClient(
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        client: MockClient((_) async => http.Response(
            jsonEncode([
              {'id': 5, 'apikey': apiKey}
            ]),
            200)),
      );

      expect(await client.testConnection(), 5);
    });
  });
}
