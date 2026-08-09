import 'package:flutter/material.dart';

import 'cherry_blossom_stage_catalog.dart';
import 'visual_theme_id.dart';

/// Shared pattern: each theme adds entries; UIs and saves use [id] strings only.
class DecorCatalogEntry {
  const DecorCatalogEntry({
    required this.id,
    required this.pointCost,
    required this.label,
    required this.icon,
    required this.themeId,
  });

  final String id;
  final int pointCost;
  final String label;
  final IconData icon;
  final VisualThemeId themeId;
}

/// Zen garden placeable granted by Path of Peace claim (A1d).
const String zenPeaceBonsaiKind = 'zen.peace_bonsai';

/// Zen garden placeable granted by Path of Power claim (A1d).
const String zenPowerBonsaiKind = 'zen.power_bonsai';

/// Paid inverted-color mutation for path claim bonsai (per item).
const int zenPathBonsaiMutationPointCost = 100000;

/// Display names for cherry stages 0-6 (achievement + decor labels).
const List<String> zenCherryStageBonsaiNames = [
  'Bare Beginning',
  'Early Spring Morning',
  'Midday Spring',
  'Golden Afternoon',
  'Deep Twilight',
  'Aurora Veil',
  'Living Canopy',
];

/// Kind id for a zen placeable bonsai matching cherry stage [stageIndex] (0-6).
String zenStageBonsaiKind(int stageIndex) {
  assert(
    stageIndex >= 0 && stageIndex < CherryBlossomStageCatalog.stageCount,
    'stageIndex out of range',
  );
  return 'zen.stage_${stageIndex}_bonsai';
}

int? zenStageBonsaiStageIndex(String kind) {
  final match = RegExp(r'^zen\.stage_(\d+)_bonsai$').firstMatch(kind);
  if (match == null) return null;
  final stage = int.tryParse(match.group(1)!);
  if (stage == null ||
      stage < 0 ||
      stage >= CherryBlossomStageCatalog.stageCount) {
    return null;
  }
  return stage;
}

bool isZenPathClaimBonsaiKind(String kind) =>
    kind == zenPeaceBonsaiKind || kind == zenPowerBonsaiKind;

bool isZenStageBonsaiKind(String kind) => zenStageBonsaiStageIndex(kind) != null;

/// Achievement-granted zen bonsai: sell-locked, place/inventory OK, no shop.
bool isZenLockedBonsaiKind(String kind) =>
    isZenPathClaimBonsaiKind(kind) || isZenStageBonsaiKind(kind);

/// Bonsai garden storage key for achievement zen pots.
String? zenAchievementBonsaiGardenKey(String kind) {
  if (kind == zenPeaceBonsaiKind) return 'stage_7_peace';
  if (kind == zenPowerBonsaiKind) return 'stage_7_power';
  final stage = zenStageBonsaiStageIndex(kind);
  if (stage == null) return null;
  return 'stage_$stage';
}

/// Prefer [zenAchievementBonsaiGardenKey]; kept for path-only call sites.
String? zenPathClaimBonsaiGardenKey(String kind) {
  if (!isZenPathClaimBonsaiKind(kind)) return null;
  return zenAchievementBonsaiGardenKey(kind);
}

String zenStageBonsaiRewardText(int stageIndex) {
  final name = zenCherryStageBonsaiNames[stageIndex];
  return 'Zen Garden $name bonsai +1';
}

const List<DecorCatalogEntry> _zenShopDecorCatalog = [
  DecorCatalogEntry(
    id: 'zen.stone_path',
    pointCost: 60,
    label: 'Stepping stones',
    icon: Icons.grid_3x3_rounded,
    themeId: VisualThemeId.zenGarden,
  ),
  DecorCatalogEntry(
    id: 'zen.koi_pond',
    pointCost: 140,
    label: 'Koi pond',
    icon: Icons.waves_rounded,
    themeId: VisualThemeId.zenGarden,
  ),
  DecorCatalogEntry(
    id: 'zen.stone_lantern',
    pointCost: 90,
    label: 'Stone lantern',
    icon: Icons.nights_stay_outlined,
    themeId: VisualThemeId.zenGarden,
  ),
  DecorCatalogEntry(
    id: 'zen.wood_bench',
    pointCost: 80,
    label: 'Wood bench',
    icon: Icons.weekend_outlined,
    themeId: VisualThemeId.zenGarden,
  ),
  DecorCatalogEntry(
    id: 'zen.bamboo_fence',
    pointCost: 70,
    label: 'Bamboo fence',
    icon: Icons.view_week_outlined,
    themeId: VisualThemeId.zenGarden,
  ),
  DecorCatalogEntry(
    id: 'zen.moss_rock',
    pointCost: 50,
    label: 'Moss rock',
    icon: Icons.landscape_outlined,
    themeId: VisualThemeId.zenGarden,
  ),
];

/// Full zen decor catalog including achievement-only locked bonsai.
List<DecorCatalogEntry> get _zenDecorCatalog => [
      ..._zenShopDecorCatalog,
      const DecorCatalogEntry(
        id: zenPeaceBonsaiKind,
        pointCost: 0,
        label: 'Peace bonsai',
        icon: Icons.park_outlined,
        themeId: VisualThemeId.zenGarden,
      ),
      const DecorCatalogEntry(
        id: zenPowerBonsaiKind,
        pointCost: 0,
        label: 'Power bonsai',
        icon: Icons.local_florist_outlined,
        themeId: VisualThemeId.zenGarden,
      ),
      for (var i = 0; i < zenCherryStageBonsaiNames.length; i++)
        DecorCatalogEntry(
          id: zenStageBonsaiKind(i),
          pointCost: 0,
          label: '${zenCherryStageBonsaiNames[i]} bonsai',
          icon: Icons.spa_outlined,
          themeId: VisualThemeId.zenGarden,
        ),
    ];

List<DecorCatalogEntry> decorCatalogFor(VisualThemeId theme) {
  if (theme == VisualThemeId.zenGarden) {
    return _zenDecorCatalog;
  }
  return const [];
}

/// Shop listings exclude achievement-only locked bonsai kinds.
List<DecorCatalogEntry> zenDecorShopCatalog() => _zenShopDecorCatalog;

DecorCatalogEntry? decorEntryByKind(String kind) {
  for (final t in VisualThemeId.values) {
    for (final e in decorCatalogFor(t)) {
      if (e.id == kind) return e;
    }
  }
  return null;
}

int? decorPrice(String kind) => decorEntryByKind(kind)?.pointCost;
