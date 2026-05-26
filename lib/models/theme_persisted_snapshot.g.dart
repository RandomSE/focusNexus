// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_persisted_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThemePersistedSnapshotImpl _$$ThemePersistedSnapshotImplFromJson(
  Map<String, dynamic> json,
) => _$ThemePersistedSnapshotImpl(
  isDark: json['isDark'] as bool? ?? false,
  primaryColorArgb: (json['primaryColorArgb'] as num?)?.toInt() ?? 0xFF000000,
  secondaryColorArgb:
      (json['secondaryColorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
  userFontSize: (json['userFontSize'] as num?)?.toDouble() ?? 14.0,
  useDyslexiaFont: json['useDyslexiaFont'] as bool? ?? false,
);

Map<String, dynamic> _$$ThemePersistedSnapshotImplToJson(
  _$ThemePersistedSnapshotImpl instance,
) => <String, dynamic>{
  'isDark': instance.isDark,
  'primaryColorArgb': instance.primaryColorArgb,
  'secondaryColorArgb': instance.secondaryColorArgb,
  'userFontSize': instance.userFontSize,
  'useDyslexiaFont': instance.useDyslexiaFont,
};
