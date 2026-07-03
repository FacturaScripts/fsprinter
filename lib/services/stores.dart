import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacén clave-valor para la configuración no sensible.
/// Se abstrae para poder usar una implementación en memoria en los tests.
abstract class KeyValueStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

/// Implementación real sobre shared_preferences.
class PrefsStore implements KeyValueStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Implementación en memoria para tests.
class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async =>
      values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Almacén de secretos (API keys). Implementación real sobre el llavero
/// del sistema mediante flutter_secure_storage.
abstract class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Almacén de secretos que reutiliza un [KeyValueStore].
///
/// Se usa en escritorio: el llavero del sistema en macOS exige firmar con un
/// certificado de desarrollo (flutter_secure_storage lanza
/// errSecMissingEntitlement, -34018, con firma ad-hoc). Aquí la API key se
/// guarda junto al resto de la configuración, protegida por los permisos del
/// usuario del sistema operativo.
class KeyValueSecretStore implements SecretStore {
  final KeyValueStore store;

  const KeyValueSecretStore(this.store);

  @override
  Future<String?> read(String key) => store.getString(key);

  @override
  Future<void> write(String key, String value) => store.setString(key, value);

  @override
  Future<void> delete(String key) => store.remove(key);
}

/// Implementación en memoria para tests.
class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
