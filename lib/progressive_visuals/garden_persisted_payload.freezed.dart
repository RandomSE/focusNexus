// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_persisted_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GardenPersistedPayload _$GardenPersistedPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _GardenPersistedPayload.fromJson(json);
}

/// @nodoc
mixin _$GardenPersistedPayload {
  List<GardenItem> get items => throw _privateConstructorUsedError;
  List<DecorItem> get decor => throw _privateConstructorUsedError;
  @DecorStashJsonConverter()
  Map<String, int> get decorStash => throw _privateConstructorUsedError;
  List<DecorItem> get decorInventory => throw _privateConstructorUsedError;
  List<GardenItem> get plantInventory => throw _privateConstructorUsedError;
  bool get freeFirstGrowthEverConsumed => throw _privateConstructorUsedError;
  String? get freeFirstGrowthEligibleItemId =>
      throw _privateConstructorUsedError;
  bool? get legacyFreeFirst => throw _privateConstructorUsedError;
  int get lifetimeZenPointsSpent => throw _privateConstructorUsedError;
  bool get cherryBlossomTreeUnlocked => throw _privateConstructorUsedError;
  bool get suppressRestartGrowthPrompt => throw _privateConstructorUsedError;
  bool get cherryBlossomUnlockToastShown => throw _privateConstructorUsedError;
  CherryBlossomTreeState get cherryBlossomTree =>
      throw _privateConstructorUsedError;

  /// Serializes this GardenPersistedPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GardenPersistedPayloadCopyWith<GardenPersistedPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GardenPersistedPayloadCopyWith<$Res> {
  factory $GardenPersistedPayloadCopyWith(
    GardenPersistedPayload value,
    $Res Function(GardenPersistedPayload) then,
  ) = _$GardenPersistedPayloadCopyWithImpl<$Res, GardenPersistedPayload>;
  @useResult
  $Res call({
    List<GardenItem> items,
    List<DecorItem> decor,
    @DecorStashJsonConverter() Map<String, int> decorStash,
    List<DecorItem> decorInventory,
    List<GardenItem> plantInventory,
    bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool? legacyFreeFirst,
    int lifetimeZenPointsSpent,
    bool cherryBlossomTreeUnlocked,
    bool suppressRestartGrowthPrompt,
    bool cherryBlossomUnlockToastShown,
    CherryBlossomTreeState cherryBlossomTree,
  });

  $CherryBlossomTreeStateCopyWith<$Res> get cherryBlossomTree;
}

/// @nodoc
class _$GardenPersistedPayloadCopyWithImpl<
  $Res,
  $Val extends GardenPersistedPayload
