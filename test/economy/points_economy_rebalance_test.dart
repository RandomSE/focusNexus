import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/mini_game_achievement_rewards.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('wallet clamp', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '50'});
      repo = PointsRepository(storage);
    });

    test('floor clamps creditBalance below 0', () async {
      await repo.ensureInitialized();
      repo.creditBalance(-100);
      expect(await repo.readBalance(), 0);
    });

    test('ceiling clamps add and writeBalance', () async {
      await repo.ensureInitialized();
      await repo.writeBalance(PointsRepository.maxBalance);
      await repo.add(1);
      expect(await repo.readBalance(), PointsRepository.maxBalance);
      expect(
        await storage.read(key: StorageKeys.points),
        PointsRepository.maxBalance.toString(),
      );
    });

    test('debug 10M seed remains valid under ceiling', () async {
      await repo.writeBalance(10000000);
      expect(await repo.readBalance(), 10000000);
      expect(PointsRepository.maxBalance, greaterThanOrEqualTo(10000000));
    });

    test('trySpend result stays at floor 0 when spending exact balance',
        () async {
      await repo.writeBalance(40);
      final next = await repo.trySpend(40);
      expect(next, 0);
    });
  });

  group('mini-game reward math', () {
    test('x0.4 ceil table', () {
      expect(scaleMiniGameAchievementReward(100), 40);
      expect(scaleMiniGameAchievementReward(250), 100);
      expect(scaleMiniGameAchievementReward(500), 200);
      expect(scaleMiniGameAchievementReward(750), 300);
      expect(scaleMiniGameAchievementReward(1000), 400);
      expect(scaleMiniGameAchievementReward(1500), 600);
      expect(scaleMiniGameAchievementReward(2000), 800);
      expect(scaleMiniGameAchievementReward(2500), 1000);
      expect(scaleMiniGameAchievementReward(5000), 2000);
    });
  });

  group('cherry costs', () {
    test('FU-1 geometric 0-5; stage 6 and pathSwitch retained', () {
      expect(CherryBlossomStageCatalog.stageTotalFor(0), 500);
      expect(CherryBlossomStageCatalog.stageTotalFor(5), 512000);
      expect(CherryBlossomStageCatalog.stageTotalFor(6), 1000000);
      expect(CherryBlossomStageCatalog.grandTotalToMaxStage6(), 1682500);
      expect(CherryBlossomStageCatalog.pathSwitchCost, 100000);
      expect(
        CherryBlossomStageCatalog.costForGrow(
          stageIndex: 6,
          growthStepsInStage: 0,
        ),
        40000,
      );
    });
  });

  group('achievement economy catalog', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository points;
    late GardenRepository garden;
    late AchievementService service;

    setUp(() async {
      storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '1000',
        'soundEnabled': 'false',
      });
      points = PointsRepository(storage);
      garden = GardenRepository(storage, points: points);
      service = AchievementService(
        storage: storage,
        pointsRepository: points,
        gardenRepository: garden,
        soundService: SoundService(storage),
      );
      await service.initialize();
    });

    test('F3 Consistent Completionist rewards are monotonic', () {
      final rewards = [
        for (var id = 88; id <= 92; id++)
          int.parse(
            service.getById('$id')!.reward.replaceAll(RegExp(r'[^0-9]'), ''),
          ),
      ];
      expect(rewards, [100, 250, 500, 1000, 1000]);
      for (var i = 1; i < rewards.length; i++) {
        expect(rewards[i], greaterThanOrEqualTo(rewards[i - 1]));
      }
    });

    test('F2 Eternal Bloom task matches grand total; A2b reward 1000', () {
      final eternal = service.getById('113')!;
      expect(eternal.reward, '1000 points');
      expect(
        eternal.task,
        contains('${CherryBlossomStageCatalog.grandTotalToMaxStage6()}'),
      );
      expect(eternal.task.contains('1,000,000'), isFalse);
      expect(eternal.task.contains('2665500'), isFalse);
    });

    test('cherry stage clear rewards are zen stage bonsai (not points)', () {
      expect(
        [for (var id = 141; id <= 147; id++) service.getById('$id')!.reward],
        [
          for (var i = 0; i < zenCherryStageBonsaiNames.length; i++)
            zenStageBonsaiRewardText(i),
        ],
      );
      for (var id = 141; id <= 147; id++) {
        expect(service.getById('$id')!.reward.contains('points'), isFalse);
      }
    });

    test('F1 path claims are non-points; A1d grants zen decor bonsai', () async {
      expect(service.getById('148')!.reward.contains('points'), isFalse);
      expect(service.getById('149')!.reward.contains('points'), isFalse);
      expect(service.getById('148')!.reward, contains('Zen Garden'));
      expect(service.getById('149')!.reward, contains('Zen Garden'));

      await garden.save(
        const GardenState(
          pointsBalance: 1000,
          cherryBlossomTree: CherryBlossomTreeState(
            peaceBonsaiCount: 25,
            powerBonsaiCount: 25,
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

      final beforePoints = await points.readBalance();
      await service.completeAchievement('148');
      expect(await points.readBalance(), beforePoints);

      final after = await garden.load();
      // A1d: no bonsai-garden count bump (grandfather prior counts untouched).
      expect(after.cherryBlossomTree.peaceBonsaiCount, 25);
      expect(after.cherryBlossomTree.powerBonsaiCount, 25);
      expect(after.decorInventory.length, 1);
      expect(after.decorInventory.single.kind, zenPeaceBonsaiKind);
      expect(after.decorInventory.single.themeId, VisualThemeId.zenGarden);
      expect(after.decorInventory.single.stageIndex, DecorItem.maxStageIndex);
    });

    test('cherry stage claim grants stage bonsai without points', () async {
      await garden.save(const GardenState(pointsBalance: 800));
      await service.removeAchievement('141');
      await service.addAchievement(
        Achievement(
          id: '141',
          title: 'Cherry: Bare Beginning',
          reward: zenStageBonsaiRewardText(0),
          task: 'Clear Cherry Blossom Tree stage Bare Beginning',
          isSecret: false,
          progress: 100,
        ),
      );
      final before = await points.readBalance();
      await service.completeAchievement('141');
      expect(await points.readBalance(), before);
      final after = await garden.load();
      expect(after.decorInventory.single.kind, zenStageBonsaiKind(0));
    });

    test('F5 catalog size matches numOfAchievements constant', () {
      expect(service.all.length, AchievementService.numOfAchievements);
      expect(AchievementService.numOfAchievements, greaterThan(139));
    });

    test('mini-game firefly rewards use x0.4 ceil', () {
      expect(service.getById('118')!.reward, '40 points');
      expect(service.getById('122')!.reward, '400 points');
    });

    test('persisted stale rewards migrate on initialize', () async {
      final mem = InMemoryKeyValueStorage();
      final pts = PointsRepository(mem);
      final g = GardenRepository(mem, points: pts);
      final seed = AchievementService(
        storage: mem,
        pointsRepository: pts,
        gardenRepository: g,
        soundService: SoundService(mem),
      );
      await seed.initialize();
      await seed.removeAchievement('148');
      await seed.addAchievement(
        const Achievement(
          id: '148',
          title: 'Path of Peace',
          reward: '500000 points',
          task: 'Complete the Peace finale path on the Cherry Blossom Tree',
          isSecret: true,
        ),
      );
      await seed.removeAchievement('141');
      await seed.addAchievement(
        const Achievement(
          id: '141',
          title: 'Cherry: Bare Beginning',
          reward: '50 points',
          task: 'Clear Cherry Blossom Tree stage Bare Beginning',
          isSecret: false,
        ),
      );
      await seed.removeAchievement('118');
      await seed.addAchievement(
        const Achievement(
          id: '118',
          title: 'Firefly Swarm I',
          reward: '100 points',
          task: 'Catch 100 fireflies in one Duration round of Firefly Jar',
          isSecret: false,
        ),
      );

      final migrated = AchievementService(
        storage: mem,
        pointsRepository: pts,
        gardenRepository: g,
        soundService: SoundService(mem),
      );
      await migrated.initialize();
      expect(migrated.getById('148')!.reward.contains('points'), isFalse);
      expect(migrated.getById('141')!.reward, zenStageBonsaiRewardText(0));
      expect(migrated.getById('118')!.reward, '40 points');
    });
  });
}
