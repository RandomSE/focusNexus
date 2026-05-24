import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/completed_today_codec.dart';
import 'package:focusNexus/utils/goals_codec.dart';

/// Active, completed, and paused goal lists plus daily completion streak.
class GoalsRepository {
  GoalsRepository(this._storage);

  final KeyValueStorage _storage;

  Future<List<Map<String, dynamic>>> readActiveGoals() async {
    final raw = await _storage.read(key: StorageKeys.activeGoals);
    return GoalsCodec.decodeList(raw);
  }

  Future<void> writeActiveGoals(List<Map<String, dynamic>> goals) async {
    await _storage.write(
      key: StorageKeys.activeGoals,
      value: GoalsCodec.encodeList(goals),
    );
  }

  Future<List<Map<String, dynamic>>> readCompletedGoals() async {
    final raw = await _storage.read(key: StorageKeys.completedGoals);
    return GoalsCodec.decodeList(raw);
  }

  Future<void> writeCompletedGoals(List<Map<String, dynamic>> goals) async {
    await _storage.write(
      key: StorageKeys.completedGoals,
      value: GoalsCodec.encodeList(goals),
    );
  }

  /// Whether goal deadlines are paused (accepts legacy `True` casing).
  Future<bool> areDeadlinesPaused() async {
    final raw = await _storage.read(key: StorageKeys.pauseGoals);
    return raw != null && raw.toLowerCase() == 'true';
  }

  Future<void> setDeadlinesPaused(bool paused) async {
    await _storage.write(
      key: StorageKeys.pauseGoals,
      value: paused ? 'true' : 'false',
    );
  }

  Future<String?> readCompletedTodayRaw() =>
      _storage.read(key: StorageKeys.completedToday);

  Future<void> writeCompletedToday({required String today, required int count}) {
    return _storage.write(
      key: StorageKeys.completedToday,
      value: CompletedTodayCodec.encode(today: today, count: count),
    );
  }

  Future<int> nextCompletedTodayCount(String today) async {
    final stored = await readCompletedTodayRaw();
    return CompletedTodayCodec.nextCount(stored: stored, today: today);
  }
}
