// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GoalSet {
  String get title => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get complexity => throw _privateConstructorUsedError;
  String get effort => throw _privateConstructorUsedError;
  String get motivation => throw _privateConstructorUsedError;
  int get time => throw _privateConstructorUsedError;
  @JsonKey(name: 'Deadline')
  String get deadline => throw _privateConstructorUsedError;
  @JsonKey(name: 'CompletedAt')
  String get completedAt => throw _privateConstructorUsedError;
  int get steps => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get stepProgress => throw _privateConstructorUsedError;
  @JsonKey(name: 'Id')
  int get goalId => throw _privateConstructorUsedError;
  String get goalKind => throw _privateConstructorUsedError;
  @JsonKey(name: 'ActionWindowStart')
  String get actionWindowStart => throw _privateConstructorUsedError;
  @JsonKey(name: 'ActionWindowEnd')
  String get actionWindowEnd => throw _privateConstructorUsedError;
  int get repeatSeriesId => throw _privateConstructorUsedError;

  /// Serializes this GoalSet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalSetCopyWith<GoalSet> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalSetCopyWith<$Res> {
  factory $GoalSetCopyWith(GoalSet value, $Res Function(GoalSet) then) =
      _$GoalSetCopyWithImpl<$Res, GoalSet>;
  @useResult
  $Res call({
    String title,
    String category,
    String complexity,
    String effort,
    String motivation,
    int time,
    @JsonKey(name: 'Deadline') String deadline,
    @JsonKey(name: 'CompletedAt') String completedAt,
    int steps,
    int points,
    int stepProgress,
    @JsonKey(name: 'Id') int goalId,
    String goalKind,
    @JsonKey(name: 'ActionWindowStart') String actionWindowStart,
    @JsonKey(name: 'ActionWindowEnd') String actionWindowEnd,
    int repeatSeriesId,
  });
}

/// @nodoc
class _$GoalSetCopyWithImpl<$Res, $Val extends GoalSet>
    implements $GoalSetCopyWith<$Res> {
  _$GoalSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? category = null,
    Object? complexity = null,
    Object? effort = null,
    Object? motivation = null,
    Object? time = null,
    Object? deadline = null,
    Object? completedAt = null,
    Object? steps = null,
    Object? points = null,
    Object? stepProgress = null,
    Object? goalId = null,
    Object? goalKind = null,
    Object? actionWindowStart = null,
    Object? actionWindowEnd = null,
    Object? repeatSeriesId = null,
  }) {
    return _then(
      _value.copyWith(
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            category:
                null == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String,
            complexity:
                null == complexity
                    ? _value.complexity
                    : complexity // ignore: cast_nullable_to_non_nullable
                        as String,
            effort:
                null == effort
                    ? _value.effort
                    : effort // ignore: cast_nullable_to_non_nullable
                        as String,
            motivation:
                null == motivation
                    ? _value.motivation
                    : motivation // ignore: cast_nullable_to_non_nullable
                        as String,
            time:
                null == time
                    ? _value.time
                    : time // ignore: cast_nullable_to_non_nullable
                        as int,
            deadline:
                null == deadline
                    ? _value.deadline
                    : deadline // ignore: cast_nullable_to_non_nullable
                        as String,
            completedAt:
                null == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as String,
            steps:
                null == steps
                    ? _value.steps
                    : steps // ignore: cast_nullable_to_non_nullable
                        as int,
            points:
                null == points
                    ? _value.points
                    : points // ignore: cast_nullable_to_non_nullable
                        as int,
            stepProgress:
                null == stepProgress
                    ? _value.stepProgress
                    : stepProgress // ignore: cast_nullable_to_non_nullable
                        as int,
            goalId:
                null == goalId
                    ? _value.goalId
                    : goalId // ignore: cast_nullable_to_non_nullable
                        as int,
            goalKind:
                null == goalKind
                    ? _value.goalKind
                    : goalKind // ignore: cast_nullable_to_non_nullable
                        as String,
            actionWindowStart:
                null == actionWindowStart
                    ? _value.actionWindowStart
                    : actionWindowStart // ignore: cast_nullable_to_non_nullable
                        as String,
            actionWindowEnd:
                null == actionWindowEnd
                    ? _value.actionWindowEnd
                    : actionWindowEnd // ignore: cast_nullable_to_non_nullable
                        as String,
            repeatSeriesId:
                null == repeatSeriesId
                    ? _value.repeatSeriesId
                    : repeatSeriesId // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GoalSetImplCopyWith<$Res> implements $GoalSetCopyWith<$Res> {
  factory _$$GoalSetImplCopyWith(
    _$GoalSetImpl value,
    $Res Function(_$GoalSetImpl) then,
  ) = __$$GoalSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String category,
    String complexity,
    String effort,
    String motivation,
    int time,
    @JsonKey(name: 'Deadline') String deadline,
    @JsonKey(name: 'CompletedAt') String completedAt,
    int steps,
    int points,
    int stepProgress,
    @JsonKey(name: 'Id') int goalId,
    String goalKind,
    @JsonKey(name: 'ActionWindowStart') String actionWindowStart,
    @JsonKey(name: 'ActionWindowEnd') String actionWindowEnd,
    int repeatSeriesId,
  });
}