>
    implements $GardenPersistedPayloadCopyWith<$Res> {
  _$GardenPersistedPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? decor = null,
    Object? decorStash = null,
    Object? decorInventory = null,
    Object? plantInventory = null,
    Object? freeFirstGrowthEverConsumed = null,
    Object? freeFirstGrowthEligibleItemId = freezed,
    Object? legacyFreeFirst = freezed,
    Object? lifetimeZenPointsSpent = null,
    Object? cherryBlossomTreeUnlocked = null,
    Object? suppressRestartGrowthPrompt = null,
    Object? cherryBlossomUnlockToastShown = null,
    Object? cherryBlossomTree = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<GardenItem>,
            decor: null == decor
                ? _value.decor
                : decor // ignore: cast_nullable_to_non_nullable
                      as List<DecorItem>,
            decorStash: null == decorStash
                ? _value.decorStash
                : decorStash // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            decorInventory: null == decorInventory
                ? _value.decorInventory
                : decorInventory // ignore: cast_nullable_to_non_nullable
                      as List<DecorItem>,
            plantInventory: null == plantInventory
                ? _value.plantInventory
                : plantInventory // ignore: cast_nullable_to_non_nullable
                      as List<GardenItem>,
            freeFirstGrowthEverConsumed: null == freeFirstGrowthEverConsumed
                ? _value.freeFirstGrowthEverConsumed
                : freeFirstGrowthEverConsumed // ignore: cast_nullable_to_non_nullable
                      as bool,
            freeFirstGrowthEligibleItemId:
                freezed == freeFirstGrowthEligibleItemId
                ? _value.freeFirstGrowthEligibleItemId
                : freeFirstGrowthEligibleItemId // ignore: cast_nullable_to_non_nullable
                      as String?,
            legacyFreeFirst: freezed == legacyFreeFirst
                ? _value.legacyFreeFirst
                : legacyFreeFirst // ignore: cast_nullable_to_non_nullable
                      as bool?,
            lifetimeZenPointsSpent: null == lifetimeZenPointsSpent
                ? _value.lifetimeZenPointsSpent
                : lifetimeZenPointsSpent // ignore: cast_nullable_to_non_nullable
                      as int,
            cherryBlossomTreeUnlocked: null == cherryBlossomTreeUnlocked
                ? _value.cherryBlossomTreeUnlocked
                : cherryBlossomTreeUnlocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            suppressRestartGrowthPrompt: null == suppressRestartGrowthPrompt
                ? _value.suppressRestartGrowthPrompt
                : suppressRestartGrowthPrompt // ignore: cast_nullable_to_non_nullable
                      as bool,
            cherryBlossomUnlockToastShown: null == cherryBlossomUnlockToastShown
                ? _value.cherryBlossomUnlockToastShown
                : cherryBlossomUnlockToastShown // ignore: cast_nullable_to_non_nullable
                      as bool,
            cherryBlossomTree: null == cherryBlossomTree
                ? _value.cherryBlossomTree
                : cherryBlossomTree // ignore: cast_nullable_to_non_nullable
                      as CherryBlossomTreeState,
          )
          as $Val,
    );
  }

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CherryBlossomTreeStateCopyWith<$Res> get cherryBlossomTree {
    return $CherryBlossomTreeStateCopyWith<$Res>(_value.cherryBlossomTree, (
      value,
    ) {
      return _then(_value.copyWith(cherryBlossomTree: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GardenPersistedPayloadImplCopyWith<$Res>
    implements $GardenPersistedPayloadCopyWith<$Res> {
  factory _$$GardenPersistedPayloadImplCopyWith(
    _$GardenPersistedPayloadImpl value,
    $Res Function(_$GardenPersistedPayloadImpl) then,
  ) = __$$GardenPersistedPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<GardenItem> items,
    List<DecorItem> decor,
    @DecorStashJsonConverter() Map<String, int> decorStash,
    List<DecorItem> decorInventory,
    List<GardenItem> plantInventory,
    bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool? legacyFreeFirst,
    int lifetimeZenPointsSpent,
    bool cherryBlossomTreeUnlocked,
    bool suppressRestartGrowthPrompt,
    bool cherryBlossomUnlockToastShown,
    CherryBlossomTreeState cherryBlossomTree,
  });

  @override
  $CherryBlossomTreeStateCopyWith<$Res> get cherryBlossomTree;
}

/// @nodoc
class __$$GardenPersistedPayloadImplCopyWithImpl<$Res>
    extends
        _$GardenPersistedPayloadCopyWithImpl<$Res, _$GardenPersistedPayloadImpl>
    implements _$$GardenPersistedPayloadImplCopyWith<$Res> {
  __$$GardenPersistedPayloadImplCopyWithImpl(
    _$GardenPersistedPayloadImpl _value,
    $Res Function(_$GardenPersistedPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? decor = null,
    Object? decorStash = null,
    Object? decorInventory = null,
    Object? plantInventory = null,
    Object? freeFirstGrowthEverConsumed = null,
    Object? freeFirstGrowthEligibleItemId = freezed,
    Object? legacyFreeFirst = freezed,
    Object? lifetimeZenPointsSpent = null,
    Object? cherryBlossomTreeUnlocked = null,
    Object? suppressRestartGrowthPrompt = null,
    Object? cherryBlossomUnlockToastShown = null,
    Object? cherryBlossomTree = null,
  }) {
    return _then(
      _$GardenPersistedPayloadImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<GardenItem>,
        decor: null == decor
            ? _value._decor
            : decor // ignore: cast_nullable_to_non_nullable
                  as List<DecorItem>,
        decorStash: null == decorStash
            ? _value._decorStash
            : decorStash // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        decorInventory: null == decorInventory
            ? _value._decorInventory
            : decorInventory // ignore: cast_nullable_to_non_nullable
                  as List<DecorItem>,
        plantInventory: null == plantInventory
            ? _value._plantInventory
            : plantInventory // ignore: cast_nullable_to_non_nullable
                  as List<GardenItem>,
        freeFirstGrowthEverConsumed: null == freeFirstGrowthEverConsumed
            ? _value.freeFirstGrowthEverConsumed
            : freeFirstGrowthEverConsumed // ignore: cast_nullable_to_non_nullable
                  as bool,
        freeFirstGrowthEligibleItemId: freezed == freeFirstGrowthEligibleItemId
            ? _value.freeFirstGrowthEligibleItemId
            : freeFirstGrowthEligibleItemId // ignore: cast_nullable_to_non_nullable
                  as String?,
        legacyFreeFirst: freezed == legacyFreeFirst
            ? _value.legacyFreeFirst
            : legacyFreeFirst // ignore: cast_nullable_to_non_nullable
                  as bool?,
        lifetimeZenPointsSpent: null == lifetimeZenPointsSpent
            ? _value.lifetimeZenPointsSpent
            : lifetimeZenPointsSpent // ignore: cast_nullable_to_non_nullable
                  as int,
        cherryBlossomTreeUnlocked: null == cherryBlossomTreeUnlocked
            ? _value.cherryBlossomTreeUnlocked
            : cherryBlossomTreeUnlocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        suppressRestartGrowthPrompt: null == suppressRestartGrowthPrompt
            ? _value.suppressRestartGrowthPrompt
            : suppressRestartGrowthPrompt // ignore: cast_nullable_to_non_nullable
                  as bool,
        cherryBlossomUnlockToastShown: null == cherryBlossomUnlockToastShown
            ? _value.cherryBlossomUnlockToastShown
            : cherryBlossomUnlockToastShown // ignore: cast_nullable_to_non_nullable
                  as bool,
        cherryBlossomTree: null == cherryBlossomTree
            ? _value.cherryBlossomTree
            : cherryBlossomTree // ignore: cast_nullable_to_non_nullable
                  as CherryBlossomTreeState,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GardenPersistedPayloadImpl implements _GardenPersistedPayload {
  const _$GardenPersistedPayloadImpl({
    final List<GardenItem> items = const <GardenItem>[],
    final List<DecorItem> decor = const <DecorItem>[],
    @DecorStashJsonConverter()
    final Map<String, int> decorStash = const <String, int>{},
    final List<DecorItem> decorInventory = const <DecorItem>[],
    final List<GardenItem> plantInventory = const <GardenItem>[],
    this.freeFirstGrowthEverConsumed = false,
    this.freeFirstGrowthEligibleItemId,
    this.legacyFreeFirst,
    this.lifetimeZenPointsSpent = 0,
    this.cherryBlossomTreeUnlocked = false,
    this.suppressRestartGrowthPrompt = false,
    this.cherryBlossomUnlockToastShown = false,
    this.cherryBlossomTree = const CherryBlossomTreeState(),
  }) : _items = items,
       _decor = decor,
       _decorStash = decorStash,
       _decorInventory = decorInventory,
       _plantInventory = plantInventory;

  factory _$GardenPersistedPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$GardenPersistedPayloadImplFromJson(json);

  final List<GardenItem> _items;
  @override
  @JsonKey()
  List<GardenItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<DecorItem> _decor;
  @override
  @JsonKey()
  List<DecorItem> get decor {
    if (_decor is EqualUnmodifiableListView) return _decor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_decor);
  }

  final Map<String, int> _decorStash;
  @override
  @JsonKey()
  @DecorStashJsonConverter()
  Map<String, int> get decorStash {
    if (_decorStash is EqualUnmodifiableMapView) return _decorStash;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_decorStash);
  }

  final List<DecorItem> _decorInventory;
  @override
  @JsonKey()
  List<DecorItem> get decorInventory {
    if (_decorInventory is EqualUnmodifiableListView) return _decorInventory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_decorInventory);
  }

  final List<GardenItem> _plantInventory;
  @override
  @JsonKey()
  List<GardenItem> get plantInventory {
    if (_plantInventory is EqualUnmodifiableListView) return _plantInventory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_plantInventory);
  }

  @override
  @JsonKey()
  final bool freeFirstGrowthEverConsumed;
  @override
  final String? freeFirstGrowthEligibleItemId;
  @override
  final bool? legacyFreeFirst;
  @override
  @JsonKey()
  final int lifetimeZenPointsSpent;
  @override
  @JsonKey()
  final bool cherryBlossomTreeUnlocked;
  @override
  @JsonKey()
  final bool suppressRestartGrowthPrompt;
  @override
  @JsonKey()
  final bool cherryBlossomUnlockToastShown;
  @override
  @JsonKey()
  final CherryBlossomTreeState cherryBlossomTree;

  @override
  String toString() {
    return 'GardenPersistedPayload(items: $items, decor: $decor, decorStash: $decorStash, decorInventory: $decorInventory, plantInventory: $plantInventory, freeFirstGrowthEverConsumed: $freeFirstGrowthEverConsumed, freeFirstGrowthEligibleItemId: $freeFirstGrowthEligibleItemId, legacyFreeFirst: $legacyFreeFirst, lifetimeZenPointsSpent: $lifetimeZenPointsSpent, cherryBlossomTreeUnlocked: $cherryBlossomTreeUnlocked, suppressRestartGrowthPrompt: $suppressRestartGrowthPrompt, cherryBlossomUnlockToastShown: $cherryBlossomUnlockToastShown, cherryBlossomTree: $cherryBlossomTree)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GardenPersistedPayloadImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._decor, _decor) &&
            const DeepCollectionEquality().equals(
              other._decorStash,
              _decorStash,
            ) &&
            const DeepCollectionEquality().equals(
              other._decorInventory,
              _decorInventory,
            ) &&
            const DeepCollectionEquality().equals(
              other._plantInventory,
              _plantInventory,
            ) &&
            (identical(
                  other.freeFirstGrowthEverConsumed,
                  freeFirstGrowthEverConsumed,
                ) ||
                other.freeFirstGrowthEverConsumed ==
                    freeFirstGrowthEverConsumed) &&
            (identical(
                  other.freeFirstGrowthEligibleItemId,
                  freeFirstGrowthEligibleItemId,
                ) ||
                other.freeFirstGrowthEligibleItemId ==
                    freeFirstGrowthEligibleItemId) &&
            (identical(other.legacyFreeFirst, legacyFreeFirst) ||
                other.legacyFreeFirst == legacyFreeFirst) &&
            (identical(other.lifetimeZenPointsSpent, lifetimeZenPointsSpent) ||
                other.lifetimeZenPointsSpent == lifetimeZenPointsSpent) &&
            (identical(
                  other.cherryBlossomTreeUnlocked,
                  cherryBlossomTreeUnlocked,
                ) ||
                other.cherryBlossomTreeUnlocked == cherryBlossomTreeUnlocked) &&
            (identical(
                  other.suppressRestartGrowthPrompt,
                  suppressRestartGrowthPrompt,
                ) ||
                other.suppressRestartGrowthPrompt ==
                    suppressRestartGrowthPrompt) &&
            (identical(
                  other.cherryBlossomUnlockToastShown,
                  cherryBlossomUnlockToastShown,
                ) ||
                other.cherryBlossomUnlockToastShown ==
                    cherryBlossomUnlockToastShown) &&
            (identical(other.cherryBlossomTree, cherryBlossomTree) ||
                other.cherryBlossomTree == cherryBlossomTree));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_decor),
    const DeepCollectionEquality().hash(_decorStash),
    const DeepCollectionEquality().hash(_decorInventory),
    const DeepCollectionEquality().hash(_plantInventory),
    freeFirstGrowthEverConsumed,
    freeFirstGrowthEligibleItemId,
    legacyFreeFirst,
    lifetimeZenPointsSpent,
    cherryBlossomTreeUnlocked,
    suppressRestartGrowthPrompt,
    cherryBlossomUnlockToastShown,
    cherryBlossomTree,
  );

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GardenPersistedPayloadImplCopyWith<_$GardenPersistedPayloadImpl>
  get copyWith =>
      __$$GardenPersistedPayloadImplCopyWithImpl<_$GardenPersistedPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GardenPersistedPayloadImplToJson(this);
  }
}

