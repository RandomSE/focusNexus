import 'package:flutter/material.dart';

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

const List<DecorCatalogEntry> _zenDecorCatalog = [
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

List<DecorCatalogEntry> decorCatalogFor(VisualThemeId theme) {
  return switch (theme) {
    VisualThemeId.zenGarden => _zenDecorCatalog,
    _ => const [],
  };
}

DecorCatalogEntry? decorEntryByKind(String kind) {
  for (final t in VisualThemeId.values) {
    for (final e in decorCatalogFor(t)) {
      if (e.id == kind) return e;
    }
  }
  return null;
}

int? decorPrice(String kind) => decorEntryByKind(kind)?.pointCost;
