// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'decor_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DecorItem _$DecorItemFromJson(Map<String, dynamic> json) {
  return _DecorItem.fromJson(json);
}

/// @nodoc
mixin _$DecorItem {
  String get id => throw _privateConstructorUsedError;
  @VisualThemeIdJsonConverter()
  VisualThemeId get themeId => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  double get positionX => throw _privateConstructorUsedError;
  double get positionY => throw _privateConstructorUsedError;
  int get stageIndex => throw _privateConstructorUsedError;
  DateTime? get nextAdvanceAllowedAt => throw _privateConstructorUsedError;
  int? get pendingSkipWaitCost => throw _privateConstructorUsedError;
  @MutationKindJsonConverter()
  MutationKind? get mutation => throw _privateConstructorUsedError;
  bool get awaitingRegrowthForRemutation => throw _privateConstructorUsedError;
  bool get mutationRolledThisCycle => throw _privateConstructorUsedError;

  /// Serializes this DecorItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DecorItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DecorItemCopyWith<DecorItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DecorItemCopyWith<$Res> {
  factory $DecorItemCopyWith(DecorItem value, $Res Function(DecorItem) then) =
      _$DecorItemCopyWithImpl<$Res, DecorItem>;
  @useResult
  $Res call({
    String id,
    @VisualThemeIdJsonConverter() VisualThemeId themeId,
    String kind,
    double positionX,
    double positionY,
    int stageIndex,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    bool awaitingRegrowthForRemutation,
    bool mutationRolledThisCycle,
  });
}

/// @nodoc
class _$DecorItemCopyWithImpl<$Res, $Val extends DecorItem>
    implements $DecorItemCopyWith<$Res> {
  _$DecorItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DecorItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? themeId = null,
    Object? kind = null,
    Object? positionX = null,
    Object? positionY = null,
    Object? stageIndex = null,
    Object? nextAdvanceAllowedAt = freezed,
    Object? pendingSkipWaitCost = freezed,
    Object? mutation = freezed,
    Object? awaitingRegrowthForRemutation = null,
    Object? mutationRolledThisCycle = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            themeId:
                null == themeId
                    ? _value.themeId
                    : themeId // ignore: cast_nullable_to_non_nullable
                        as VisualThemeId,
            kind:
                null == kind
                    ? _value.kind
                    : kind // ignore: cast_nullable_to_non_nullable
                        as String,
            positionX:
                null == positionX
                    ? _value.positionX
                    : positionX // ignore: cast_nullable_to_non_nullable
                        as double,
            positionY:
                null == positionY
                    ? _value.positionY
                    : positionY // ignore: cast_nullable_to_non_nullable
                        as double,
            stageIndex:
                null == stageIndex
                    ? _value.stageIndex
                    : stageIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            nextAdvanceAllowedAt:
                freezed == nextAdvanceAllowedAt
                    ? _value.nextAdvanceAllowedAt
                    : nextAdvanceAllowedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            pendingSkipWaitCost:
                freezed == pendingSkipWaitCost
                    ? _value.pendingSkipWaitCost
                    : pendingSkipWaitCost // ignore: cast_nullable_to_non_nullable
                        as int?,
            mutation:
                freezed == mutation
                    ? _value.mutation
                    : mutation // ignore: cast_nullable_to_non_nullable
                        as MutationKind?,
            awaitingRegrowthForRemutation:
                null == awaitingRegrowthForRemutation
                    ? _value.awaitingRegrowthForRemutation
                    : awaitingRegrowthForRemutation // ignore: cast_nullable_to_non_nullable
                        as bool,
            mutationRolledThisCycle:
                null == mutationRolledThisCycle
                    ? _value.mutationRolledThisCycle
                    : mutationRolledThisCycle // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DecorItemImplCopyWith<$Res>
    implements $DecorItemCopyWith<$Res> {
  factory _$$DecorItemImplCopyWith(
    _$DecorItemImpl value,
    $Res Function(_$DecorItemImpl) then,
  ) = __$$DecorItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @VisualThemeIdJsonConverter() VisualThemeId themeId,
    String kind,
    double positionX,
    double positionY,
    int stageIndex,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    bool awaitingRegrowthForRemutation,
    bool mutationRolledThisCycle,
  });
}

