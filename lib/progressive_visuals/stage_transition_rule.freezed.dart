// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage_transition_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StageTransitionRule {
  int get fromStageIndex => throw _privateConstructorUsedError;
  int get pointCost => throw _privateConstructorUsedError;
  Duration? get waitBeforeNextAdvance => throw _privateConstructorUsedError;
  int? get skipWaitPointCost => throw _privateConstructorUsedError;

  /// Create a copy of StageTransitionRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageTransitionRuleCopyWith<StageTransitionRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageTransitionRuleCopyWith<$Res> {
  factory $StageTransitionRuleCopyWith(
    StageTransitionRule value,
    $Res Function(StageTransitionRule) then,
  ) = _$StageTransitionRuleCopyWithImpl<$Res, StageTransitionRule>;
  @useResult
  $Res call({
    int fromStageIndex,
    int pointCost,
    Duration? waitBeforeNextAdvance,
    int? skipWaitPointCost,
  });
}

/// @nodoc
class _$StageTransitionRuleCopyWithImpl<$Res, $Val extends StageTransitionRule>
    implements $StageTransitionRuleCopyWith<$Res> {
  _$StageTransitionRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageTransitionRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromStageIndex = null,
    Object? pointCost = null,
    Object? waitBeforeNextAdvance = freezed,
    Object? skipWaitPointCost = freezed,
  }) {
    return _then(
      _value.copyWith(
            fromStageIndex:
                null == fromStageIndex
                    ? _value.fromStageIndex
                    : fromStageIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            pointCost:
                null == pointCost
                    ? _value.pointCost
                    : pointCost // ignore: cast_nullable_to_non_nullable
                        as int,
            waitBeforeNextAdvance:
                freezed == waitBeforeNextAdvance
                    ? _value.waitBeforeNextAdvance
                    : waitBeforeNextAdvance // ignore: cast_nullable_to_non_nullable
                        as Duration?,
            skipWaitPointCost:
                freezed == skipWaitPointCost
                    ? _value.skipWaitPointCost
                    : skipWaitPointCost // ignore: cast_nullable_to_non_nullable
                        as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StageTransitionRuleImplCopyWith<$Res>
    implements $StageTransitionRuleCopyWith<$Res> {
  factory _$$StageTransitionRuleImplCopyWith(
    _$StageTransitionRuleImpl value,
    $Res Function(_$StageTransitionRuleImpl) then,
  ) = __$$StageTransitionRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int fromStageIndex,
    int pointCost,
    Duration? waitBeforeNextAdvance,
    int? skipWaitPointCost,
  });
}

/// @nodoc
class __$$StageTransitionRuleImplCopyWithImpl<$Res>
    extends _$StageTransitionRuleCopyWithImpl<$Res, _$StageTransitionRuleImpl>
    implements _$$StageTransitionRuleImplCopyWith<$Res> {
  __$$StageTransitionRuleImplCopyWithImpl(
    _$StageTransitionRuleImpl _value,
    $Res Function(_$StageTransitionRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StageTransitionRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromStageIndex = null,
    Object? pointCost = null,
    Object? waitBeforeNextAdvance = freezed,
    Object? skipWaitPointCost = freezed,
  }) {
    return _then(
      _$StageTransitionRuleImpl(
        fromStageIndex:
            null == fromStageIndex
                ? _value.fromStageIndex
                : fromStageIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        pointCost:
            null == pointCost
                ? _value.pointCost
                : pointCost // ignore: cast_nullable_to_non_nullable
                    as int,
        waitBeforeNextAdvance:
            freezed == waitBeforeNextAdvance
                ? _value.waitBeforeNextAdvance
                : waitBeforeNextAdvance // ignore: cast_nullable_to_non_nullable
                    as Duration?,
        skipWaitPointCost:
            freezed == skipWaitPointCost
                ? _value.skipWaitPointCost
                : skipWaitPointCost // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc

class _$StageTransitionRuleImpl extends _StageTransitionRule {
  const _$StageTransitionRuleImpl({
    required this.fromStageIndex,
    required this.pointCost,
    this.waitBeforeNextAdvance,
    this.skipWaitPointCost,
  }) : super._();

  @override
  final int fromStageIndex;
  @override
  final int pointCost;
  @override
  final Duration? waitBeforeNextAdvance;
  @override
  final int? skipWaitPointCost;

  @override
  String toString() {
    return 'StageTransitionRule(fromStageIndex: $fromStageIndex, pointCost: $pointCost, waitBeforeNextAdvance: $waitBeforeNextAdvance, skipWaitPointCost: $skipWaitPointCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageTransitionRuleImpl &&
            (identical(other.fromStageIndex, fromStageIndex) ||
                other.fromStageIndex == fromStageIndex) &&
            (identical(other.pointCost, pointCost) ||
                other.pointCost == pointCost) &&
            (identical(other.waitBeforeNextAdvance, waitBeforeNextAdvance) ||
                other.waitBeforeNextAdvance == waitBeforeNextAdvance) &&
            (identical(other.skipWaitPointCost, skipWaitPointCost) ||
                other.skipWaitPointCost == skipWaitPointCost));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    fromStageIndex,
    pointCost,
    waitBeforeNextAdvance,
    skipWaitPointCost,
  );

  /// Create a copy of StageTransitionRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageTransitionRuleImplCopyWith<_$StageTransitionRuleImpl> get copyWith =>
      __$$StageTransitionRuleImplCopyWithImpl<_$StageTransitionRuleImpl>(
        this,
        _$identity,
      );
}

abstract class _StageTransitionRule extends StageTransitionRule {
  const factory _StageTransitionRule({
    required final int fromStageIndex,
    required final int pointCost,
    final Duration? waitBeforeNextAdvance,
    final int? skipWaitPointCost,
  }) = _$StageTransitionRuleImpl;
  const _StageTransitionRule._() : super._();

  @override
  int get fromStageIndex;
  @override
  int get pointCost;
  @override
  Duration? get waitBeforeNextAdvance;
  @override
  int? get skipWaitPointCost;

  /// Create a copy of StageTransitionRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageTransitionRuleImplCopyWith<_$StageTransitionRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
