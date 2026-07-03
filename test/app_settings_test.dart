import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/models/app_settings.dart';
import 'package:fsprinter/services/app_settings_repository.dart';
import 'package:fsprinter/services/stores.dart';

void main() {
  test('devuelve valores por defecto sin configuración previa', () async {
    final repo = AppSettingsRepository(store: MemoryStore());

    final settings = await repo.load();

    expect(settings.launchAtStartup, isFalse);
    expect(settings.startHidden, isFalse);
  });

  test('guarda y recupera los ajustes', () async {
    final store = MemoryStore();
    final repo = AppSettingsRepository(store: store);

    await repo.save(const AppSettings(launchAtStartup: true, startHidden: true));

    final settings = await repo.load();
    expect(settings.launchAtStartup, isTrue);
    expect(settings.startHidden, isTrue);
  });

  test('tolera contenido corrupto devolviendo los valores por defecto',
      () async {
    final store = MemoryStore();
    store.values['app_settings'] = 'esto no es json{{{';

    final settings = await AppSettingsRepository(store: store).load();

    expect(settings.launchAtStartup, isFalse);
    expect(settings.startHidden, isFalse);
  });
}
