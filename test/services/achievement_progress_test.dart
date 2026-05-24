import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/achievement_progress.dart';

void main() {
  group('AchievementProgress.percentComplete', () {
    test('computes rounded percent', () {
      expect(AchievementProgress.percentComplete(5, 10), 50.0);
      expect(AchievementProgress.percentComplete(1, 3), 33.3);
    });

    test('returns zero when repetitions needed is non-positive', () {
      expect(AchievementProgress.percentComplete(5, 0), 0);
    });
  });

  group('AchievementProgress.shouldBlockProgressDecrease', () {
    test('blocks when already at 100 and new progress is lower', () {
      expect(AchievementProgress.shouldBlockProgressDecrease(100, 80), isTrue);
      expect(AchievementProgress.shouldBlockProgressDecrease(100, 100), isTrue);
    });

    test('allows increase from partial progress', () {
      expect(AchievementProgress.shouldBlockProgressDecrease(50, 80), isFalse);
    });
  });

  group('AchievementProgress.parsePointsFromReward', () {
    test('extracts digits from reward strings', () {
      expect(AchievementProgress.parsePointsFromReward('250 points'), 250);
      expect(AchievementProgress.parsePointsFromReward('no digits'), 0);
    });
  });
}
