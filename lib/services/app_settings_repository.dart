import 'dart:convert';

import '../models/app_settings.dart';
import 'stores.dart';

/// Persistencia de los ajustes globales de la app.
class AppSettingsRepository {
  static const _key = 'app_settings';

  final KeyValueStore store;

  const AppSettingsRepository({required this.store});

  Future<AppSettings> load() async {
    final raw = await store.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const AppSettings();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const AppSettings();
      }
      return AppSettings.fromJson(decoded);
    } on FormatException {
      // Contenido corrupto: no debe impedir el arranque de la app.
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await store.setString(_key, jsonEncode(settings.toJson()));
  }
}
