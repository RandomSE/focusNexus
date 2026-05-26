// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_op_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GardenOpResult {
  GardenState? get state => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GardenOpResultCopyWith<GardenOpResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GardenOpResultCopyWith<$Res> {
  factory $GardenOpResultCopyWith(
    GardenOpResult value,
    $Res Function(GardenOpResult) then,
  ) = _$GardenOpResultCopyWithImpl<$Res, GardenOpResult>;
  @useResult
  $Res call({GardenState? state, String? error});

  $GardenStateCopyWith<$Res>? get state;
}

/// @nodoc
class _$GardenOpResultCopyWithImpl<$Res, $Val extends GardenOpResult>
    implements $GardenOpResultCopyWith<$Res> {
  _$GardenOpResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? state = freezed, Object? error = freezed}) {
    return _then(
      _value.copyWith(
            state:
                freezed == state
                    ? _value.state
                    : state // ignore: cast_nullable_to_non_nullable
                        as GardenState?,
            error:
                freezed == error
                    ? _value.error
                    : error // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GardenStateCopyWith<$Res>? get state {
    if (_value.state == null) {
      return null;
    }

    return $GardenStateCopyWith<$Res>(_value.state!, (value) {
      return _then(_value.copyWith(state: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GardenOpResultImplCopyWith<$Res>
    implements $GardenOpResultCopyWith<$Res> {
  factory _$$GardenOpResultImplCopyWith(
    _$GardenOpResultImpl value,
    $Res Function(_$GardenOpResultImpl) then,
  ) = __$$GardenOpResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GardenState? state, String? error});

  @override
  $GardenStateCopyWith<$Res>? get state;
}

/// @nodoc
class __$$GardenOpResultImplCopyWithImpl<$Res>
    extends _$GardenOpResultCopyWithImpl<$Res, _$GardenOpResultImpl>
    implements _$$GardenOpResultImplCopyWith<$Res> {
  __$$GardenOpResultImplCopyWithImpl(
    _$GardenOpResultImpl _value,
    $Res Function(_$GardenOpResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? state = freezed, Object? error = freezed}) {
    return _then(
      _$GardenOpResultImpl(
        state:
            freezed == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                    as GardenState?,
        error:
            freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$GardenOpResultImpl extends _GardenOpResult {
  const _$GardenOpResultImpl({this.state, this.error}) : super._();

  @override
  final GardenState? state;
  @override
  final String? error;

  @override
  String toString() {
    return 'GardenOpResult(state: $state, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GardenOpResultImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, state, error);

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GardenOpResultImplCopyWith<_$GardenOpResultImpl> get copyWith =>
      __$$GardenOpResultImplCopyWithImpl<_$GardenOpResultImpl>(
        this,
        _$identity,
      );
}

abstract class _GardenOpResult extends GardenOpResult {
  const factory _GardenOpResult({
    final GardenState? state,
    final String? error,
  }) = _$GardenOpResultImpl;
  const _GardenOpResult._() : super._();

  @override
  GardenState? get state;
  @override
  String? get error;

  /// Create a copy of GardenOpResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GardenOpResultImplCopyWith<_$GardenOpResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
