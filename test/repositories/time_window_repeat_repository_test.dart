import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/goal_repeat_series.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  test('TimeWindowRepeatRepository round-trips series', () async {
    final storage = InMemoryKeyValueStorage();
    final repo = TimeWindowRepeatRepository(storage);
    const series = GoalRepeatSeries(
      seriesId: 42,
      repeatRule: RepeatRule(
        enabled: true,
        unit: RepeatUnit.days,
        interval: 1,
      ),
      windowDuration: Duration(hours: 1),
      anchorEndAt: '2026-06-21T18:00:00.000',
      title: 'Walk',
      category: 'Health',
      complexity: 'Low',
      effort: 'Low',
      motivation: 'Low',
      time: 10,
      steps: 1,
    );

    await repo.upsert(series);
    final read = await repo.readById(42);
    expect(read?.title, 'Walk');
    expect(read?.repeatRule.enabled, isTrue);
    expect((await repo.readActive()).length, 1);
  });
}
