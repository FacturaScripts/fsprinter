import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/link_status.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/models/ticket_job.dart';
import 'package:fsprinter/printing/printer_driver.dart';
import 'package:fsprinter/services/fs_api_client.dart';
import 'package:fsprinter/services/print_queue.dart';
import 'package:fsprinter/services/stores.dart';
import 'package:fsprinter/services/unconfirmed_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contador de concurrencia compartido entre varios drivers, para medir
/// solapamientos de envíos hacia una misma impresora física.
class Concurrency {
  int active = 0;
  int max = 0;
}

/// Driver falso: registra los envíos y puede fallar los N primeros.
class FakeDriver implements PrinterDriver {
  @override
  final PrinterRef printer;

  final List<Uint8List> sent = [];
  int failuresLeft;
  Duration sendDelay;
  final Concurrency concurrency;

  FakeDriver({
    this.printer = const PrinterRef(
        type: PrinterType.network, address: 'fake', port: 9100),
    this.failuresLeft = 0,
    this.sendDelay = Duration.zero,
    Concurrency? concurrency,
  }) : concurrency = concurrency ?? Concurrency();

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    concurrency.active++;
    concurrency.max = math.max(concurrency.max, concurrency.active);
    try {
      if (sendDelay > Duration.zero) {
        await Future<void>.delayed(sendDelay);
      }
      if (failuresLeft > 0) {
        failuresLeft--;
        throw const PrinterException('fallo simulado');
      }
      sent.add(bytes);
    } finally {
      concurrency.active--;
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  FsApiClient buildApi({bool failPut = false, List<http.Request>? requests}) {
    return FsApiClient(
      apiUrl: 'https://example.com',
      apiKey: 'k',
      client: MockClient((request) async {
        requests?.add(request);
        if (request.method == 'PUT' && failPut) {
          return http.Response('error', 500);
        }
        return http.Response('{}', 200);
      }),
    );
  }

  PrintQueue buildQueue({
    required FakeDriver driver,
    required FsApiClient api,
    required UnconfirmedStore unconfirmed,
    bool sendInit = true,
    void Function(JobLogEntry)? onJob,
  }) {
    return PrintQueue(
      driver: driver,
      api: api,
      unconfirmed: unconfirmed,
      sendInit: sendInit,
      retryDelays: const [Duration(milliseconds: 10)],
      onJob: onJob,
    );
  }

  UnconfirmedStore buildUnconfirmed([MemoryStore? store]) =>
      UnconfirmedStore(store: store ?? MemoryStore(), linkId: 'link1');

  const job = TicketJob(id: 3, body: 'SG9sYQ==', base64: true);

  test('imprime, antepone ESC @ y confirma printed=1', () async {
    final driver = FakeDriver();
    final requests = <http.Request>[];
    final queue = buildQueue(
      driver: driver,
      api: buildApi(requests: requests),
      unconfirmed: buildUnconfirmed(),
    );

    final ok = await queue.process(job);

    expect(ok, isTrue);
    expect(driver.sent, hasLength(1));
    expect(driver.sent.first.sublist(0, 2), [0x1B, 0x40]);
    expect(driver.sent.first.sublist(2), [0x48, 0x6F, 0x6C, 0x61]);
    expect(requests.single.url.path, '/api/3/ticketes/3');
    expect(requests.single.bodyFields, {'printed': '1'});
  });

  test('sin sendInit envía el cuerpo tal cual (preparado para ZPL)',
      () async {
    final driver = FakeDriver();
    final queue = buildQueue(
      driver: driver,
      api: buildApi(),
      unconfirmed: buildUnconfirmed(),
      sendInit: false,
    );

    await queue.process(job);

    expect(driver.sent.first, [0x48, 0x6F, 0x6C, 0x61]);
  });

  test('reintenta tras un fallo y termina imprimiendo', () async {
    final driver = FakeDriver(failuresLeft: 1);
    final log = <JobLogEntry>[];
    final queue = buildQueue(
      driver: driver,
      api: buildApi(),
      unconfirmed: buildUnconfirmed(),
      onJob: log.add,
    );

    final ok = await queue.process(job);

    expect(ok, isTrue);
    expect(driver.sent, hasLength(1));
    expect(log.single.success, isTrue);
    expect(log.single.attempts, 2);
  });

  test('si la impresora falla siempre NO se marca como impreso', () async {
    final driver = FakeDriver(failuresLeft: 99);
    final requests = <http.Request>[];
    final log = <JobLogEntry>[];
    final queue = buildQueue(
      driver: driver,
      api: buildApi(requests: requests),
      unconfirmed: buildUnconfirmed(),
      onJob: log.add,
    );

    final ok = await queue.process(job);

    expect(ok, isFalse);
    expect(requests, isEmpty, reason: 'nunca debe llegar el PUT printed=1');
    expect(log.single.success, isFalse);
  });

  test('impreso pero sin confirmar: no se reimprime en el siguiente pull',
      () async {
    final store = MemoryStore();
    final driver = FakeDriver();

    // Primera pasada: imprime bien pero el PUT falla.
    final queue1 = buildQueue(
      driver: driver,
      api: buildApi(failPut: true),
      unconfirmed: buildUnconfirmed(store),
    );
    expect(await queue1.process(job), isTrue);
    expect(driver.sent, hasLength(1));

    // Segunda pasada (el ticket sigue printed=0 en el servidor): solo
    // confirma, sin volver a imprimir.
    final requests = <http.Request>[];
    final queue2 = buildQueue(
      driver: driver,
      api: buildApi(requests: requests),
      unconfirmed: buildUnconfirmed(store),
    );
    expect(await queue2.process(job), isTrue);

    expect(driver.sent, hasLength(1), reason: 'no debe reimprimirse');
    expect(requests.single.bodyFields, {'printed': '1'});
  });

  test('dos vínculos sobre la misma impresora física no se solapan',
      () async {
    const sharedPrinter = PrinterRef(
        type: PrinterType.network, address: 'compartida', port: 9100);
    final shared = Concurrency();
    final driver1 = FakeDriver(
        printer: sharedPrinter,
        sendDelay: const Duration(milliseconds: 50),
        concurrency: shared);
    final driver2 = FakeDriver(
        printer: sharedPrinter,
        sendDelay: const Duration(milliseconds: 50),
        concurrency: shared);

    final queue1 = buildQueue(
      driver: driver1,
      api: buildApi(),
      unconfirmed: buildUnconfirmed(),
    );
    final queue2 = buildQueue(
      driver: driver2,
      api: buildApi(),
      unconfirmed: UnconfirmedStore(store: MemoryStore(), linkId: 'link2'),
    );

    await Future.wait([
      queue1.process(const TicketJob(id: 1, body: 'YQ==', base64: true)),
      queue2.process(const TicketJob(id: 2, body: 'Yg==', base64: true)),
    ]);

    // El mutex es global por impresora: nunca dos envíos a la vez.
    expect(shared.max, 1);
    expect(driver1.sent.length + driver2.sent.length, 2);
  });

  test('el mismo ticket no se procesa dos veces en paralelo', () async {
    final driver = FakeDriver(sendDelay: const Duration(milliseconds: 30));
    final queue = buildQueue(
      driver: driver,
      api: buildApi(),
      unconfirmed: buildUnconfirmed(),
    );

    final results = await Future.wait([
      queue.process(job),
      queue.process(job),
    ]);

    expect(results.where((r) => r), hasLength(1));
    expect(driver.sent, hasLength(1));
  });
}