abstract class _GardenPersistedPayload implements GardenPersistedPayload {
  const factory _GardenPersistedPayload({
    final List<GardenItem> items,
    final List<DecorItem> decor,
    @DecorStashJsonConverter() final Map<String, int> decorStash,
    final List<DecorItem> decorInventory,
    final List<GardenItem> plantInventory,
    final bool freeFirstGrowthEverConsumed,
    final String? freeFirstGrowthEligibleItemId,
    final bool? legacyFreeFirst,
    final int lifetimeZenPointsSpent,
    final bool cherryBlossomTreeUnlocked,
    final bool suppressRestartGrowthPrompt,
    final bool cherryBlossomUnlockToastShown,
    final CherryBlossomTreeState cherryBlossomTree,
  }) = _$GardenPersistedPayloadImpl;

  factory _GardenPersistedPayload.fromJson(Map<String, dynamic> json) =
      _$GardenPersistedPayloadImpl.fromJson;

  @override
  List<GardenItem> get items;
  @override
  List<DecorItem> get decor;
  @override
  @DecorStashJsonConverter()
  Map<String, int> get decorStash;
  @override
  List<DecorItem> get decorInventory;
  @override
  List<GardenItem> get plantInventory;
  @override
  bool get freeFirstGrowthEverConsumed;
  @override
  String? get freeFirstGrowthEligibleItemId;
  @override
  bool? get legacyFreeFirst;
  @override
  int get lifetimeZenPointsSpent;
  @override
  bool get cherryBlossomTreeUnlocked;
  @override
  bool get suppressRestartGrowthPrompt;
  @override
  bool get cherryBlossomUnlockToastShown;
  @override
  CherryBlossomTreeState get cherryBlossomTree;

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GardenPersistedPayloadImplCopyWith<_$GardenPersistedPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
