/// Rules for advancing from [fromStage] to the next stage.
///
/// After the user pays [pointCost] and any active wait is cleared, they enter
/// [fromStage] + 1. If [waitBeforeNextAdvance] is non-null, a lock starts
/// *after* this transition completes, blocking further advances until elapsed
/// or [skipWaitPointCost] is paid.
class StageTransitionRule {
  const StageTransitionRule({
    required this.fromStageIndex,
    required this.pointCost,
    this.waitBeforeNextAdvance,
    this.skipWaitPointCost,
  })  : assert(fromStageIndex >= 0),
        assert(pointCost >= 0),
        assert(skipWaitPointCost == null || skipWaitPointCost >= 0);

  final int fromStageIndex;
  final int pointCost;

  /// When advancing *from* [fromStageIndex] to the next stage, the user may
  /// need to wait this long before the *next* advance is allowed.
  final Duration? waitBeforeNextAdvance;

  /// Cost to clear [waitBeforeNextAdvance] early.
  final int? skipWaitPointCost;
}
