// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AchievementImpl _$$AchievementImplFromJson(Map<String, dynamic> json) =>
    _$AchievementImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      reward: json['reward'] as String,
      task: json['task'] as String,
      dateCompleted:
          json['dateCompleted'] == null
              ? null
              : DateTime.parse(json['dateCompleted'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isSecret: json['isSecret'] as bool? ?? true,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$AchievementImplToJson(_$AchievementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'reward': instance.reward,
      'task': instance.task,
      'dateCompleted': instance.dateCompleted?.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'isSecret': instance.isSecret,
      'progress': instance.progress,
    };
