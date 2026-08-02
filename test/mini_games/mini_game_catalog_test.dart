import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_engine.dart';
import 'package:focusNexus/mini_games/mini_game_catalog.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';

void main() {
  test('production catalog pricing and free unlocks match the economy table', () {
    expect(MiniGameCatalog.production, hasLength(6));

    final firefly = MiniGameCatalog.production[0];
    expect(firefly.id, FireflyJarConstants.gameId);
    expect(firefly.isFreeUnlock, isTrue);
    expect(firefly.playCost, 60);
    expect(firefly.endlessCost, 100);
    expect(firefly.startCost(endless: false), 60);
    expect(firefly.startCost(endless: true), 160);
    expect(firefly.hubImageAsset, isNotNull);

    final stones = MiniGameCatalog.production[1];
    expect(stones.id, StoneBalanceConstants.gameId);
    expect(stones.isFreeUnlock, isFalse);
    expect(stones.unlockCost, 300);
    expect(stones.playCost, 100);
    expect(stones.endlessCost, 150);
    expect(stones.startCost(endless: true), 250);

    final breath = MiniGameCatalog.production[2];
    expect(breath.id, BreathPacerConstants.gameId);
    expect(breath.isFreeUnlock, isTrue);
    expect(breath.playCost, 60);
    expect(breath.endlessCost, 90);
    expect(breath.startCost(endless: false), 60);
    expect(breath.startCost(endless: true), 150);

    final meteor = MiniGameCatalog.production[3];
    expect(meteor.id, MeteorCatchConstants.gameId);
    expect(meteor.unlockCost, 250);
    expect(meteor.playCost, 90);
    expect(meteor.endlessCost, 130);
    expect(meteor.startCost(endless: true), 220);

    final bloom = MiniGameCatalog.production[4];
    expect(bloom.id, WordBloomConstants.gameId);
    expect(bloom.unlockCost, 200);
    expect(bloom.playCost, 80);
    expect(bloom.endlessCost, 120);
    expect(bloom.startCost(endless: true), 200);

    final rain = MiniGameCatalog.production[5];
    expect(rain.id, RainCatcherConstants.gameId);
    expect(rain.unlockCost, 150);
    expect(rain.playCost, 70);
    expect(rain.endlessCost, 110);
    expect(rain.defaultDurationSeconds, 90);
    expect(rain.startCost(endless: false), 70);
    expect(rain.startCost(endless: true), 180);
  });
}
