import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late AchievementService service;

  setUpAll(() async {
    service = AchievementService(
      storage: InMemoryKeyValueStorage(),
      soundService: SoundService(InMemoryKeyValueStorage()),
    );
    await service.setInitializationPrerequisites();
  });

  group('AchievementService.getVariableForAchievement', () {
    test('maps known achievement ids to tracking variables', () {
      expect(service.getVariableForAchievement('1'), 'totalGoalsCreated');
      expect(service.getVariableForAchievement('6'), 'totalGoalsCompleted');
      expect(service.getVariableForAchievement('18'), 'goalsCompletedWithHighPoints');
      expect(
        service.getVariableForAchievement('94'),
        'consecutiveWeeksWithGoalsCompleted',
      );
      expect(
        service.getVariableForAchievement('100'),
        StorageKeys.categoriesWithAtLeast1Goal,
      );
      expect(
        service.getVariableForAchievement('105'),
        StorageKeys.categoriesWithAllTypesCompleted,
      );
    });

    test('returns null for unknown id', () {
      expect(service.getVariableForAchievement('999'), isNull);
    });
  });
}
