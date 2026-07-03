import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/link_config.dart';
import 'package:fsprinter/models/printer_ref.dart';
import 'package:fsprinter/services/settings_repository.dart';
import 'package:fsprinter/services/stores.dart';

void main() {
  late MemoryStore store;
  late KeyValueSecretStore secrets;

  setUp(() {
    store = MemoryStore();
    secrets = KeyValueSecretStore(store);
  });

  test('escribe, lee y borra secretos usando el almacén clave-valor',
      () async {
    await secrets.write('apikey_a', 'super-secreta');

    // El valor queda en el mismo almacén clave-valor subyacente.
    expect(store.values['apikey_a'], 'super-secreta');
    expect(await secrets.read('apikey_a'), 'super-secreta');

    await secrets.delete('apikey_a');
    expect(await secrets.read('apikey_a'), isNull);
    expect(store.values.containsKey('apikey_a'), isFalse);
  });

  test('leer una clave inexistente devuelve null', () async {
    expect(await secrets.read('apikey_desconocida'), isNull);
  });

  test('sobrescribir una clave actualiza su valor', () async {
    await secrets.write('apikey_a', 'antigua');
    await secrets.write('apikey_a', 'nueva');

    expect(await secrets.read('apikey_a'), 'nueva');
  });

  test('SettingsRepository funciona con KeyValueSecretStore en escritorio',
      () async {
    // En escritorio la API key comparte almacén con la config, pero el
    // repositorio la sigue guardando bajo su propia clave (apikey_<id>) y
    // no dentro del JSON de vínculos.
    final repo = SettingsRepository(store: store, secrets: secrets);
    final link = _buildLink('a', apiKey: 'clave-desktop');

    await repo.saveLink(link);

    final loaded = await repo.loadLinks();
    expect(loaded, hasLength(1));
    expect(loaded.first.apiKey, 'clave-desktop');
    // La API key no debe filtrarse dentro del JSON de la lista de vínculos.
    expect(store.values['links'], isNot(contains('clave-desktop')));
    expect(store.values['apikey_a'], 'clave-desktop');
  });
}

LinkConfig _buildLink(String id, {required String apiKey}) => LinkConfig(
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
