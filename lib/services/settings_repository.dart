import 'dart:convert';

import '../models/link_config.dart';
import 'stores.dart';

/// Carga y guarda la lista de vínculos.
///
/// La configuración va en el almacén clave-valor (JSON bajo la clave
/// `links`); las API keys van aparte en el almacén seguro del sistema,
/// bajo `apikey_<id>`.
class SettingsRepository {
  static const _linksKey = 'links';

  final KeyValueStore store;
  final SecretStore secrets;

  const SettingsRepository({required this.store, required this.secrets});

  Future<List<LinkConfig>> loadLinks() async {
    final raw = await store.getString(_linksKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    final links = <LinkConfig>[];
    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final id = item['id'] as String?;
      if (id == null) {
        continue;
      }
      final apiKey = await secrets.read(_secretKey(id)) ?? '';
      links.add(LinkConfig.fromJson(item, apiKey: apiKey));
    }
    return links;
  }

  /// Crea o actualiza un vínculo (según su id).
  Future<void> saveLink(LinkConfig link) async {
    final links = await loadLinks();
    final index = links.indexWhere((l) => l.id == link.id);
    if (index >= 0) {
      links[index] = link;
    } else {
      links.add(link);
    }

    await secrets.write(_secretKey(link.id), link.apiKey);
    await _persist(links);
  }

  Future<void> deleteLink(String id) async {
    final links = await loadLinks();
    links.removeWhere((l) => l.id == id);
    await _persist(links);
    await secrets.delete(_secretKey(id));
  }

  /// Exporta todos los vínculos, API keys incluidas, como JSON portable
  /// para migrar la configuración a otro dispositivo.
  Future<String> exportLinks() async {
    final links = await loadLinks();
    return jsonEncode({
      'fsprinter': 1,
      'links': [
        for (final link in links) {...link.toJson(), 'apiKey': link.apiKey},
      ],
    });
  }

  /// Importa vínculos exportados con [exportLinks]. Los ids existentes se
  /// actualizan y los nuevos se añaden. Devuelve cuántos se importaron.
  /// Lanza [FormatException] si el texto no es una exportación válida.
  Future<int> importLinks(String raw) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('JSON inválido');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['fsprinter'] != 1 ||
        decoded['links'] is! List) {
      throw const FormatException('No es una exportación de fsprinter');
    }

    var count = 0;
    for (final item
        in (decoded['links'] as List).whereType<Map<String, dynamic>>()) {
      final id = item['id'];
      if (id is! String || id.isEmpty) {
        continue;
      }
      final link =
          LinkConfig.fromJson(item, apiKey: item['apiKey'] as String? ?? '');
      await saveLink(link);
      count++;
    }
    return count;
  }

  Future<void> _persist(List<LinkConfig> links) async {
    final json = jsonEncode(links.map((l) => l.toJson()).toList());
    await store.setString(_linksKey, json);
  }

  static String _secretKey(String id) => 'apikey_$id';
}
