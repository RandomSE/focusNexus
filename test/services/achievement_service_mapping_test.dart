import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/achievement_service.dart';

void main() {
  setUpAll(() async {
    await AchievementService().setInitializationPrerequisites();
  });

  group('AchievementService.getVariableForAchievement', () {
    test('maps known achievement ids to tracking variables', () {
      expect(AchievementService.getVariableForAchievement('1'), 'totalGoalsCreated');
      expect(AchievementService.getVariableForAchievement('6'), 'totalGoalsCompleted');
      expect(AchievementService.getVariableForAchievement('18'), 'goalsCompletedWithHighPoints');
      expect(AchievementService.getVariableForAchievement('94'), 'consecutiveWeeksWithGoalsCompleted');
    });

    test('returns null for unknown id', () {
      expect(AchievementService.getVariableForAchievement('999'), isNull);
    });
  });
}
