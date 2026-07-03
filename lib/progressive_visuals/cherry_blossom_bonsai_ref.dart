import 'cherry_blossom_prestige_path.dart';
import 'cherry_blossom_stage_catalog.dart';
import 'cherry_blossom_tree_state.dart';

/// One placeable bonsai = one stage (or finale path), not per-mini-tree index.
class CherryBlossomBonsaiRef {
  const CherryBlossomBonsaiRef({
    required this.stageIndex,
    this.prestigePath,
  });

  final int stageIndex;
  final CherryBlossomPrestigePath? prestigePath;

  static const gardenSlotCount = 25;
  static const gridDimension = 5;

  String get storageKey {
    if (stageIndex == CherryBlossomStageCatalog.finaleStage) {
      final path = prestigePath ?? CherryBlossomPrestigePath.peace;
      return 'stage_7_${path.name}';
    }
    return 'stage_$stageIndex';
  }

  static CherryBlossomBonsaiRef? parse(String? key) {
    if (key == null || key.isEmpty) return null;

    final legacyFinale = RegExp(r'^s7_(peace|power)_i\d+$').firstMatch(key);
    if (legacyFinale != null) {
      return CherryBlossomBonsaiRef(
        stageIndex: CherryBlossomStageCatalog.finaleStage,
        prestigePath: legacyFinale.group(1) == 'power'
            ? CherryBlossomPrestigePath.power
            : CherryBlossomPrestigePath.peace,
      );
    }
    final legacy = RegExp(r'^s(\d+)_i\d+$').firstMatch(key);
    if (legacy != null) {
      return CherryBlossomBonsaiRef(stageIndex: int.parse(legacy.group(1)!));
    }

    final finale = RegExp(r'^stage_7_(peace|power)$').firstMatch(key);
    if (finale != null) {
      return CherryBlossomBonsaiRef(
        stageIndex: CherryBlossomStageCatalog.finaleStage,
        prestigePath: finale.group(1) == 'power'
            ? CherryBlossomPrestigePath.power
            : CherryBlossomPrestigePath.peace,
      );
    }
    final normal = RegExp(r'^stage_(\d+)$').firstMatch(key);
    if (normal == null) return null;
    return CherryBlossomBonsaiRef(stageIndex: int.parse(normal.group(1)!));
  }

  String get assetPath => CherryBlossomStageCatalog.assetPathFor(
        stageIndex: stageIndex,
        prestigePath: prestigePath,
      );

  String get stageLabel => CherryBlossomStageCatalog.displayNameFor(
        stageIndex: stageIndex,
        prestigePath: prestigePath,
      );

  int countFor(CherryBlossomTreeState tree) {
    if (stageIndex == CherryBlossomStageCatalog.finaleStage) {
      return switch (prestigePath) {
        CherryBlossomPrestigePath.peace => tree.peaceBonsaiCount,
        CherryBlossomPrestigePath.power => tree.powerBonsaiCount,
        null => 0,
      };
    }
    return tree.bonsaiCountForStage(stageIndex);
  }

  static List<String> unlockedStageKeys(CherryBlossomTreeState tree) {
    final keys = <String>[];
    for (var stage = 0; stage <= CherryBlossomStageCatalog.maxPlayableStage; stage++) {
      if (tree.bonsaiCountForStage(stage) > 0) {
        keys.add(CherryBlossomBonsaiRef(stageIndex: stage).storageKey);
      }
    }
    if (tree.peaceBonsaiCount > 0) {
      keys.add(
        const CherryBlossomBonsaiRef(
          stageIndex: CherryBlossomStageCatalog.finaleStage,
          prestigePath: CherryBlossomPrestigePath.peace,
        ).storageKey,
      );
    }
    if (tree.powerBonsaiCount > 0) {
      keys.add(
        const CherryBlossomBonsaiRef(
          stageIndex: CherryBlossomStageCatalog.finaleStage,
          prestigePath: CherryBlossomPrestigePath.power,
        ).storageKey,
      );
    }
    return keys;
  }

  static List<String?> normalizeGardenSlots(List<String?> raw) {
    final out = List<String?>.filled(gardenSlotCount, null);
    for (var i = 0; i < gardenSlotCount && i < raw.length; i++) {
      final parsed = parse(raw[i]);
      out[i] = parsed?.storageKey;
    }
    return out;
  }
}
