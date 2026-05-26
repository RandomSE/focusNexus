import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage_transition_rule.freezed.dart';

/// Rules for advancing from [fromStageIndex] to the next stage.
@freezed
class StageTransitionRule with _$StageTransitionRule {
  const StageTransitionRule._();

  const factory StageTransitionRule({
    required int fromStageIndex,
    required int pointCost,
    Duration? waitBeforeNextAdvance,
    int? skipWaitPointCost,
  }) = _StageTransitionRule;

  void validate() {
    assert(fromStageIndex >= 0, 'fromStageIndex must be non-negative');
    assert(pointCost >= 0, 'pointCost must be non-negative');
    assert(
      skipWaitPointCost == null || skipWaitPointCost! >= 0,
      'skipWaitPointCost must be non-negative',
    );
  }
}