/// @nodoc
class __$$GoalSetImplCopyWithImpl<$Res>
    extends _$GoalSetCopyWithImpl<$Res, _$GoalSetImpl>
    implements _$$GoalSetImplCopyWith<$Res> {
  __$$GoalSetImplCopyWithImpl(
    _$GoalSetImpl _value,
    $Res Function(_$GoalSetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GoalSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? category = null,
    Object? complexity = null,
    Object? effort = null,
    Object? motivation = null,
    Object? time = null,
    Object? deadline = null,
    Object? completedAt = null,
    Object? steps = null,
    Object? points = null,
    Object? stepProgress = null,
    Object? goalId = null,
    Object? goalKind = null,
    Object? actionWindowStart = null,
    Object? actionWindowEnd = null,
    Object? repeatSeriesId = null,
  }) {
    return _then(
      _$GoalSetImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        category:
            null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String,
        complexity:
            null == complexity
                ? _value.complexity
                : complexity // ignore: cast_nullable_to_non_nullable
                    as String,
        effort:
            null == effort
                ? _value.effort
                : effort // ignore: cast_nullable_to_non_nullable
                    as String,
        motivation:
            null == motivation
                ? _value.motivation
                : motivation // ignore: cast_nullable_to_non_nullable
                    as String,
        time:
            null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                    as int,
        deadline:
            null == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                    as String,
        completedAt:
            null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as String,
        steps:
            null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                    as int,
        points:
            null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                    as int,
        stepProgress:
            null == stepProgress
                ? _value.stepProgress
                : stepProgress // ignore: cast_nullable_to_non_nullable
                    as int,
        goalId:
            null == goalId
                ? _value.goalId
                : goalId // ignore: cast_nullable_to_non_nullable
                    as int,
        goalKind:
            null == goalKind
                ? _value.goalKind
                : goalKind // ignore: cast_nullable_to_non_nullable
                    as String,
        actionWindowStart:
            null == actionWindowStart
                ? _value.actionWindowStart
                : actionWindowStart // ignore: cast_nullable_to_non_nullable
                    as String,
        actionWindowEnd:
            null == actionWindowEnd
                ? _value.actionWindowEnd
                : actionWindowEnd // ignore: cast_nullable_to_non_nullable
                    as String,
        repeatSeriesId:
            null == repeatSeriesId
                ? _value.repeatSeriesId
                : repeatSeriesId // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable(createFactory: false)
class _$GoalSetImpl extends _GoalSet {
  const _$GoalSetImpl({
    this.title = '',
    this.category = '',
    this.complexity = '',
    this.effort = '',
    this.motivation = '',
    this.time = 0,
    @JsonKey(name: 'Deadline') this.deadline = '',
    @JsonKey(name: 'CompletedAt') this.completedAt = '',
    this.steps = 0,
    this.points = 0,
    this.stepProgress = 0,
    @JsonKey(name: 'Id') this.goalId = 0,
    this.goalKind = GoalKind.deadline,
    @JsonKey(name: 'ActionWindowStart') this.actionWindowStart = '',
    @JsonKey(name: 'ActionWindowEnd') this.actionWindowEnd = '',
    this.repeatSeriesId = 0,
  }) : super._();

  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final String complexity;
  @override
  @JsonKey()
  final String effort;
  @override
  @JsonKey()
  final String motivation;
  @override
  @JsonKey()
  final int time;
  @override
  @JsonKey(name: 'Deadline')
  final String deadline;
  @override
  @JsonKey(name: 'CompletedAt')
  final String completedAt;
  @override
  @JsonKey()
  final int steps;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int stepProgress;
  @override
  @JsonKey(name: 'Id')
  final int goalId;
  @override
  @JsonKey()
  final String goalKind;
  @override
  @JsonKey(name: 'ActionWindowStart')
  final String actionWindowStart;
  @override
  @JsonKey(name: 'ActionWindowEnd')
  final String actionWindowEnd;
  @override
  @JsonKey()
  final int repeatSeriesId;

  @override
  String toString() {
    return 'GoalSet(title: $title, category: $category, complexity: $complexity, effort: $effort, motivation: $motivation, time: $time, deadline: $deadline, completedAt: $completedAt, steps: $steps, points: $points, stepProgress: $stepProgress, goalId: $goalId, goalKind: $goalKind, actionWindowStart: $actionWindowStart, actionWindowEnd: $actionWindowEnd, repeatSeriesId: $repeatSeriesId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalSetImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.complexity, complexity) ||
                other.complexity == complexity) &&
            (identical(other.effort, effort) || other.effort == effort) &&
            (identical(other.motivation, motivation) ||
                other.motivation == motivation) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.steps, steps) || other.steps == steps) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.stepProgress, stepProgress) ||
                other.stepProgress == stepProgress) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.goalKind, goalKind) ||
                other.goalKind == goalKind) &&
            (identical(other.actionWindowStart, actionWindowStart) ||
                other.actionWindowStart == actionWindowStart) &&
            (identical(other.actionWindowEnd, actionWindowEnd) ||
                other.actionWindowEnd == actionWindowEnd) &&
            (identical(other.repeatSeriesId, repeatSeriesId) ||
                other.repeatSeriesId == repeatSeriesId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    category,
    complexity,
    effort,
    motivation,
    time,
    deadline,
    completedAt,
    steps,
    points,
    stepProgress,
    goalId,
    goalKind,
    actionWindowStart,
    actionWindowEnd,
    repeatSeriesId,
  );

  /// Create a copy of GoalSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalSetImplCopyWith<_$GoalSetImpl> get copyWith =>
      __$$GoalSetImplCopyWithImpl<_$GoalSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalSetImplToJson(this);
  }
}

