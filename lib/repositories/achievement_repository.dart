import 'dart:convert';

import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Persisted achievement catalog blob (definitions + progress).
class AchievementRepository {
  AchievementRepository(this._storage);

  final KeyValueStorage _storage;

  Future<List<Achievement>?> loadAll() async {
    final jsonStr = await _storage.read(key: StorageKeys.achievements);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    final decoded = jsonDecode(jsonStr) as List<dynamic>;
    return decoded
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Achievement> achievements) async {
    final encoded =
        jsonEncode(achievements.map((a) => a.toJson()).toList());
    await _storage.write(key: StorageKeys.achievements, value: encoded);
  }

  Future<void> clear() => _storage.delete(key: StorageKeys.achievements);
}
