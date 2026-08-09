import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/repositories/theme_repository.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('FU-1 geometric cherry stages', () {
    test('0-5 follow ~4x series; stage 6 and path unchanged from rebalance', () {
      expect(
        [
          for (var i = 0; i < 7; i++) CherryBlossomStageCatalog.stageTotalFor(i),
        ],
        [500, 2000, 8000, 32000, 128000, 512000, 1000000],
      );
      expect(CherryBlossomStageCatalog.grandTotalToMaxStage6(), 1682500);
      expect(CherryBlossomStageCatalog.pathSwitchCost, 100000);
    });
  });

  group('FU-3 lifetime spend breadth', () {
    test('trySpend increments lifetimePointsSpent and unlocks via garden load',
        () async {
      final storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '50',
      });
      final points = PointsRepository(storage);
      final garden = GardenRepository(storage, points: points);

      await points.writeBalance(500);
      final spent = await points.trySpend(200);
      expect(spent, 300);
      expect(await points.readLifetimeSpent(), 200);

      // Simulate prior zen spend below threshold, wallet lifetime pushes over.
      await garden.save(
        const GardenState(
          pointsBalance: 300,
          lifetimeZenPointsSpent: 9900,
        ),
      );
      await points.ensureLifetimeSpentAtLeast(10000);
      final loaded = await garden.load();
      expect(loaded.lifetimeZenPointsSpent, greaterThanOrEqualTo(10000));
      expect(loaded.cherryBlossomTreeUnlocked, isTrue);
    });
  });

  group('FU-3 goal clawback', () {
    test('removeCompletedGoal claws back stored awarded points', () async {
      final storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '500',
      });
      final points = PointsRepository(storage);
      final goals = GoalsRepository(storage);
      final prefs = UserPrefsRepository(storage);
      final useCase = GoalsUseCase(
        goals: goals,
        points: points,
        streaks: AchievementStreakService(
          AchievementCountersRepository(storage),
          prefs,
        ),
        settings: AppSettings(prefs, ThemeRepository(prefs)),
        repeatSeries: TimeWindowRepeatRepository(storage),
      );

      await goals.writeCompletedGoals([
        const GoalSet(
          title: 'Done',
          goalId: 7,
          points: 180,
        ),
      ]);
      await useCase.removeCompletedGoal(7);
      expect(await points.readBalance(), 320);
      expect(await goals.readCompletedGoals(), isEmpty);
    });
  });

  group('FU-3 time-window label', () {
    test('mentions first-day split preview', () {
      final label = timeWindowGoalPointsLabel(
        GoalSet(
          title: 'Slot',
          goalId: 1,
          points: 80,
          actionWindowStart: DateTime(2026, 8, 8, 9).toIso8601String(),
          actionWindowEnd: DateTime(2026, 8, 8, 10).toIso8601String(),
        ),
      );
      expect(label, contains('80 pts'));
      expect(label, contains('if first today'));
      expect(label, contains('momentum'));
    });
  });

  group('FU-3 Rain Deluge IX', () {
    test('IX reward is above VIII after scale', () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();
      expect(service.getById('186')!.reward, '700 points');
      expect(service.getById('187')!.reward, '800 points');
    });
  });

  group('FU-5 path claim zen decor smoke', () {
    test('claim Peace adds zen decor and leaves bonsai count unchanged', () async {
      final storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '1000',
        'soundEnabled': 'false',
      });
      final points = PointsRepository(storage);
      final garden = GardenRepository(storage, points: points);
      final service = AchievementService(
        storage: storage,
        pointsRepository: points,
        gardenRepository: garden,
        soundService: SoundService(storage),
      );
      await service.initialize();
      await garden.save(
        const GardenState(
          pointsBalance: 1000,
          cherryBlossomTree: CherryBlossomTreeState(
            peaceBonsaiCount: 25,
            powerBonsaiCount: 10,
          ),
        ),
      );
      await service.removeAchievement('148');
      await service.addAchievement(
        const Achievement(
          id: '148',
          title: 'Path of Peace',
          reward: 'Zen Garden Peace bonsai +1',
          task: 'Complete the Peace finale path on the Cherry Blossom Tree',
          isSecret: true,
          progress: 100,
        ),
      );
      final before = await points.readBalance();
      await service.completeAchievement('148');
      expect(await points.readBalance(), before);
      final after = await garden.load();
      expect(after.cherryBlossomTree.peaceBonsaiCount, 25);
      expect(after.cherryBlossomTree.powerBonsaiCount, 10);
      expect(after.decorInventory.single.kind, zenPeaceBonsaiKind);
      expect(after.decorInventory.single.stageIndex, DecorItem.maxStageIndex);
    });

    test('claim Power adds zen.power_bonsai decor', () async {
      final storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '1000',
        'soundEnabled': 'false',
      });
      final points = PointsRepository(storage);
      final garden = GardenRepository(storage, points: points);
      final service = AchievementService(
        storage: storage,
        pointsRepository: points,
        gardenRepository: garden,
        soundService: SoundService(storage),
      );
      await service.initialize();
      await garden.save(
        const GardenState(
          pointsBalance: 1000,
          cherryBlossomTree: CherryBlossomTreeState(
            peaceBonsaiCount: 25,
            powerBonsaiCount: 25,
          ),
        ),
      );
      await service.removeAchievement('149');
      await service.addAchievement(
        const Achievement(
          id: '149',
          title: 'Path of Power',
          reward: 'Zen Garden Power bonsai +1',
          task: 'Complete the Power finale path on the Cherry Blossom Tree',
          isSecret: true,
          progress: 100,
        ),
      );
      await service.completeAchievement('149');
      final after = await garden.load();
      expect(after.decorInventory.single.kind, zenPowerBonsaiKind);
      expect(after.decorInventory.single.stageIndex, DecorItem.maxStageIndex);
      expect(after.cherryBlossomTree.powerBonsaiCount, 25);
    });
  });
}
