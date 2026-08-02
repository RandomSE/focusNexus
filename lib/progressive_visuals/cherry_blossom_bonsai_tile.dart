import 'package:flutter/material.dart';

import 'cherry_blossom_bonsai_ref.dart';
import 'cherry_blossom_falling_petals.dart';
import 'cherry_blossom_living_canopy_background.dart';
import 'cherry_blossom_multiply_blend.dart';
import 'cherry_blossom_peace_petals.dart';
import 'cherry_blossom_power_petals.dart';
import 'cherry_blossom_prestige_path.dart';
import 'cherry_blossom_stage_catalog.dart';
import 'cherry_blossom_stage_six_leaves.dart';
import 'cherry_blossom_tree_background.dart';

/// Bonsai cell: stage sky + true-alpha tree for 0-5; full-bleed for 6-7.
/// Petals stay clipped to the pot. Quantity badges are opt-in via [countLabel].
class CherryBlossomBonsaiTile extends StatelessWidget {
  const CherryBlossomBonsaiTile({
    super.key,
    required this.bonsaiKey,
    this.onTap,
    this.selected = false,
    this.empty = false,
    this.countLabel,
    this.animateEffects = true,
  });

  final String? bonsaiKey;
  final VoidCallback? onTap;
  final bool selected;
  final bool empty;
  final String? countLabel;
  final bool animateEffects;

  @override
  Widget build(BuildContext context) {
    final ref = CherryBlossomBonsaiRef.parse(bonsaiKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cellSize = Size(w, h);
        final stage = ref?.stageIndex ?? 0;
        final fillsSlot =
            ref != null && CherryBlossomStageCatalog.bonsaiFillsSlot(stage);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: empty
                    ? const Color(0xFFE4EDE4).withValues(alpha: 0.55)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.amber : const Color(0xFFB8C8B8),
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: empty || ref == null
                    ? null
                    : fillsSlot
                        ? _buildFullSlotTree(ref, cellSize)
                        : _buildGroundedTree(ref, cellSize),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullSlotTree(CherryBlossomBonsaiRef ref, Size cellSize) {
    final stage = ref.stageIndex;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (stage >= CherryBlossomStageCatalog.maxPlayableStage)
          CherryBlossomLivingCanopyBackground(
            size: cellSize,
            stageIndex: stage,
            // Static canopy in pots: animated blur here freezes neighbor tickers.
            animate: false,
          )
        else
          ColoredBox(
            color: CherryBlossomStageCatalog.scaffoldColorFor(stage),
          ),
        Image.asset(
          ref.assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        if (stage == CherryBlossomStageCatalog.maxPlayableStage)
          CherryBlossomStageSixLeaves(
            size: cellSize,
            displayLevel: CherryBlossomStageSixLeaves.bonsaiPotConcurrent,
            maxConcurrent: CherryBlossomStageSixLeaves.bonsaiPotConcurrent,
            animate: animateEffects,
            sizeScale: CherryBlossomStageSixLeaves.bonsaiSizeScale,
          ),
        if (stage == CherryBlossomStageCatalog.finaleStage)
          switch (ref.prestigePath ?? CherryBlossomPrestigePath.peace) {
            CherryBlossomPrestigePath.peace => CherryBlossomPeacePetals(
                size: cellSize,
                animate: animateEffects,
                sizeMul: CherryBlossomPeacePetals.bonsaiSizeMul,
                minConcurrent: CherryBlossomPeacePetals.bonsaiMinConcurrent,
                maxConcurrent: CherryBlossomPeacePetals.bonsaiMaxConcurrent,
                litePaint: true,
              ),
            CherryBlossomPrestigePath.power => CherryBlossomPowerPetals(
                size: cellSize,
                animate: animateEffects,
                sizeMul: CherryBlossomPowerPetals.bonsaiSizeMul,
                minConcurrent: CherryBlossomPowerPetals.bonsaiMinConcurrent,
                maxConcurrent: CherryBlossomPowerPetals.bonsaiMaxConcurrent,
                litePaint: true,
              ),
          },
        if (countLabel != null) _countBadge(),
      ],
    );
  }

  Widget _buildGroundedTree(CherryBlossomBonsaiRef ref, Size cellSize) {
    final stage = ref.stageIndex;
    final treeH =
        cellSize.height *
        CherryBlossomStageCatalog.bonsaiTreeHeightFraction(stage);
    final bottom = CherryBlossomStageCatalog.bonsaiTreeBottomOffset(
      stageIndex: stage,
      cellHeight: cellSize.height,
      drawHeight: treeH,
    );

    Widget treeImage = Image.asset(
      ref.assetPath,
      fit: CherryBlossomStageCatalog.imageFitFor(
        stageIndex: stage,
        fullBleed: false,
      ),
      width: cellSize.width,
      height: treeH,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
    );
    if (CherryBlossomStageCatalog.usesMultiplyBlend(stage, 0)) {
      treeImage = CherryBlossomMultiplyBlend(child: treeImage);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (CherryBlossomStageCatalog.usesProgrammaticBackground(stage))
          CherryBlossomTreeBackground(
            stageIndex: stage,
            size: cellSize,
            compact: true,
          )
        else
          ColoredBox(
            color: CherryBlossomStageCatalog.scaffoldColorFor(stage),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          height: treeH,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: treeImage,
          ),
        ),
        if (stage >= 1 && stage <= 5)
          CherryBlossomFallingPetals(
            size: cellSize,
            stageIndex: stage,
            animate: animateEffects,
            compact: true,
          ),
        if (countLabel != null) _countBadge(),
      ],
    );
  }

  Widget _countBadge() {
    return Positioned(
      right: 3,
      bottom: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            countLabel!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