abstract class _GoalSet extends GoalSet {
  const factory _GoalSet({
    final String title,
    final String category,
    final String complexity,
    final String effort,
    final String motivation,
    final int time,
    @JsonKey(name: 'Deadline') final String deadline,
    @JsonKey(name: 'CompletedAt') final String completedAt,
    final int steps,
    final int points,
    final int stepProgress,
    @JsonKey(name: 'Id') final int goalId,
    final String goalKind,
    @JsonKey(name: 'ActionWindowStart') final String actionWindowStart,
    @JsonKey(name: 'ActionWindowEnd') final String actionWindowEnd,
    final int repeatSeriesId,
  }) = _$GoalSetImpl;
  const _GoalSet._() : super._();

  @override
  String get title;
  @override
  String get category;
  @override
  String get complexity;
  @override
  String get effort;
  @override
  String get motivation;
  @override
  int get time;
  @override
  @JsonKey(name: 'Deadline')
  String get deadline;
  @override
  @JsonKey(name: 'CompletedAt')
  String get completedAt;
  @override
  int get steps;
  @override
  int get points;
  @override
  int get stepProgress;
  @override
  @JsonKey(name: 'Id')
  int get goalId;
  @override
  String get goalKind;
  @override
  @JsonKey(name: 'ActionWindowStart')
  String get actionWindowStart;
  @override
  @JsonKey(name: 'ActionWindowEnd')
  String get actionWindowEnd;
  @override
  int get repeatSeriesId;

  /// Create a copy of GoalSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalSetImplCopyWith<_$GoalSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
