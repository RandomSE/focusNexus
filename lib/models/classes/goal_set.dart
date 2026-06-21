import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:focusNexus/goals/goal_kind.dart';

part 'goal_set.freezed.dart';
part 'goal_set.g.dart';

/// Typed view of a goal map for notifier filtering and achievement stats.
///
/// Storage maps use legacy keys `Deadline` and `Id`; [fromMap] tolerates string
/// numeric fields. Prefer [fromMap]/[toMap] for repository roundtrips.
@Freezed(fromJson: false, toJson: true)
class GoalSet with _$GoalSet {
  const GoalSet._();

  const factory GoalSet({
    @Default('') String title,
    @Default('') String category,
    @Default('') String complexity,
    @Default('') String effort,
    @Default('') String motivation,
    @Default(0) int time,
    @JsonKey(name: 'Deadline') @Default('') String deadline,
    @JsonKey(name: 'CompletedAt') @Default('') String completedAt,
    @Default(0) int steps,
    @Default(0) int points,
    @Default(0) int stepProgress,
    @JsonKey(name: 'Id') @Default(0) int goalId,
    @Default(GoalKind.deadline) String goalKind,
    @JsonKey(name: 'ActionWindowStart') @Default('') String actionWindowStart,
    @JsonKey(name: 'ActionWindowEnd') @Default('') String actionWindowEnd,
    @Default(0) int repeatSeriesId,
  }) = _GoalSet;

  /// Parses loosely typed goal maps from secure storage.
  factory GoalSet.fromMap(Map<String, dynamic> map) {
    final rawKind = map['goalKind']?.toString() ?? '';
    return GoalSet(
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      complexity: map['complexity']?.toString() ?? '',
      effort: map['effort']?.toString() ?? '',
      motivation: map['motivation']?.toString() ?? '',
      time: int.tryParse(map['time']?.toString() ?? '0') ?? 0,
      deadline: map['Deadline']?.toString() ?? '',
      completedAt: map['CompletedAt']?.toString() ?? '',
      steps: int.tryParse(map['steps']?.toString() ?? '0') ?? 0,
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      stepProgress: int.tryParse(map['stepProgress']?.toString() ?? '0') ?? 0,
      goalId: int.tryParse(map['Id']?.toString() ?? '0') ?? 0,
      goalKind: rawKind.isEmpty ? GoalKind.deadline : rawKind,
      actionWindowStart: map['ActionWindowStart']?.toString() ?? '',
      actionWindowEnd: map['ActionWindowEnd']?.toString() ?? '',
      repeatSeriesId:
          int.tryParse(map['repeatSeriesId']?.toString() ?? '0') ?? 0,
    );
  }

  factory GoalSet.fromJson(Map<String, dynamic> json) => GoalSet.fromMap(json);

  void validate() {
    assert(title.isNotEmpty, 'title must not be empty');
    assert(goalId > 0, 'goalId must be positive');
    assert(steps >= 0 && stepProgress >= 0, 'steps must be non-negative');
  }
}

extension GoalSetMap on GoalSet {
  Map<String, dynamic> toMap() => toJson();
}
