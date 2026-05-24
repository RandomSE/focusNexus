import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/templates_codec.dart';

/// User-defined goal templates and multi-template groups.
class TemplatesRepository {
  TemplatesRepository(this._storage);

  final KeyValueStorage _storage;

  Future<Map<String, Map<String, dynamic>>> readUserTemplates() async {
    final raw = await _storage.read(key: StorageKeys.userTemplates);
    return TemplatesCodec.decodeUserTemplates(raw);
  }

  Future<void> writeUserTemplates(
    Map<String, Map<String, dynamic>> templates,
  ) async {
    await _storage.write(
      key: StorageKeys.userTemplates,
      value: TemplatesCodec.encodeUserTemplates(templates),
    );
  }

  Future<Map<String, List<String>>> readTemplateGroups() async {
    final raw = await _storage.read(key: StorageKeys.templateGroups);
    return TemplatesCodec.decodeTemplateGroups(raw);
  }

  Future<void> writeTemplateGroups(Map<String, List<String>> groups) async {
    await _storage.write(
      key: StorageKeys.templateGroups,
      value: TemplatesCodec.encodeTemplateGroups(groups),
    );
  }
}
