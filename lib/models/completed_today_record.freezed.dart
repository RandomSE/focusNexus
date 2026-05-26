// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completed_today_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CompletedTodayRecord {
  String get dateKey => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  /// Create a copy of CompletedTodayRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompletedTodayRecordCopyWith<CompletedTodayRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompletedTodayRecordCopyWith<$Res> {
  factory $CompletedTodayRecordCopyWith(
    CompletedTodayRecord value,
    $Res Function(CompletedTodayRecord) then,
  ) = _$CompletedTodayRecordCopyWithImpl<$Res, CompletedTodayRecord>;
  @useResult
  $Res call({String dateKey, int count});
}

/// @nodoc
class _$CompletedTodayRecordCopyWithImpl<
  $Res,
  $Val extends CompletedTodayRecord
>
    implements $CompletedTodayRecordCopyWith<$Res> {
  _$CompletedTodayRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompletedTodayRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dateKey = null, Object? count = null}) {
    return _then(
      _value.copyWith(
            dateKey:
                null == dateKey
                    ? _value.dateKey
                    : dateKey // ignore: cast_nullable_to_non_nullable
                        as String,
            count:
                null == count
                    ? _value.count
                    : count // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompletedTodayRecordImplCopyWith<$Res>
    implements $CompletedTodayRecordCopyWith<$Res> {
  factory _$$CompletedTodayRecordImplCopyWith(
    _$CompletedTodayRecordImpl value,
    $Res Function(_$CompletedTodayRecordImpl) then,
  ) = __$$CompletedTodayRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String dateKey, int count});
}

/// @nodoc
class __$$CompletedTodayRecordImplCopyWithImpl<$Res>
    extends _$CompletedTodayRecordCopyWithImpl<$Res, _$CompletedTodayRecordImpl>
    implements _$$CompletedTodayRecordImplCopyWith<$Res> {
  __$$CompletedTodayRecordImplCopyWithImpl(
    _$CompletedTodayRecordImpl _value,
    $Res Function(_$CompletedTodayRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompletedTodayRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dateKey = null, Object? count = null}) {
    return _then(
      _$CompletedTodayRecordImpl(
        dateKey:
            null == dateKey
                ? _value.dateKey
                : dateKey // ignore: cast_nullable_to_non_nullable
                    as String,
        count:
            null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

class _$CompletedTodayRecordImpl extends _CompletedTodayRecord {
  const _$CompletedTodayRecordImpl({required this.dateKey, this.count = 1})
    : super._();

  @override
  final String dateKey;
  @override
  @JsonKey()
  final int count;

  @override
  String toString() {
    return 'CompletedTodayRecord(dateKey: $dateKey, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedTodayRecordImpl &&
            (identical(other.dateKey, dateKey) || other.dateKey == dateKey) &&
            (identical(other.count, count) || other.count == count));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dateKey, count);

  /// Create a copy of CompletedTodayRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletedTodayRecordImplCopyWith<_$CompletedTodayRecordImpl>
  get copyWith =>
      __$$CompletedTodayRecordImplCopyWithImpl<_$CompletedTodayRecordImpl>(
        this,
        _$identity,
      );
}

abstract class _CompletedTodayRecord extends CompletedTodayRecord {
  const factory _CompletedTodayRecord({
    required final String dateKey,
    final int count,
  }) = _$CompletedTodayRecordImpl;
  const _CompletedTodayRecord._() : super._();

  @override
  String get dateKey;
  @override
  int get count;

  /// Create a copy of CompletedTodayRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletedTodayRecordImplCopyWith<_$CompletedTodayRecordImpl>
  get copyWith => throw _privateConstructorUsedError;
}
