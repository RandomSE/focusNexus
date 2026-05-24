import 'package:focusNexus/services/storage/key_value_storage.dart';

/// In-memory [KeyValueStorage] for unit tests.
class InMemoryKeyValueStorage implements KeyValueStorage {
  InMemoryKeyValueStorage({Map<String, String>? initial}) : _data = Map.of(initial ?? {});

  final Map<String, String> _data;

  Map<String, String> get snapshot => Map.unmodifiable(_data);

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}
