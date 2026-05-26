// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'garden_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GardenItemImpl _$$GardenItemImplFromJson(Map<String, dynamic> json) =>
    _$GardenItemImpl(
      id: json['id'] as String,
      themeId: const VisualThemeIdJsonConverter().fromJson(
        json['themeId'] as String,
      ),
      stageIndex: (json['stageIndex'] as num?)?.toInt() ?? 0,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
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
      regrowthDiscountActive: json['regrowthDiscountActive'] as bool? ?? false,
    );

Map<String, dynamic> _$$GardenItemImplToJson(_$GardenItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'themeId': const VisualThemeIdJsonConverter().toJson(instance.themeId),
      'stageIndex': instance.stageIndex,
      'positionX': instance.positionX,
      'positionY': instance.positionY,
      'nextAdvanceAllowedAt': instance.nextAdvanceAllowedAt?.toIso8601String(),
      'pendingSkipWaitCost': instance.pendingSkipWaitCost,
      'mutation': _$JsonConverterToJson<String, MutationKind>(
        instance.mutation,
        const MutationKindJsonConverter().toJson,
      ),
      'awaitingRegrowthForRemutation': instance.awaitingRegrowthForRemutation,
      'mutationRolledThisCycle': instance.mutationRolledThisCycle,
      'regrowthDiscountActive': instance.regrowthDiscountActive,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
