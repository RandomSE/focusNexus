import 'stage_transition_rule.dart';

/// Zen garden: 5× point/skip costs vs original design; every advance can gate the next with a wait.
List<StageTransitionRule> zenGardenTransitionRules() {
  return const [
    StageTransitionRule(
      fromStageIndex: 0,
      pointCost: 50,
      waitBeforeNextAdvance: Duration(minutes: 2),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 1,
      pointCost: 0,
      waitBeforeNextAdvance: Duration(minutes: 5),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 2,
      pointCost: 40,
      waitBeforeNextAdvance: Duration(minutes: 30),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 3,
      pointCost: 60,
      waitBeforeNextAdvance: Duration(hours: 3),
      skipWaitPointCost: 75,
    ),
  ];
}
