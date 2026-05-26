// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Achievement _$AchievementFromJson(Map<String, dynamic> json) {
  return _Achievement.fromJson(json);
}

/// @nodoc
mixin _$Achievement {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get reward => throw _privateConstructorUsedError;
  String get task => throw _privateConstructorUsedError;
  DateTime? get dateCompleted => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  bool get isSecret => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;

  /// Serializes this Achievement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementCopyWith<Achievement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementCopyWith<$Res> {
  factory $AchievementCopyWith(
    Achievement value,
    $Res Function(Achievement) then,
  ) = _$AchievementCopyWithImpl<$Res, Achievement>;
  @useResult
  $Res call({
    String id,
    String title,
    String reward,
    String task,
    DateTime? dateCompleted,
    bool isCompleted,
    bool isSecret,
    double progress,
  });
}

/// @nodoc
class _$AchievementCopyWithImpl<$Res, $Val extends Achievement>
    implements $AchievementCopyWith<$Res> {
  _$AchievementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? reward = null,
    Object? task = null,
    Object? dateCompleted = freezed,
    Object? isCompleted = null,
    Object? isSecret = null,
    Object? progress = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            reward:
                null == reward
                    ? _value.reward
                    : reward // ignore: cast_nullable_to_non_nullable
                        as String,
            task:
                null == task
                    ? _value.task
                    : task // ignore: cast_nullable_to_non_nullable
                        as String,
            dateCompleted:
                freezed == dateCompleted
                    ? _value.dateCompleted
                    : dateCompleted // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            isCompleted:
                null == isCompleted
                    ? _value.isCompleted
                    : isCompleted // ignore: cast_nullable_to_non_nullable
                        as bool,
            isSecret:
                null == isSecret
                    ? _value.isSecret
                    : isSecret // ignore: cast_nullable_to_non_nullable
                        as bool,
            progress:
                null == progress
                    ? _value.progress
                    : progress // ignore: cast_nullable_to_non_nullable
                        as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementImplCopyWith<$Res>
    implements $AchievementCopyWith<$Res> {
  factory _$$AchievementImplCopyWith(
    _$AchievementImpl value,
    $Res Function(_$AchievementImpl) then,
  ) = __$$AchievementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String reward,
    String task,
    DateTime? dateCompleted,
    bool isCompleted,
    bool isSecret,
    double progress,
  });
}

/// @nodoc
class __$$AchievementImplCopyWithImpl<$Res>
    extends _$AchievementCopyWithImpl<$Res, _$AchievementImpl>
    implements _$$AchievementImplCopyWith<$Res> {
  __$$AchievementImplCopyWithImpl(
    _$AchievementImpl _value,
    $Res Function(_$AchievementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? reward = null,
    Object? task = null,
    Object? dateCompleted = freezed,
    Object? isCompleted = null,
    Object? isSecret = null,
    Object? progress = null,
  }) {
    return _then(
      _$AchievementImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        reward:
            null == reward
                ? _value.reward
                : reward // ignore: cast_nullable_to_non_nullable
                    as String,
        task:
            null == task
                ? _value.task
                : task // ignore: cast_nullable_to_non_nullable
                    as String,
        dateCompleted:
            freezed == dateCompleted
                ? _value.dateCompleted
                : dateCompleted // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        isCompleted:
            null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                    as bool,
        isSecret:
            null == isSecret
                ? _value.isSecret
                : isSecret // ignore: cast_nullable_to_non_nullable
                    as bool,
        progress:
            null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                    as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementImpl extends _Achievement {
  const _$AchievementImpl({
    required this.id,
    required this.title,
    required this.reward,
    required this.task,
    this.dateCompleted,
    this.isCompleted = false,
    this.isSecret = true,
    this.progress = 0.0,
  }) : super._();

  factory _$AchievementImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String reward;
  @override
  final String task;
  @override
  final DateTime? dateCompleted;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  @JsonKey()
  final bool isSecret;
  @override
  @JsonKey()
  final double progress;

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, reward: $reward, task: $task, dateCompleted: $dateCompleted, isCompleted: $isCompleted, isSecret: $isSecret, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.reward, reward) || other.reward == reward) &&
            (identical(other.task, task) || other.task == task) &&
            (identical(other.dateCompleted, dateCompleted) ||
                other.dateCompleted == dateCompleted) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.isSecret, isSecret) ||
                other.isSecret == isSecret) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    reward,
    task,
    dateCompleted,
    isCompleted,
    isSecret,
    progress,
  );

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementImplCopyWith<_$AchievementImpl> get copyWith =>
      __$$AchievementImplCopyWithImpl<_$AchievementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementImplToJson(this);
  }
}

abstract class _Achievement extends Achievement {
  const factory _Achievement({
    required final String id,
    required final String title,
    required final String reward,
    required final String task,
    final DateTime? dateCompleted,
    final bool isCompleted,
    final bool isSecret,
    final double progress,
  }) = _$AchievementImpl;
  const _Achievement._() : super._();

  factory _Achievement.fromJson(Map<String, dynamic> json) =
      _$AchievementImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get reward;
  @override
  String get task;
  @override
  DateTime? get dateCompleted;
  @override
  bool get isCompleted;
  @override
  bool get isSecret;
  @override
  double get progress;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementImplCopyWith<_$AchievementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
