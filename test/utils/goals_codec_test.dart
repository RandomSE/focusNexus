import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/goals_codec.dart';

void main() {
  group('GoalsCodec', () {
    test('decodeList returns empty for null and malformed', () {
      expect(GoalsCodec.decodeList(null), isEmpty);
      expect(GoalsCodec.decodeList('not json'), isEmpty);
      expect(GoalsCodec.decodeList('{}'), isEmpty);
    });

    test('encode and decode roundtrip', () {
      const goals = [
        GoalSet(
          title: 'Run',
          category: 'Health',
          time: 15,
          steps: 2,
          goalId: 42,
          deadline: '01 January 2027 12:00',
        ),
      ];
      final json = GoalsCodec.encodeList(goals);
      final loaded = GoalsCodec.decodeList(json);
      expect(loaded.single.title, 'Run');
      expect(loaded.single.goalId, 42);
      expect(loaded.single.time, 15);
      expect(loaded.single.steps, 2);
    });

    test('decodeList accepts legacy string numeric fields', () {
      const raw = '[{"title":"Legacy","time":"9","steps":"3","Id":"7"}]';
      final loaded = GoalsCodec.decodeList(raw);
      expect(loaded.single.time, 9);
      expect(loaded.single.steps, 3);
      expect(loaded.single.goalId, 7);
    });
  });
}
