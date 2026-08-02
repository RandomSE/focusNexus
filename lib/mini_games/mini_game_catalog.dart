import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_engine.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';

/// Production mini-game catalog.
abstract final class MiniGameCatalog {
  static const List<MiniGameDefinition> production = <MiniGameDefinition>[
    MiniGameDefinition(
      id: FireflyJarConstants.gameId,
      title: FireflyJarConstants.title,
      description: FireflyJarConstants.description,
      unlockCost: FireflyJarConstants.unlockCost,
      playCost: FireflyJarConstants.playCost,
      endlessCost: FireflyJarConstants.endlessCost,
      defaultDurationSeconds: FireflyJarConstants.durationSeconds,
      baseDifficulty: FireflyJarConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/firefly_jar.png',
    ),
    MiniGameDefinition(
      id: StoneBalanceConstants.gameId,
      title: StoneBalanceConstants.title,
      description: StoneBalanceConstants.description,
      unlockCost: StoneBalanceConstants.unlockCost,
      playCost: StoneBalanceConstants.playCost,
      endlessCost: StoneBalanceConstants.endlessCost,
      defaultDurationSeconds: StoneBalanceConstants.durationSeconds,
      baseDifficulty: StoneBalanceConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/stone_balance.png',
    ),
    MiniGameDefinition(
      id: BreathPacerConstants.gameId,
      title: BreathPacerConstants.title,
      description: BreathPacerConstants.description,
      unlockCost: BreathPacerConstants.unlockCost,
      playCost: BreathPacerConstants.playCost,
      endlessCost: BreathPacerConstants.endlessCost,
      defaultDurationSeconds: BreathPacerConstants.durationSeconds,
      baseDifficulty: BreathPacerConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/breath_pacer.png',
    ),
    MiniGameDefinition(
      id: MeteorCatchConstants.gameId,
      title: MeteorCatchConstants.title,
      description: MeteorCatchConstants.description,
      unlockCost: MeteorCatchConstants.unlockCost,
      playCost: MeteorCatchConstants.playCost,
      endlessCost: MeteorCatchConstants.endlessCost,
      defaultDurationSeconds: MeteorCatchConstants.durationSeconds,
      baseDifficulty: MeteorCatchConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/meteor_catch.png',
    ),
    MiniGameDefinition(
      id: WordBloomConstants.gameId,
      title: WordBloomConstants.title,
      description: WordBloomConstants.description,
      unlockCost: WordBloomConstants.unlockCost,
      playCost: WordBloomConstants.playCost,
      endlessCost: WordBloomConstants.endlessCost,
      defaultDurationSeconds: WordBloomConstants.durationSeconds,
      baseDifficulty: WordBloomConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/word_bloom.png',
    ),
    MiniGameDefinition(
      id: RainCatcherConstants.gameId,
      title: RainCatcherConstants.title,
      description: RainCatcherConstants.description,
      unlockCost: RainCatcherConstants.unlockCost,
      playCost: RainCatcherConstants.playCost,
      endlessCost: RainCatcherConstants.endlessCost,
      defaultDurationSeconds: RainCatcherConstants.durationSeconds,
      baseDifficulty: RainCatcherConstants.baseDifficulty,
      implemented: true,
      hubImageAsset: 'assets/images/mini_games/rain_catcher.png',
    ),
  ];
}
