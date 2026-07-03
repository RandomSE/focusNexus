// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cherry_blossom_tree_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CherryBlossomTreeStateImpl _$$CherryBlossomTreeStateImplFromJson(
  Map<String, dynamic> json,
) => _$CherryBlossomTreeStateImpl(
  stageIndex: (json['stageIndex'] as num?)?.toInt() ?? 0,
  growthStepsInStage: (json['growthStepsInStage'] as num?)?.toInt() ?? 0,
  prestigePath: $enumDecodeNullable(
    _$CherryBlossomPrestigePathEnumMap,
    json['prestigePath'],
  ),
  totalTreePointsInvested:
      (json['totalTreePointsInvested'] as num?)?.toInt() ?? 0,
  bonsaiFilledSlots: json['bonsaiFilledSlots'] == null
      ? const <int, int>{}
      : _bonsaiFromJson(json['bonsaiFilledSlots'] as Map<String, dynamic>?),
  customBonsaiGardenSlots: json['customBonsaiGardenSlots'] == null
      ? const <String?>[]
      : _gardenSlotsFromJson(json['customBonsaiGardenSlots'] as List?),
  peaceBonsaiCount: (json['peaceBonsaiCount'] as num?)?.toInt() ?? 0,
  powerBonsaiCount: (json['powerBonsaiCount'] as num?)?.toInt() ?? 0,
  unlockedFinalePaths:
      (json['unlockedFinalePaths'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$CherryBlossomPrestigePathEnumMap, e))
          .toList() ??
      const <CherryBlossomPrestigePath>[],
  highestStageUnlocked: (json['highestStageUnlocked'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CherryBlossomTreeStateImplToJson(
  _$CherryBlossomTreeStateImpl instance,
) => <String, dynamic>{
  'stageIndex': instance.stageIndex,
  'growthStepsInStage': instance.growthStepsInStage,
  'prestigePath': _$CherryBlossomPrestigePathEnumMap[instance.prestigePath],
  'totalTreePointsInvested': instance.totalTreePointsInvested,
  'bonsaiFilledSlots': _bonsaiToJson(instance.bonsaiFilledSlots),
  'customBonsaiGardenSlots': _gardenSlotsToJson(
    instance.customBonsaiGardenSlots,
  ),
  'peaceBonsaiCount': instance.peaceBonsaiCount,
  'powerBonsaiCount': instance.powerBonsaiCount,
  'unlockedFinalePaths': instance.unlockedFinalePaths
      .map((e) => _$CherryBlossomPrestigePathEnumMap[e]!)
      .toList(),
  'highestStageUnlocked': instance.highestStageUnlocked,
};

const _$CherryBlossomPrestigePathEnumMap = {
  CherryBlossomPrestigePath.peace: 'peace',
  CherryBlossomPrestigePath.power: 'power',
};
