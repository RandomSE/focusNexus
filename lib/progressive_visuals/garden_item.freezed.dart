// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GardenItem _$GardenItemFromJson(Map<String, dynamic> json) {
  return _GardenItem.fromJson(json);
}

/// @nodoc
mixin _$GardenItem {
  String get id => throw _privateConstructorUsedError;
  @VisualThemeIdJsonConverter()
  VisualThemeId get themeId => throw _privateConstructorUsedError;
  int get stageIndex => throw _privateConstructorUsedError;
  double get positionX => throw _privateConstructorUsedError;
  double get positionY => throw _privateConstructorUsedError;
  DateTime? get nextAdvanceAllowedAt => throw _privateConstructorUsedError;
  int? get pendingSkipWaitCost => throw _privateConstructorUsedError;
  @MutationKindJsonConverter()
  MutationKind? get mutation => throw _privateConstructorUsedError;
  bool get awaitingRegrowthForRemutation => throw _privateConstructorUsedError;
  bool get mutationRolledThisCycle => throw _privateConstructorUsedError;
  bool get regrowthDiscountActive => throw _privateConstructorUsedError;

  /// Serializes this GardenItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GardenItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GardenItemCopyWith<GardenItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GardenItemCopyWith<$Res> {
  factory $GardenItemCopyWith(
    GardenItem value,
    $Res Function(GardenItem) then,
  ) = _$GardenItemCopyWithImpl<$Res, GardenItem>;
  @useResult
  $Res call({
    String id,
    @VisualThemeIdJsonConverter() VisualThemeId themeId,
    int stageIndex,
    double positionX,
    double positionY,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    bool awaitingRegrowthForRemutation,
    bool mutationRolledThisCycle,
    bool regrowthDiscountActive,
  });
}

/// @nodoc
class _$GardenItemCopyWithImpl<$Res, $Val extends GardenItem>
    implements $GardenItemCopyWith<$Res> {
  _$GardenItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GardenItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? themeId = null,
    Object? stageIndex = null,
    Object? positionX = null,
    Object? positionY = null,
    Object? nextAdvanceAllowedAt = freezed,
    Object? pendingSkipWaitCost = freezed,
    Object? mutation = freezed,
    Object? awaitingRegrowthForRemutation = null,
    Object? mutationRolledThisCycle = null,
    Object? regrowthDiscountActive = null,
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
            stageIndex:
                null == stageIndex
                    ? _value.stageIndex
                    : stageIndex // ignore: cast_nullable_to_non_nullable
                        as int,
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
            regrowthDiscountActive:
                null == regrowthDiscountActive
                    ? _value.regrowthDiscountActive
                    : regrowthDiscountActive // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GardenItemImplCopyWith<$Res>
    implements $GardenItemCopyWith<$Res> {
  factory _$$GardenItemImplCopyWith(
    _$GardenItemImpl value,
    $Res Function(_$GardenItemImpl) then,
  ) = __$$GardenItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @VisualThemeIdJsonConverter() VisualThemeId themeId,
    int stageIndex,
    double positionX,
    double positionY,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    bool awaitingRegrowthForRemutation,
    bool mutationRolledThisCycle,
    bool regrowthDiscountActive,
  });
}

