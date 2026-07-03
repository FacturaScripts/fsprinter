import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/link_config.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/services/settings_repository.dart';
import 'package:fsprinter/services/stores.dart';

void main() {
  late MemoryStore store;
  late MemorySecretStore secrets;
  late SettingsRepository repo;

  setUp(() {
    store = MemoryStore();
    secrets = MemorySecretStore();
    repo = SettingsRepository(store: store, secrets: secrets);
  });

  LinkConfig buildLink(String id, {String apiKey = 'clave'}) => LinkConfig(
        id: id,
        name: 'Vínculo $id',
        apiUrl: 'https://example.com',
        apiKey: apiKey,
        printer: const PrinterRef(
          type: PrinterType.network,
          address: '192.168.1.50',
        ),
        lineLen: 32,
        pollingSeconds: 60,
        sendInit: false,
      );

  test('guarda y recupera vínculos con todos sus campos', () async {
    await repo.saveLink(buildLink('a'));

    final links = await repo.loadLinks();
    expect(links, hasLength(1));
    final link = links.first;
    expect(link.name, 'Vínculo a');
    expect(link.apiKey, 'clave');
    expect(link.printer!.address, '192.168.1.50');
    expect(link.lineLen, 32);
    expect(link.pollingSeconds, 60);
    expect(link.sendInit, isFalse);
  });

  test('la API key va al almacén seguro, no al JSON de configuración',
      () async {
    await repo.saveLink(buildLink('a', apiKey: 'super-secreta'));

    expect(store.values['links'], isNot(contains('super-secreta')));
    expect(secrets.values['apikey_a'], 'super-secreta');
  });

  test('actualiza un vínculo existente sin duplicarlo', () async {
    await repo.saveLink(buildLink('a'));
    await repo.saveLink(buildLink('a').copyWith(name: 'Renombrado'));

    final links = await repo.loadLinks();
    expect(links, hasLength(1));
    expect(links.first.name, 'Renombrado');
  });

  test('exportar e importar en otro dispositivo conserva todo', () async {
    await repo.saveLink(buildLink('a', apiKey: 'clave-a'));
    await repo.saveLink(buildLink('b', apiKey: 'clave-b'));

    final exported = await repo.exportLinks();

    // "Otro dispositivo": almacenes vacíos.
    final other = SettingsRepository(
      store: MemoryStore(),
      secrets: MemorySecretStore(),
    );
    final count = await other.importLinks(exported);

    expect(count, 2);
    final links = await other.loadLinks();
    expect(links.map((l) => l.id).toSet(), {'a', 'b'});
    expect(links.firstWhere((l) => l.id == 'a').apiKey, 'clave-a');
    expect(links.firstWhere((l) => l.id == 'b').printer!.address,
        '192.168.1.50');
  });

  test('importar actualiza los vínculos existentes sin duplicar', () async {
    await repo.saveLink(buildLink('a'));
    final exported = await repo.exportLinks();

    await repo.saveLink(buildLink('a').copyWith(name: 'Cambiado'));
    await repo.importLinks(exported);

    final links = await repo.loadLinks();
    expect(links, hasLength(1));
    expect(links.first.name, 'Vínculo a');
  });

  test('importar texto inválido lanza FormatException', () async {
    expect(() => repo.importLinks('no es json'),
        throwsA(isA<FormatException>()));
    expect(() => repo.importLinks('{"otra":"cosa"}'),
        throwsA(isA<FormatException>()));
  });

  test('elimina un vínculo y su secreto', () async {
    await repo.saveLink(buildLink('a'));
    await repo.saveLink(buildLink('b'));

    await repo.deleteLink('a');

    final links = await repo.loadLinks();
    expect(links.map((l) => l.id), ['b']);
    expect(secrets.values.containsKey('apikey_a'), isFalse);
  });
}
