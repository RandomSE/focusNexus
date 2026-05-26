// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'garden_persisted_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GardenPersistedPayloadImpl _$$GardenPersistedPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$GardenPersistedPayloadImpl(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => GardenItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GardenItem>[],
  decor:
      (json['decor'] as List<dynamic>?)
          ?.map((e) => DecorItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DecorItem>[],
  decorStash:
      json['decorStash'] == null
          ? const <String, int>{}
          : const DecorStashJsonConverter().fromJson(json['decorStash']),
  freeFirstGrowthEverConsumed:
      json['freeFirstGrowthEverConsumed'] as bool? ?? false,
  freeFirstGrowthEligibleItemId:
      json['freeFirstGrowthEligibleItemId'] as String?,
  legacyFreeFirst: json['legacyFreeFirst'] as bool?,
);

Map<String, dynamic> _$$GardenPersistedPayloadImplToJson(
  _$GardenPersistedPayloadImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'decor': instance.decor,
  'decorStash': const DecorStashJsonConverter().toJson(instance.decorStash),
  'freeFirstGrowthEverConsumed': instance.freeFirstGrowthEverConsumed,
  'freeFirstGrowthEligibleItemId': instance.freeFirstGrowthEligibleItemId,
  'legacyFreeFirst': instance.legacyFreeFirst,
};
