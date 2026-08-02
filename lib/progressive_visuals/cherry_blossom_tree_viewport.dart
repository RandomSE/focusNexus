import 'package:flutter/material.dart';

import 'cherry_blossom_falling_petals.dart';
import 'cherry_blossom_living_canopy_background.dart';
import 'cherry_blossom_multiply_blend.dart';
import 'cherry_blossom_peace_petals.dart';
import 'cherry_blossom_power_petals.dart';
import 'cherry_blossom_prestige_path.dart';
import 'cherry_blossom_stage_catalog.dart';
import 'cherry_blossom_stage_six_effects.dart';
import 'cherry_blossom_stage_six_leaves.dart';
import 'cherry_blossom_tree_background.dart';
import 'cherry_blossom_tree_state.dart';

/// Composes background, scaled tree image, and optional alive effects.
class CherryBlossomTreeViewport extends StatelessWidget {
  const CherryBlossomTreeViewport({
    super.key,
    required this.tree,
    required this.size,
    this.growPulseT = 1.0,
    this.animateEffects = true,
  });

  /// Stack key for the tree image layer (z-order tests).
  static const treeLayerKey = ValueKey<String>('cherry_tree_layer');

  /// Stack key for finale peace/power petal overlay (must be above tree).
  static const finalePetalsKey = ValueKey<String>('cherry_finale_petals');

  final CherryBlossomTreeState tree;
  final Size size;
  final double growPulseT;
  final bool animateEffects;

  @override
  Widget build(BuildContext context) {
    final stage = tree.stageIndex;
    final fullBleed = CherryBlossomStageCatalog.fillsViewport(
      stage,
      tree.growthStepsInStage,
    );
    final usesMultiply = CherryBlossomStageCatalog.usesMultiplyBlend(
      stage,
      tree.growthStepsInStage,
    );
    final pulseBoost = 0.02 * Curves.easeOutCubic.transform(growPulseT);
    final imageFit = CherryBlossomStageCatalog.imageFitFor(
      stageIndex: stage,
      fullBleed: fullBleed,
    );
    final displayLevel = CherryBlossomStageCatalog.displayLevel(
      stageIndex: stage,
      growthStepsInStage: tree.growthStepsInStage,
    );
    final peaceFinale = stage == CherryBlossomStageCatalog.finaleStage &&
        tree.prestigePath == CherryBlossomPrestigePath.peace;
    final powerFinale = stage == CherryBlossomStageCatalog.finaleStage &&
        tree.prestigePath == CherryBlossomPrestigePath.power;

    return ColoredBox(
      color: CherryBlossomStageCatalog.scaffoldColorFor(stage),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          if (CherryBlossomStageCatalog.usesProgrammaticBackground(stage))
            Positioned.fill(
              child: CherryBlossomTreeBackground(
                stageIndex: stage,
                size: size,
              ),
            ),
          if (stage >= 6)
            CherryBlossomLivingCanopyBackground(
              size: size,
              stageIndex: stage,
              animate: animateEffects,
            ),
          if (stage >= 6 && CherryBlossomStageCatalog.usesAliveEffects(stage))
            CherryBlossomStageSixEffects(
              size: size,
              animate: animateEffects,
            ),
          if (stage >= 1 && stage <= 5)
            CherryBlossomFallingPetals(
              size: size,
              stageIndex: stage,
              animate: animateEffects,
            ),
          _buildTreeLayer(
            key: treeLayerKey,
            stage: stage,
            usesMultiply: usesMultiply,
            fullBleed: fullBleed ||
                CherryBlossomStageCatalog.usesFullBleedImage(stage),
            imageFit: imageFit,
            pulseBoost: pulseBoost,
          ),
          if (stage == CherryBlossomStageCatalog.maxPlayableStage)
            CherryBlossomStageSixLeaves(
              size: size,
              displayLevel: displayLevel,
              animate: animateEffects,
            ),
          // Finale petals MUST paint above the full-bleed tree image.
          if (peaceFinale)
            KeyedSubtree(
              key: finalePetalsKey,
              child: CherryBlossomPeacePetals(
                size: size,
                animate: animateEffects,
              ),
            ),
          if (powerFinale)
            KeyedSubtree(
              key: finalePetalsKey,
              child: CherryBlossomPowerPetals(
                size: size,
                animate: animateEffects,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTreeLayer({
    Key? key,
    required int stage,
    required bool usesMultiply,
    required bool fullBleed,
    required BoxFit imageFit,
    required double pulseBoost,
  }) {
    if (fullBleed) {
      return Positioned.fill(
        key: key,
        child: Image.asset(
          tree.assetPath,
          fit: imageFit,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    // Fixed max-height box; scale from content baseline so trunk does not lift.
    final maxFraction = CherryBlossomStageCatalog.maxTreeHeightFraction(stage);
    final growthScale = CherryBlossomStageCatalog.growthScaleRelativeToMax(
      stageIndex: stage,
      growthStepsInStage: tree.growthStepsInStage,
    );
    final scale = (growthScale * (1.0 + pulseBoost)).clamp(0.0, 1.2);
    final pad = CherryBlossomStageCatalog.contentBottomPaddingFraction(stage);
    final alignY = CherryBlossomStageCatalog.contentBaselineAlignmentY(pad);
    final drawHeight = size.height * maxFraction.clamp(0.0, 1.0);

    Widget treeImage = Image.asset(
      tree.assetPath,
      fit: imageFit,
      width: size.width,
      height: drawHeight,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
    );

    // Scale INSIDE blend wrappers. Do not set filterQuality on Transform: that
    // rasterizes into its own layer and breaks BlendMode.multiply onto the sky.
    treeImage = Transform.scale(
      scale: scale,
      alignment: Alignment(0, alignY),
      child: treeImage,
    );

    if (usesMultiply) {
      treeImage = CherryBlossomMultiplyBlend(child: treeImage);
    }

    return Positioned(
      key: key,
      left: 0,
      right: 0,
      bottom: CherryBlossomStageCatalog.treeLayerBottomOffset(
        stageIndex: stage,
        viewportHeight: size.height,
        drawHeight: drawHeight,
      ),
      height: drawHeight,
      child: treeImage,
    );
  }
}