/// @nodoc
class __$$GardenItemImplCopyWithImpl<$Res>
    extends _$GardenItemCopyWithImpl<$Res, _$GardenItemImpl>
    implements _$$GardenItemImplCopyWith<$Res> {
  __$$GardenItemImplCopyWithImpl(
    _$GardenItemImpl _value,
    $Res Function(_$GardenItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GardenItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? themeId = null,
    Object? stageIndex = null,
    Object? positionX = null,
    Object? positionY = null,
    Object? nextAdvanceAllowedAt = freezed,
    Object? pendingSkipWaitCost = freezed,
    Object? mutation = freezed,
    Object? awaitingRegrowthForRemutation = null,
    Object? mutationRolledThisCycle = null,
    Object? regrowthDiscountActive = null,
  }) {
    return _then(
      _$GardenItemImpl(
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
        stageIndex:
            null == stageIndex
                ? _value.stageIndex
                : stageIndex // ignore: cast_nullable_to_non_nullable
                    as int,
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
        regrowthDiscountActive:
            null == regrowthDiscountActive
                ? _value.regrowthDiscountActive
                : regrowthDiscountActive // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GardenItemImpl extends _GardenItem {
  const _$GardenItemImpl({
    required this.id,
    @VisualThemeIdJsonConverter() required this.themeId,
    this.stageIndex = 0,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.nextAdvanceAllowedAt,
    this.pendingSkipWaitCost,
    @MutationKindJsonConverter() this.mutation,
    this.awaitingRegrowthForRemutation = false,
    this.mutationRolledThisCycle = false,
    this.regrowthDiscountActive = false,
  }) : super._();

  factory _$GardenItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GardenItemImplFromJson(json);

  @override
  final String id;
  @override
  @VisualThemeIdJsonConverter()
  final VisualThemeId themeId;
  @override
  @JsonKey()
  final int stageIndex;
  @override
  @JsonKey()
  final double positionX;
  @override
  @JsonKey()
  final double positionY;
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
  @JsonKey()
  final bool regrowthDiscountActive;

  @override
  String toString() {
    return 'GardenItem(id: $id, themeId: $themeId, stageIndex: $stageIndex, positionX: $positionX, positionY: $positionY, nextAdvanceAllowedAt: $nextAdvanceAllowedAt, pendingSkipWaitCost: $pendingSkipWaitCost, mutation: $mutation, awaitingRegrowthForRemutation: $awaitingRegrowthForRemutation, mutationRolledThisCycle: $mutationRolledThisCycle, regrowthDiscountActive: $regrowthDiscountActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GardenItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.stageIndex, stageIndex) ||
                other.stageIndex == stageIndex) &&
            (identical(other.positionX, positionX) ||
                other.positionX == positionX) &&
            (identical(other.positionY, positionY) ||
                other.positionY == positionY) &&
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
                other.mutationRolledThisCycle == mutationRolledThisCycle) &&
            (identical(other.regrowthDiscountActive, regrowthDiscountActive) ||
                other.regrowthDiscountActive == regrowthDiscountActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    themeId,
    stageIndex,
    positionX,
    positionY,
    nextAdvanceAllowedAt,
    pendingSkipWaitCost,
    mutation,
    awaitingRegrowthForRemutation,
    mutationRolledThisCycle,
    regrowthDiscountActive,
  );

  /// Create a copy of GardenItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GardenItemImplCopyWith<_$GardenItemImpl> get copyWith =>
      __$$GardenItemImplCopyWithImpl<_$GardenItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GardenItemImplToJson(this);
  }
}

abstract class _GardenItem extends GardenItem {
  const factory _GardenItem({
    required final String id,
    @VisualThemeIdJsonConverter() required final VisualThemeId themeId,
    final int stageIndex,
    final double positionX,
    final double positionY,
    final DateTime? nextAdvanceAllowedAt,
    final int? pendingSkipWaitCost,
    @MutationKindJsonConverter() final MutationKind? mutation,
    final bool awaitingRegrowthForRemutation,
    final bool mutationRolledThisCycle,
    final bool regrowthDiscountActive,
  }) = _$GardenItemImpl;
  const _GardenItem._() : super._();

  factory _GardenItem.fromJson(Map<String, dynamic> json) =
      _$GardenItemImpl.fromJson;

  @override
  String get id;
  @override
  @VisualThemeIdJsonConverter()
  VisualThemeId get themeId;
  @override
  int get stageIndex;
  @override
  double get positionX;
  @override
  double get positionY;
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
  @override
  bool get regrowthDiscountActive;

  /// Create a copy of GardenItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GardenItemImplCopyWith<_$GardenItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
