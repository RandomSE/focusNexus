import 'package:focusNexus/services/storage/key_value_storage.dart';

/// Scalar achievement counters persisted as stringified integers.
class AchievementCountersRepository {
  AchievementCountersRepository(this._storage);

  final KeyValueStorage _storage;

  Future<int> readInt(String key) async {
    final raw = await _storage.read(key: key);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> writeInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<void> increment(String key, {int by = 1}) async {
    final current = await readInt(key);
    await writeInt(key, current + by);
  }

  Future<void> decrement(String key, {int by = 1}) async {
    final current = await readInt(key);
    await writeInt(key, current - by);
  }

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> writeString(String key, String value) =>
      _storage.write(key: key, value: value);
}
