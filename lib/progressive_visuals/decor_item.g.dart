// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decor_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DecorItemImpl _$$DecorItemImplFromJson(Map<String, dynamic> json) =>
    _$DecorItemImpl(
      id: json['id'] as String,
      themeId: const VisualThemeIdJsonConverter().fromJson(
        json['themeId'] as String,
      ),
      kind: json['kind'] as String,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
      stageIndex: (json['stageIndex'] as num?)?.toInt() ?? 0,
      nextAdvanceAllowedAt:
          json['nextAdvanceAllowedAt'] == null
              ? null
              : DateTime.parse(json['nextAdvanceAllowedAt'] as String),
      pendingSkipWaitCost: (json['pendingSkipWaitCost'] as num?)?.toInt(),
      mutation: _$JsonConverterFromJson<String, MutationKind>(
        json['mutation'],
        const MutationKindJsonConverter().fromJson,
      ),
      awaitingRegrowthForRemutation:
          json['awaitingRegrowthForRemutation'] as bool? ?? false,
      mutationRolledThisCycle:
          json['mutationRolledThisCycle'] as bool? ?? false,
    );

Map<String, dynamic> _$$DecorItemImplToJson(_$DecorItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'themeId': const VisualThemeIdJsonConverter().toJson(instance.themeId),
      'kind': instance.kind,
      'positionX': instance.positionX,
      'positionY': instance.positionY,
      'stageIndex': instance.stageIndex,
      'nextAdvanceAllowedAt': instance.nextAdvanceAllowedAt?.toIso8601String(),
      'pendingSkipWaitCost': instance.pendingSkipWaitCost,
      'mutation': _$JsonConverterToJson<String, MutationKind>(
        instance.mutation,
        const MutationKindJsonConverter().toJson,
      ),
      'awaitingRegrowthForRemutation': instance.awaitingRegrowthForRemutation,
      'mutationRolledThisCycle': instance.mutationRolledThisCycle,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