/// @nodoc
class __$$DecorItemImplCopyWithImpl<$Res>
    extends _$DecorItemCopyWithImpl<$Res, _$DecorItemImpl>
    implements _$$DecorItemImplCopyWith<$Res> {
  __$$DecorItemImplCopyWithImpl(
    _$DecorItemImpl _value,
    $Res Function(_$DecorItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DecorItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? themeId = null,
    Object? kind = null,
    Object? positionX = null,
    Object? positionY = null,
    Object? stageIndex = null,
    Object? nextAdvanceAllowedAt = freezed,
    Object? pendingSkipWaitCost = freezed,
    Object? mutation = freezed,
    Object? awaitingRegrowthForRemutation = null,
    Object? mutationRolledThisCycle = null,
  }) {
    return _then(
      _$DecorItemImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        themeId:
            null == themeId
                ? _value.themeId
                : themeId // ignore: cast_nullable_to_non_nullable
                    as VisualThemeId,
        kind:
            null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                    as String,
        positionX:
            null == positionX
                ? _value.positionX
                : positionX // ignore: cast_nullable_to_non_nullable
                    as double,
        positionY:
            null == positionY
                ? _value.positionY
                : positionY // ignore: cast_nullable_to_non_nullable
                    as double,
        stageIndex:
            null == stageIndex
                ? _value.stageIndex
                : stageIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        nextAdvanceAllowedAt:
            freezed == nextAdvanceAllowedAt
                ? _value.nextAdvanceAllowedAt
                : nextAdvanceAllowedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        pendingSkipWaitCost:
            freezed == pendingSkipWaitCost
                ? _value.pendingSkipWaitCost
                : pendingSkipWaitCost // ignore: cast_nullable_to_non_nullable
                    as int?,
        mutation:
            freezed == mutation
                ? _value.mutation
                : mutation // ignore: cast_nullable_to_non_nullable
                    as MutationKind?,
        awaitingRegrowthForRemutation:
            null == awaitingRegrowthForRemutation
                ? _value.awaitingRegrowthForRemutation
                : awaitingRegrowthForRemutation // ignore: cast_nullable_to_non_nullable
                    as bool,
        mutationRolledThisCycle:
            null == mutationRolledThisCycle
                ? _value.mutationRolledThisCycle
                : mutationRolledThisCycle // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DecorItemImpl extends _DecorItem {
  const _$DecorItemImpl({
    required this.id,
    @VisualThemeIdJsonConverter() required this.themeId,
    required this.kind,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.stageIndex = 0,
    this.nextAdvanceAllowedAt,
    this.pendingSkipWaitCost,
    @MutationKindJsonConverter() this.mutation,
    this.awaitingRegrowthForRemutation = false,
    this.mutationRolledThisCycle = false,
  }) : super._();

  factory _$DecorItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$DecorItemImplFromJson(json);

  @override
  final String id;
  @override
  @VisualThemeIdJsonConverter()
  final VisualThemeId themeId;
  @override
  final String kind;
  @override
  @JsonKey()
  final double positionX;
  @override
  @JsonKey()
  final double positionY;
  @override
  @JsonKey()
  final int stageIndex;
  @override
  final DateTime? nextAdvanceAllowedAt;
  @override
  final int? pendingSkipWaitCost;
  @override
  @MutationKindJsonConverter()
  final MutationKind? mutation;
  @override
  @JsonKey()
  final bool awaitingRegrowthForRemutation;
  @override
  @JsonKey()
  final bool mutationRolledThisCycle;

  @override
  String toString() {
    return 'DecorItem(id: $id, themeId: $themeId, kind: $kind, positionX: $positionX, positionY: $positionY, stageIndex: $stageIndex, nextAdvanceAllowedAt: $nextAdvanceAllowedAt, pendingSkipWaitCost: $pendingSkipWaitCost, mutation: $mutation, awaitingRegrowthForRemutation: $awaitingRegrowthForRemutation, mutationRolledThisCycle: $mutationRolledThisCycle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DecorItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.positionX, positionX) ||
                other.positionX == positionX) &&
            (identical(other.positionY, positionY) ||
                other.positionY == positionY) &&
            (identical(other.stageIndex, stageIndex) ||
                other.stageIndex == stageIndex) &&
            (identical(other.nextAdvanceAllowedAt, nextAdvanceAllowedAt) ||
                other.nextAdvanceAllowedAt == nextAdvanceAllowedAt) &&
            (identical(other.pendingSkipWaitCost, pendingSkipWaitCost) ||
                other.pendingSkipWaitCost == pendingSkipWaitCost) &&
            (identical(other.mutation, mutation) ||
                other.mutation == mutation) &&
            (identical(
                  other.awaitingRegrowthForRemutation,
                  awaitingRegrowthForRemutation,
                ) ||
                other.awaitingRegrowthForRemutation ==
                    awaitingRegrowthForRemutation) &&
            (identical(
                  other.mutationRolledThisCycle,
                  mutationRolledThisCycle,
                ) ||
                other.mutationRolledThisCycle == mutationRolledThisCycle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    themeId,
    kind,
    positionX,
    positionY,
    stageIndex,
    nextAdvanceAllowedAt,
    pendingSkipWaitCost,
    mutation,
    awaitingRegrowthForRemutation,
    mutationRolledThisCycle,
  );

  /// Create a copy of DecorItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DecorItemImplCopyWith<_$DecorItemImpl> get copyWith =>
      __$$DecorItemImplCopyWithImpl<_$DecorItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DecorItemImplToJson(this);
  }
}

abstract class _DecorItem extends DecorItem {
  const factory _DecorItem({
    required final String id,
    @VisualThemeIdJsonConverter() required final VisualThemeId themeId,
    required final String kind,
    final double positionX,
    final double positionY,
    final int stageIndex,
    final DateTime? nextAdvanceAllowedAt,
    final int? pendingSkipWaitCost,
    @MutationKindJsonConverter() final MutationKind? mutation,
    final bool awaitingRegrowthForRemutation,
    final bool mutationRolledThisCycle,
  }) = _$DecorItemImpl;
  const _DecorItem._() : super._();

  factory _DecorItem.fromJson(Map<String, dynamic> json) =
      _$DecorItemImpl.fromJson;

  @override
  String get id;
  @override
  @VisualThemeIdJsonConverter()
  VisualThemeId get themeId;
  @override
  String get kind;
  @override
  double get positionX;
  @override
  double get positionY;
  @override
  int get stageIndex;
  @override
  DateTime? get nextAdvanceAllowedAt;
  @override
  int? get pendingSkipWaitCost;
  @override
  @MutationKindJsonConverter()
  MutationKind? get mutation;
  @override
  bool get awaitingRegrowthForRemutation;
  @override
  bool get mutationRolledThisCycle;

  /// Create a copy of DecorItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DecorItemImplCopyWith<_$DecorItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
