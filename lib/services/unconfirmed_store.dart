import 'dart:convert';

import 'stores.dart';

/// Registro persistente de tickets "impresos pero no confirmados": se
/// imprimieron correctamente pero el PUT `printed=1` falló. En el siguiente
/// pull se reintenta solo la confirmación, sin volver a imprimir.
class UnconfirmedStore {
  final KeyValueStore store;
  final String linkId;

  const UnconfirmedStore({required this.store, required this.linkId});

  String get _key => 'unconfirmed_$linkId';

  Future<Set<int>> _load() async {
    final raw = await store.getString(_key);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return {};
    }
    return decoded.whereType<int>().toSet();
  }

  Future<bool> contains(int ticketId) async {
    return (await _load()).contains(ticketId);
  }

  Future<void> add(int ticketId) async {
    final ids = await _load();
    ids.add(ticketId);
    await store.setString(_key, jsonEncode(ids.toList()));
  }

  Future<void> remove(int ticketId) async {
    final ids = await _load();
    ids.remove(ticketId);
    await store.setString(_key, jsonEncode(ids.toList()));
  }
}
