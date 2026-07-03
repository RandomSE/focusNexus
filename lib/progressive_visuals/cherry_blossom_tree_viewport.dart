import 'package:flutter/material.dart';

import 'cherry_blossom_falling_petals.dart';
import 'cherry_blossom_living_canopy_background.dart';
import 'cherry_blossom_multiply_blend.dart';
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
    final heightFraction = CherryBlossomStageCatalog.treeHeightFraction(
      stageIndex: stage,
      growthStepsInStage: tree.growthStepsInStage,
    );
    final imageFit = CherryBlossomStageCatalog.imageFitFor(
      stageIndex: stage,
      fullBleed: fullBleed,
    );

    return ColoredBox(
      color: CherryBlossomStageCatalog.scaffoldColorFor(stage),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          if (CherryBlossomStageCatalog.usesProgrammaticBackground(stage))
            CherryBlossomTreeBackground(stageIndex: stage, size: size),
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
            heightFraction: fullBleed ? 1.0 : heightFraction * (1.0 + pulseBoost),
            usesMultiply: usesMultiply,
            fullBleed: fullBleed || CherryBlossomStageCatalog.usesFullBleedImage(stage),
            imageFit: imageFit,
          ),
          if (stage == CherryBlossomStageCatalog.maxPlayableStage)
            CherryBlossomStageSixLeaves(
              size: size,
              animate: animateEffects,
            ),
        ],
      ),
    );
  }

  Widget _buildTreeLayer({
    required double heightFraction,
    required bool usesMultiply,
    required bool fullBleed,
    required BoxFit imageFit,
  }) {
    if (fullBleed) {
      return Positioned.fill(
        child: Image.asset(
          tree.assetPath,
          fit: imageFit,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    final drawHeight = size.height * heightFraction.clamp(0.0, 1.0);
    Widget treeImage = Image.asset(
      tree.assetPath,
      fit: imageFit,
      width: size.width,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
    );

    if (usesMultiply) {
      treeImage = CherryBlossomMultiplyBlend(child: treeImage);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: drawHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: treeImage,
      ),
    );
  }
}
