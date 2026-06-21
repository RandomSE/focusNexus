import 'package:focusNexus/models/classes/goal_repeat_series.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/time_window_repeat_codec.dart';

class TimeWindowRepeatRepository {
  TimeWindowRepeatRepository(this._storage);

  final KeyValueStorage _storage;

  Future<List<GoalRepeatSeries>> readAll() async {
    final raw = await _storage.read(key: StorageKeys.timeWindowRepeatSeries);
    return TimeWindowRepeatCodec.decodeList(raw);
  }

  Future<void> writeAll(List<GoalRepeatSeries> series) async {
    await _storage.write(
      key: StorageKeys.timeWindowRepeatSeries,
      value: TimeWindowRepeatCodec.encodeList(series),
    );
  }

  Future<GoalRepeatSeries?> readById(int seriesId) async {
    final all = await readAll();
    for (final series in all) {
      if (series.seriesId == seriesId) return series;
    }
    return null;
  }

  Future<void> upsert(GoalRepeatSeries series) async {
    final all = await readAll();
    final index = all.indexWhere((s) => s.seriesId == series.seriesId);
    if (index >= 0) {
      all[index] = series;
    } else {
      all.add(series);
    }
    await writeAll(all);
  }

  Future<List<GoalRepeatSeries>> readActive() async {
    final all = await readAll();
    return all.where((s) => s.isActive).toList();
  }
}
