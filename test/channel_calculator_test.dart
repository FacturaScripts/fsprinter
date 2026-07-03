import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/services/channel_calculator.dart';

void main() {
  // Los md5 esperados se han calculado con PHP (misma función que usa el
  // plugin Tickets en Mc20Printer::channel()).
  group('ChannelCalculator.normalize', () {
    test('minúsculas en esquema y host, sin puerto por defecto ni barra final',
        () {
      expect(ChannelCalculator.normalize('HTTPS://Example.COM:443/'),
          'https://example.com');
      expect(ChannelCalculator.normalize('http://Example.com:80/'),
          'http://example.com');
      expect(ChannelCalculator.normalize('https://example.com'),
          'https://example.com');
    });

    test('conserva puertos no estándar y el path', () {
      expect(ChannelCalculator.normalize('https://Example.com:8080/fs/'),
          'https://example.com:8080/fs');
      expect(ChannelCalculator.normalize('http://example.com/fs'),
          'http://example.com/fs');
    });

    test('recorta espacios', () {
      expect(ChannelCalculator.normalize('  https://example.com/  '),
          'https://example.com');
    });

    test('devuelve la URL tal cual si no tiene esquema o host', () {
      expect(ChannelCalculator.normalize('example.com'), 'example.com');
      expect(ChannelCalculator.normalize('  no-es-url  '), 'no-es-url');
    });
  });

  group('ChannelCalculator.isLocalhost', () {
    test('detecta hosts locales', () {
      expect(ChannelCalculator.isLocalhost('http://localhost/fs'), isTrue);
      expect(ChannelCalculator.isLocalhost('http://127.0.0.1:8000'), isTrue);
      expect(ChannelCalculator.isLocalhost('http://[::1]/fs'), isTrue);
      expect(ChannelCalculator.isLocalhost('HTTP://LOCALHOST/'), isTrue);
    });

    test('no marca hosts públicos ni URLs inválidas', () {
      expect(ChannelCalculator.isLocalhost('https://example.com'), isFalse);
      expect(ChannelCalculator.isLocalhost('https://midominio.local'), isFalse);
      expect(ChannelCalculator.isLocalhost('no-es-url'), isFalse);
    });
  });

  group('ChannelCalculator.channel', () {
    test('URL pública: md5 de la URL normalizada, ignora la API key', () {
      // md5('https://example.com') calculado con PHP
      const expected = 'c984d06aafbecf6bc55569f964148ea3';
      expect(ChannelCalculator.channel('https://example.com', 'abc123'),
          expected);
      expect(ChannelCalculator.channel('HTTPS://Example.COM:443/', 'otra'),
          expected);
    });

    test('URL local: añade :apikey antes del md5', () {
      // md5('http://localhost/fs:abc123') calculado con PHP
      expect(ChannelCalculator.channel('http://localhost/fs/', 'abc123'),
          'd7f88f529a8e13f21b4fe4af7f57f6af');
    });

    test('URL pública con puerto no estándar y path', () {
      // md5('https://example.com:8080/fs') calculado con PHP
      expect(ChannelCalculator.channel('https://Example.com:8080/fs/', 'x'),
          'dc2528f7626ab2dd91e1888465c804ec');
    });

    test('misma URL con y sin barra final produce el mismo canal', () {
      expect(
        ChannelCalculator.channel('https://example.com/', 'k'),
        ChannelCalculator.channel('https://example.com', 'k'),
      );
    });
  });

  test('wsUrl apunta al relay con el canal calculado', () {
    expect(
      ChannelCalculator.wsUrl('https://example.com', 'k'),
      'wss://ai.factura.city/mc20printer/c984d06aafbecf6bc55569f964148ea3',
    );
  });
}
