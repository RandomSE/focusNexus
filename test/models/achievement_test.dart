import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';

void main() {
  test('fromJson and toJson roundtrip', () {
    final original = Achievement(
      id: '7',
      title: 'Weekly Warrior I',
      reward: '250 points',
      task: 'Complete goals in one calendar week 5 times',
      dateCompleted: DateTime.utc(2026, 5, 1, 10, 30),
      isCompleted: true,
      isSecret: false,
      progress: 55.5,
    );

    final restored = Achievement.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.dateCompleted, original.dateCompleted);
    expect(restored.isCompleted, isTrue);
    expect(restored.isSecret, isFalse);
    expect(restored.progress, 55.5);
  });

  test('fromJson applies defaults', () {
    final achievement = Achievement.fromJson({
      'id': '1',
      'title': 'T',
      'reward': '10 points',
      'task': 'Do thing',
      'isSecret': false,
    });
    expect(achievement.isCompleted, isFalse);
    expect(achievement.progress, 0.0);
    expect(achievement.dateCompleted, isNull);
  });
}
