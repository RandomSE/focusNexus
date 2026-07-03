import 'package:freezed_annotation/freezed_annotation.dart';

import 'cherry_blossom_bonsai_ref.dart';
import 'cherry_blossom_prestige_path.dart';
import 'cherry_blossom_stage_catalog.dart';

part 'cherry_blossom_tree_state.freezed.dart';
part 'cherry_blossom_tree_state.g.dart';

List<String?> _gardenSlotsFromJson(List<dynamic>? json) {
  if (json == null) return CherryBlossomBonsaiRef.normalizeGardenSlots(const []);
  return CherryBlossomBonsaiRef.normalizeGardenSlots(
    json.map((e) => e as String?).toList(),
  );
}

List<String?> _gardenSlotsToJson(List<String?> slots) => slots;

Map<int, int> _bonsaiFromJson(Map<String, dynamic>? json) {
  if (json == null) return {};
  return json.map((key, value) => MapEntry(int.parse(key), (value as num).toInt()));
}

Map<String, dynamic> _bonsaiToJson(Map<int, int> map) =>
    map.map((key, value) => MapEntry('$key', value));

/// Persisted cherry blossom tree growth (image-based stages).
@freezed
class CherryBlossomTreeState with _$CherryBlossomTreeState {
  const CherryBlossomTreeState._();

  const factory CherryBlossomTreeState({
    @Default(0) int stageIndex,
    @Default(0) int growthStepsInStage,
    CherryBlossomPrestigePath? prestigePath,
    @Default(0) int totalTreePointsInvested,
    @JsonKey(fromJson: _bonsaiFromJson, toJson: _bonsaiToJson)
    @Default(<int, int>{})
    Map<int, int> bonsaiFilledSlots,
    @JsonKey(fromJson: _gardenSlotsFromJson, toJson: _gardenSlotsToJson)
    @Default(<String?>[])
    List<String?> customBonsaiGardenSlots,
    @Default(0) int peaceBonsaiCount,
    @Default(0) int powerBonsaiCount,
    @Default(<CherryBlossomPrestigePath>[])
    List<CherryBlossomPrestigePath> unlockedFinalePaths,
    @Default(0) int highestStageUnlocked,
  }) = _CherryBlossomTreeState;

  factory CherryBlossomTreeState.fromJson(Map<String, dynamic> json) =>
      _$CherryBlossomTreeStateFromJson(_normalizeJson(json));

  factory CherryBlossomTreeState.initial() => const CherryBlossomTreeState();

  CherryBlossomTreeState normalized() {
    final stage = stageIndex.clamp(0, CherryBlossomStageCatalog.finaleStage);
    final maxSteps = CherryBlossomStageCatalog.maxGrowthStepsForStage(stage);
    var steps = growthStepsInStage.clamp(0, maxSteps);
    if (stage != CherryBlossomStageCatalog.finaleStage &&
        steps >= CherryBlossomStageCatalog.levelsPerStage) {
      steps = CherryBlossomStageCatalog.levelsPerStage - 1;
    }
    final unlocked = highestStageUnlocked.clamp(0, stage);
    final invested = CherryBlossomStageCatalog.totalInvestedThrough(
      stageIndex: stage,
      growthStepsInStage: steps,
    );
    final gardenSlots =
        CherryBlossomBonsaiRef.normalizeGardenSlots(customBonsaiGardenSlots);
    final paths = List<CherryBlossomPrestigePath>.from(unlockedFinalePaths);
    if (stage == CherryBlossomStageCatalog.finaleStage && prestigePath != null) {
      if (!paths.contains(prestigePath)) {
        paths.add(prestigePath!);
      }
    }
    return copyWith(
      stageIndex: stage,
      growthStepsInStage: steps,
      totalTreePointsInvested: invested,
      highestStageUnlocked: unlocked < stage ? stage : unlocked,
      customBonsaiGardenSlots: gardenSlots,
      unlockedFinalePaths: paths,
      prestigePath: stage == CherryBlossomStageCatalog.finaleStage
          ? prestigePath
          : null,
    );
  }

  int get displayLevel => CherryBlossomStageCatalog.displayLevel(
        stageIndex: stageIndex,
        growthStepsInStage: growthStepsInStage,
      );

  int get levelCap => CherryBlossomStageCatalog.levelCapForStage(stageIndex);

  String get stageLabel => CherryBlossomStageCatalog.displayNameFor(
        stageIndex: stageIndex,
        prestigePath: prestigePath,
      );

  String get hudLabel => '$displayLevel/$levelCap · $stageLabel';

  String get assetPath => CherryBlossomStageCatalog.assetPathFor(
        stageIndex: stageIndex,
        prestigePath: prestigePath,
      );

  double get treeScale => CherryBlossomStageCatalog.scaleFor(
        stageIndex: stageIndex,
        growthStepsInStage: growthStepsInStage,
      );

  bool get isFinale => stageIndex == CherryBlossomStageCatalog.finaleStage;

  bool get canGrowMore =>
      !isFinale &&
      growthStepsInStage < CherryBlossomStageCatalog.levelsPerStage - 1;

  bool get canPrestige =>
      !isFinale &&
      growthStepsInStage >= CherryBlossomStageCatalog.levelsPerStage - 1;

  int bonsaiCountForStage(int stage) => bonsaiFilledSlots[stage] ?? 0;

  List<String> get unlockedBonsaiKeys =>
      CherryBlossomBonsaiRef.unlockedStageKeys(this);

  bool get hasUnlockedPath =>
      unlockedFinalePaths.length >= 2 ||
      (peaceBonsaiCount > 0 && powerBonsaiCount > 0);

  bool isFinalePathUnlocked(CherryBlossomPrestigePath path) =>
      unlockedFinalePaths.contains(path);

  List<String?> get gardenSlots =>
      CherryBlossomBonsaiRef.normalizeGardenSlots(customBonsaiGardenSlots);

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    if (_isLegacyCherryJson(json)) {
      return const {};
    }
    return json;
  }

  static bool _isLegacyCherryJson(Map<String, dynamic> json) {
    return json.containsKey('growthStepIndex') ||
        json.containsKey('branchSlots') ||
        json.containsKey('leafSlots') ||
        json.containsKey('undoStack') ||
        json.containsKey('baseGrowthLevel') ||
        json.containsKey('trunkBaseTintArgb') ||
        !json.containsKey('stageIndex');
  }
}
