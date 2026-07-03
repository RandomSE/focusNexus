// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cherry_blossom_tree_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CherryBlossomTreeState _$CherryBlossomTreeStateFromJson(
  Map<String, dynamic> json,
) {
  return _CherryBlossomTreeState.fromJson(json);
}

/// @nodoc
mixin _$CherryBlossomTreeState {
  int get stageIndex => throw _privateConstructorUsedError;
  int get growthStepsInStage => throw _privateConstructorUsedError;
  CherryBlossomPrestigePath? get prestigePath =>
      throw _privateConstructorUsedError;
  int get totalTreePointsInvested => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
  Map<int, int> get bonsaiFilledSlots => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
  List<String?> get customBonsaiGardenSlots =>
      throw _privateConstructorUsedError;
  int get peaceBonsaiCount => throw _privateConstructorUsedError;
  int get powerBonsaiCount => throw _privateConstructorUsedError;
  List<CherryBlossomPrestigePath> get unlockedFinalePaths =>
      throw _privateConstructorUsedError;
  int get highestStageUnlocked => throw _privateConstructorUsedError;

  /// Serializes this CherryBlossomTreeState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CherryBlossomTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CherryBlossomTreeStateCopyWith<CherryBlossomTreeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CherryBlossomTreeStateCopyWith<$Res> {
  factory $CherryBlossomTreeStateCopyWith(
    CherryBlossomTreeState value,
    $Res Function(CherryBlossomTreeState) then,
  ) = _$CherryBlossomTreeStateCopyWithImpl<$Res, CherryBlossomTreeState>;
  @useResult
  $Res call({
    int stageIndex,
    int growthStepsInStage,
    CherryBlossomPrestigePath? prestigePath,
    int totalTreePointsInvested,
    @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
    Map<int, int> bonsaiFilledSlots,
    @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
    List<String?> customBonsaiGardenSlots,
    int peaceBonsaiCount,
    int powerBonsaiCount,
    List<CherryBlossomPrestigePath> unlockedFinalePaths,
    int highestStageUnlocked,
  });
}

/// @nodoc
class _$CherryBlossomTreeStateCopyWithImpl<
  $Res,
  $Val extends CherryBlossomTreeState
