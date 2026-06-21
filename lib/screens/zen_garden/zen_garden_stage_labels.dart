import 'package:focusNexus/progressive_visuals/growth_stage.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';

String zenGardenStageLabel(int index) {
  final stage = growthStageFromIndex(index);
  return switch (stage) {
    GrowthStage.seed => 'seed',
    GrowthStage.sprout => 'sprout',
    GrowthStage.vegetative => 'full foliage',
    GrowthStage.bloom => 'bloom',
    GrowthStage.mature => 'mature tree',
  };
}

Duration zenWaitAfterAdvancingFrom(int fromStage) {
  final rules = zenGardenTransitionRules();
  if (fromStage < 0) {
    return rules.first.waitBeforeNextAdvance ?? const Duration(minutes: 2);
  }
  final r = rules.firstWhere((x) => x.fromStageIndex == fromStage);
  return r.waitBeforeNextAdvance ?? const Duration(minutes: 2);
}
