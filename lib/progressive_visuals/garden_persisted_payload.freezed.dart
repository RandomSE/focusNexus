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
  bool get freeFirstGrowthEverConsumed => throw _privateConstructorUsedError;
  String? get freeFirstGrowthEligibleItemId =>
      throw _privateConstructorUsedError;
  bool? get legacyFreeFirst => throw _privateConstructorUsedError;

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
    bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool? legacyFreeFirst,
  });
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
    Object? freeFirstGrowthEverConsumed = null,
    Object? freeFirstGrowthEligibleItemId = freezed,
    Object? legacyFreeFirst = freezed,
  }) {
    return _then(
      _value.copyWith(
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<GardenItem>,
            decor:
                null == decor
                    ? _value.decor
                    : decor // ignore: cast_nullable_to_non_nullable
                        as List<DecorItem>,
            decorStash:
                null == decorStash
                    ? _value.decorStash
                    : decorStash // ignore: cast_nullable_to_non_nullable
                        as Map<String, int>,
            freeFirstGrowthEverConsumed:
                null == freeFirstGrowthEverConsumed
                    ? _value.freeFirstGrowthEverConsumed
                    : freeFirstGrowthEverConsumed // ignore: cast_nullable_to_non_nullable
                        as bool,
            freeFirstGrowthEligibleItemId:
                freezed == freeFirstGrowthEligibleItemId
                    ? _value.freeFirstGrowthEligibleItemId
                    : freeFirstGrowthEligibleItemId // ignore: cast_nullable_to_non_nullable
                        as String?,
            legacyFreeFirst:
                freezed == legacyFreeFirst
                    ? _value.legacyFreeFirst
                    : legacyFreeFirst // ignore: cast_nullable_to_non_nullable
                        as bool?,
          )
          as $Val,
    );
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
    bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool? legacyFreeFirst,
  });
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
    Object? freeFirstGrowthEverConsumed = null,
    Object? freeFirstGrowthEligibleItemId = freezed,
    Object? legacyFreeFirst = freezed,
  }) {
    return _then(
      _$GardenPersistedPayloadImpl(
        items:
            null == items
                ? _value._items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<GardenItem>,
        decor:
            null == decor
                ? _value._decor
                : decor // ignore: cast_nullable_to_non_nullable
                    as List<DecorItem>,
        decorStash:
            null == decorStash
                ? _value._decorStash
                : decorStash // ignore: cast_nullable_to_non_nullable
                    as Map<String, int>,
        freeFirstGrowthEverConsumed:
            null == freeFirstGrowthEverConsumed
                ? _value.freeFirstGrowthEverConsumed
                : freeFirstGrowthEverConsumed // ignore: cast_nullable_to_non_nullable
                    as bool,
        freeFirstGrowthEligibleItemId:
            freezed == freeFirstGrowthEligibleItemId
                ? _value.freeFirstGrowthEligibleItemId
                : freeFirstGrowthEligibleItemId // ignore: cast_nullable_to_non_nullable
                    as String?,
        legacyFreeFirst:
            freezed == legacyFreeFirst
                ? _value.legacyFreeFirst
                : legacyFreeFirst // ignore: cast_nullable_to_non_nullable
                    as bool?,
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
    this.freeFirstGrowthEverConsumed = false,
    this.freeFirstGrowthEligibleItemId,
    this.legacyFreeFirst,
  }) : _items = items,
       _decor = decor,
       _decorStash = decorStash;

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

  @override
  @JsonKey()
  final bool freeFirstGrowthEverConsumed;
  @override
  final String? freeFirstGrowthEligibleItemId;
  @override
  final bool? legacyFreeFirst;

  @override
  String toString() {
    return 'GardenPersistedPayload(items: $items, decor: $decor, decorStash: $decorStash, freeFirstGrowthEverConsumed: $freeFirstGrowthEverConsumed, freeFirstGrowthEligibleItemId: $freeFirstGrowthEligibleItemId, legacyFreeFirst: $legacyFreeFirst)';
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
                other.legacyFreeFirst == legacyFreeFirst));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_decor),
    const DeepCollectionEquality().hash(_decorStash),
    freeFirstGrowthEverConsumed,
    freeFirstGrowthEligibleItemId,
    legacyFreeFirst,
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
    final bool freeFirstGrowthEverConsumed,
    final String? freeFirstGrowthEligibleItemId,
    final bool? legacyFreeFirst,
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
  bool get freeFirstGrowthEverConsumed;
  @override
  String? get freeFirstGrowthEligibleItemId;
  @override
  bool? get legacyFreeFirst;

  /// Create a copy of GardenPersistedPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GardenPersistedPayloadImplCopyWith<_$GardenPersistedPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