>
    implements $CherryBlossomTreeStateCopyWith<$Res> {
  _$CherryBlossomTreeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CherryBlossomTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageIndex = null,
    Object? growthStepsInStage = null,
    Object? prestigePath = freezed,
    Object? totalTreePointsInvested = null,
    Object? bonsaiFilledSlots = null,
    Object? customBonsaiGardenSlots = null,
    Object? peaceBonsaiCount = null,
    Object? powerBonsaiCount = null,
    Object? unlockedFinalePaths = null,
    Object? highestStageUnlocked = null,
  }) {
    return _then(
      _value.copyWith(
            stageIndex: null == stageIndex
                ? _value.stageIndex
                : stageIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            growthStepsInStage: null == growthStepsInStage
                ? _value.growthStepsInStage
                : growthStepsInStage // ignore: cast_nullable_to_non_nullable
                      as int,
            prestigePath: freezed == prestigePath
                ? _value.prestigePath
                : prestigePath // ignore: cast_nullable_to_non_nullable
                      as CherryBlossomPrestigePath?,
            totalTreePointsInvested: null == totalTreePointsInvested
                ? _value.totalTreePointsInvested
                : totalTreePointsInvested // ignore: cast_nullable_to_non_nullable
                      as int,
            bonsaiFilledSlots: null == bonsaiFilledSlots
                ? _value.bonsaiFilledSlots
                : bonsaiFilledSlots // ignore: cast_nullable_to_non_nullable
                      as Map<int, int>,
            customBonsaiGardenSlots: null == customBonsaiGardenSlots
                ? _value.customBonsaiGardenSlots
                : customBonsaiGardenSlots // ignore: cast_nullable_to_non_nullable
                      as List<String?>,
            peaceBonsaiCount: null == peaceBonsaiCount
                ? _value.peaceBonsaiCount
                : peaceBonsaiCount // ignore: cast_nullable_to_non_nullable
                      as int,
            powerBonsaiCount: null == powerBonsaiCount
                ? _value.powerBonsaiCount
                : powerBonsaiCount // ignore: cast_nullable_to_non_nullable
                      as int,
            unlockedFinalePaths: null == unlockedFinalePaths
                ? _value.unlockedFinalePaths
                : unlockedFinalePaths // ignore: cast_nullable_to_non_nullable
                      as List<CherryBlossomPrestigePath>,
            highestStageUnlocked: null == highestStageUnlocked
                ? _value.highestStageUnlocked
                : highestStageUnlocked // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CherryBlossomTreeStateImplCopyWith<$Res>
    implements $CherryBlossomTreeStateCopyWith<$Res> {
  factory _$$CherryBlossomTreeStateImplCopyWith(
    _$CherryBlossomTreeStateImpl value,
    $Res Function(_$CherryBlossomTreeStateImpl) then,
  ) = __$$CherryBlossomTreeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int stageIndex,
    int growthStepsInStage,
    CherryBlossomPrestigePath? prestigePath,
    int totalTreePointsInvested,
    @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
    Map<int, int> bonsaiFilledSlots,
    @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
    List<String?> customBonsaiGardenSlots,
    int peaceBonsaiCount,
    int powerBonsaiCount,
    List<CherryBlossomPrestigePath> unlockedFinalePaths,
    int highestStageUnlocked,
  });
}

/// @nodoc
class __$$CherryBlossomTreeStateImplCopyWithImpl<$Res>
    extends
        _$CherryBlossomTreeStateCopyWithImpl<$Res, _$CherryBlossomTreeStateImpl>
    implements _$$CherryBlossomTreeStateImplCopyWith<$Res> {
  __$$CherryBlossomTreeStateImplCopyWithImpl(
    _$CherryBlossomTreeStateImpl _value,
    $Res Function(_$CherryBlossomTreeStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CherryBlossomTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageIndex = null,
    Object? growthStepsInStage = null,
    Object? prestigePath = freezed,
    Object? totalTreePointsInvested = null,
    Object? bonsaiFilledSlots = null,
    Object? customBonsaiGardenSlots = null,
    Object? peaceBonsaiCount = null,
    Object? powerBonsaiCount = null,
    Object? unlockedFinalePaths = null,
    Object? highestStageUnlocked = null,
  }) {
    return _then(
      _$CherryBlossomTreeStateImpl(
        stageIndex: null == stageIndex
            ? _value.stageIndex
            : stageIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        growthStepsInStage: null == growthStepsInStage
            ? _value.growthStepsInStage
            : growthStepsInStage // ignore: cast_nullable_to_non_nullable
                  as int,
        prestigePath: freezed == prestigePath
            ? _value.prestigePath
            : prestigePath // ignore: cast_nullable_to_non_nullable
                  as CherryBlossomPrestigePath?,
        totalTreePointsInvested: null == totalTreePointsInvested
            ? _value.totalTreePointsInvested
            : totalTreePointsInvested // ignore: cast_nullable_to_non_nullable
                  as int,
        bonsaiFilledSlots: null == bonsaiFilledSlots
            ? _value._bonsaiFilledSlots
            : bonsaiFilledSlots // ignore: cast_nullable_to_non_nullable
                  as Map<int, int>,
        customBonsaiGardenSlots: null == customBonsaiGardenSlots
            ? _value._customBonsaiGardenSlots
            : customBonsaiGardenSlots // ignore: cast_nullable_to_non_nullable
                  as List<String?>,
        peaceBonsaiCount: null == peaceBonsaiCount
            ? _value.peaceBonsaiCount
            : peaceBonsaiCount // ignore: cast_nullable_to_non_nullable
                  as int,
        powerBonsaiCount: null == powerBonsaiCount
            ? _value.powerBonsaiCount
            : powerBonsaiCount // ignore: cast_nullable_to_non_nullable
                  as int,
        unlockedFinalePaths: null == unlockedFinalePaths
            ? _value._unlockedFinalePaths
            : unlockedFinalePaths // ignore: cast_nullable_to_non_nullable
                  as List<CherryBlossomPrestigePath>,
        highestStageUnlocked: null == highestStageUnlocked
            ? _value.highestStageUnlocked
            : highestStageUnlocked // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CherryBlossomTreeStateImpl extends _CherryBlossomTreeState {
  const _$CherryBlossomTreeStateImpl({
    this.stageIndex = 0,
    this.growthStepsInStage = 0,
    this.prestigePath,
    this.totalTreePointsInvested = 0,
    @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
    final Map<int, int> bonsaiFilledSlots = const <int, int>{},
    @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
    final List<String?> customBonsaiGardenSlots = const <String?>[],
    this.peaceBonsaiCount = 0,
    this.powerBonsaiCount = 0,
    final List<CherryBlossomPrestigePath> unlockedFinalePaths =
        const <CherryBlossomPrestigePath>[],
    this.highestStageUnlocked = 0,
  }) : _bonsaiFilledSlots = bonsaiFilledSlots,
       _customBonsaiGardenSlots = customBonsaiGardenSlots,
       _unlockedFinalePaths = unlockedFinalePaths,
       super._();

  factory _$CherryBlossomTreeStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CherryBlossomTreeStateImplFromJson(json);

  @override
  @JsonKey()
  final int stageIndex;
  @override
  @JsonKey()
  final int growthStepsInStage;
  @override
  final CherryBlossomPrestigePath? prestigePath;
  @override
  @JsonKey()
  final int totalTreePointsInvested;
  final Map<int, int> _bonsaiFilledSlots;
  @override
  @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
  Map<int, int> get bonsaiFilledSlots {
    if (_bonsaiFilledSlots is EqualUnmodifiableMapView)
      return _bonsaiFilledSlots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_bonsaiFilledSlots);
  }

  final List<String?> _customBonsaiGardenSlots;
  @override
  @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
  List<String?> get customBonsaiGardenSlots {
    if (_customBonsaiGardenSlots is EqualUnmodifiableListView)
      return _customBonsaiGardenSlots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customBonsaiGardenSlots);
  }

  @override
  @JsonKey()
  final int peaceBonsaiCount;
  @override
  @JsonKey()
  final int powerBonsaiCount;
  final List<CherryBlossomPrestigePath> _unlockedFinalePaths;
  @override
  @JsonKey()
  List<CherryBlossomPrestigePath> get unlockedFinalePaths {
    if (_unlockedFinalePaths is EqualUnmodifiableListView)
      return _unlockedFinalePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedFinalePaths);
  }

  @override
  @JsonKey()
  final int highestStageUnlocked;

  @override
  String toString() {
    return 'CherryBlossomTreeState(stageIndex: $stageIndex, growthStepsInStage: $growthStepsInStage, prestigePath: $prestigePath, totalTreePointsInvested: $totalTreePointsInvested, bonsaiFilledSlots: $bonsaiFilledSlots, customBonsaiGardenSlots: $customBonsaiGardenSlots, peaceBonsaiCount: $peaceBonsaiCount, powerBonsaiCount: $powerBonsaiCount, unlockedFinalePaths: $unlockedFinalePaths, highestStageUnlocked: $highestStageUnlocked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CherryBlossomTreeStateImpl &&
            (identical(other.stageIndex, stageIndex) ||
                other.stageIndex == stageIndex) &&
            (identical(other.growthStepsInStage, growthStepsInStage) ||
                other.growthStepsInStage == growthStepsInStage) &&
            (identical(other.prestigePath, prestigePath) ||
                other.prestigePath == prestigePath) &&
            (identical(
                  other.totalTreePointsInvested,
                  totalTreePointsInvested,
                ) ||
                other.totalTreePointsInvested == totalTreePointsInvested) &&
            const DeepCollectionEquality().equals(
              other._bonsaiFilledSlots,
              _bonsaiFilledSlots,
            ) &&
            const DeepCollectionEquality().equals(
              other._customBonsaiGardenSlots,
              _customBonsaiGardenSlots,
            ) &&
            (identical(other.peaceBonsaiCount, peaceBonsaiCount) ||
                other.peaceBonsaiCount == peaceBonsaiCount) &&
            (identical(other.powerBonsaiCount, powerBonsaiCount) ||
                other.powerBonsaiCount == powerBonsaiCount) &&
            const DeepCollectionEquality().equals(
              other._unlockedFinalePaths,
              _unlockedFinalePaths,
            ) &&
            (identical(other.highestStageUnlocked, highestStageUnlocked) ||
                other.highestStageUnlocked == highestStageUnlocked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    stageIndex,
    growthStepsInStage,
    prestigePath,
    totalTreePointsInvested,
    const DeepCollectionEquality().hash(_bonsaiFilledSlots),
    const DeepCollectionEquality().hash(_customBonsaiGardenSlots),
    peaceBonsaiCount,
    powerBonsaiCount,
    const DeepCollectionEquality().hash(_unlockedFinalePaths),
    highestStageUnlocked,
  );

  /// Create a copy of CherryBlossomTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CherryBlossomTreeStateImplCopyWith<_$CherryBlossomTreeStateImpl>
  get copyWith =>
      __$$CherryBlossomTreeStateImplCopyWithImpl<_$CherryBlossomTreeStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CherryBlossomTreeStateImplToJson(this);
  }
}

abstract class _CherryBlossomTreeState extends CherryBlossomTreeState {
  const factory _CherryBlossomTreeState({
    final int stageIndex,
    final int growthStepsInStage,
    final CherryBlossomPrestigePath? prestigePath,
    final int totalTreePointsInvested,
    @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
    final Map<int, int> bonsaiFilledSlots,
    @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
    final List<String?> customBonsaiGardenSlots,
    final int peaceBonsaiCount,
    final int powerBonsaiCount,
    final List<CherryBlossomPrestigePath> unlockedFinalePaths,
    final int highestStageUnlocked,
  }) = _$CherryBlossomTreeStateImpl;
  const _CherryBlossomTreeState._() : super._();

  factory _CherryBlossomTreeState.fromJson(Map<String, dynamic> json) =
      _$CherryBlossomTreeStateImpl.fromJson;

  @override
  int get stageIndex;
  @override
  int get growthStepsInStage;
  @override
  CherryBlossomPrestigePath? get prestigePath;
  @override
  int get totalTreePointsInvested;
  @override
  @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
  Map<int, int> get bonsaiFilledSlots;
  @override
  @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
  List<String?> get customBonsaiGardenSlots;
  @override
  int get peaceBonsaiCount;
  @override
  int get powerBonsaiCount;
  @override
  List<CherryBlossomPrestigePath> get unlockedFinalePaths;
  @override
  int get highestStageUnlocked;

  /// Create a copy of CherryBlossomTreeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CherryBlossomTreeStateImplCopyWith<_$CherryBlossomTreeStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
