import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_growth.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_reference_tree.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_painter.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_sequence.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';

void main() {
  const canvasSize = Size(400, 600);

  group('CherryBlossomReferenceTree', () {
    test('canopy spans approximately 88% of canvas width', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      expect(
        layout.canopySpanWidth / canvasSize.width,
        closeTo(0.88, 0.04),
      );
    });

    test('individual dot radii stay within 1.1% of canvas width', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      final maxR = canvasSize.width * CherryBlossomReferenceTree.maxDotRadiusRatio;
      final allDots = [
        ...layout.backDots,
        ...layout.midDots,
        ...layout.frontDots,
        ...layout.whiteDots,
        ...layout.accentDots,
      ];
      for (final dot in allDots) {
        expect(
          dot.radius,
          lessThanOrEqualTo(maxR + 0.01),
          reason: 'dot radius ${dot.radius} exceeds max $maxR',
        );
      }
    });

    test('recursive skeleton produces 40–60 branch tips', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      expect(layout.branchTips.length, inInclusiveRange(40, 60));
    });

    test('blossom clusters attach to branch skeleton', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      expect(layout.clusterCenters, isNotEmpty);
      final anchors = [
        ...layout.branchTips,
        ...layout.clusterCenters,
      ];
      for (final center in layout.clusterCenters) {
        final nearest = anchors
            .map((a) => (a - center).distance)
            .reduce((a, b) => a < b ? a : b);
        expect(nearest, lessThan(canvasSize.width * 0.06));
      }
    });

    test('cluster centers respect minimum spacing', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      final minSpacing = canvasSize.width * 0.055;
      for (var i = 0; i < layout.clusterCenters.length; i++) {
        for (var j = i + 1; j < layout.clusterCenters.length; j++) {
          expect(
            (layout.clusterCenters[i] - layout.clusterCenters[j]).distance,
            greaterThanOrEqualTo(minSpacing - 0.5),
          );
        }
      }
    });

    test('places 35 flowers and 18 leaves', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      expect(layout.flowers.length, 35);
      expect(layout.leaves.length, 18);
      expect(layout.flowers.first.size, closeTo(canvasSize.width * 0.020, 0.001));
    });

    test('flowers sit on branch tips', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      for (final flower in layout.flowers) {
        final onTip = layout.branchTips.any(
          (tip) => (tip - flower.center).distance < 1.0,
        );
        expect(onTip, isTrue, reason: 'flower at ${flower.center} not on a tip');
      }
    });

    test('canopy sides droop lower than center bottom', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      expect(
        layout.canopyBottomY,
        greaterThan(layout.canopyBottomCenterY + 5),
      );
    });

    test('left and right branch tips are asymmetric', () {
      final layout = CherryBlossomReferenceTree.layout(canvasSize);
      final cx = layout.base.dx;
      final left = layout.branchTips.where((t) => t.dx < cx - 10).toList();
      final right = layout.branchTips.where((t) => t.dx > cx + 10).toList();
      expect(left.length, greaterThan(10));
      expect(right.length, greaterThan(10));
      final leftMeanY = left.map((t) => t.dy).reduce((a, b) => a + b) / left.length;
      final rightMeanY = right.map((t) => t.dy).reduce((a, b) => a + b) / right.length;
      expect((leftMeanY - rightMeanY).abs(), greaterThan(5));
    });
  });

  group('CherryBlossomTreePainter _focusBounds regression', () {
    test('leaf focus does not throw when composition clusters empty', () {
      final tree = CherryBlossomTreeState(
        growthStepIndex: 0,
        totalTreePointsInvested: 0,
      ).normalized();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => CherryBlossomTreePainter(
          tree: tree,
          growthFocus: const CherryBlossomGrowthFocus(
            kind: CherryBlossomGrowthKind.leaf,
            slotIndex: 3,
          ),
          growthPulseT: 0.4,
        ).paint(canvas, canvasSize),
        returnsNormally,
      );
    });

    test('growth pulse on perfect band paints without crash', () {
      final tree = CherryBlossomTreeState(
        growthStepIndex: CherryBlossomTreeSequence.stepsAt1m,
        totalTreePointsInvested: CherryBlossomTreeSequence.milestone1m,
      ).normalized();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final kind in CherryBlossomGrowthKind.values) {
        expect(
          () => CherryBlossomTreePainter(
            tree: tree,
            growthFocus: CherryBlossomGrowthFocus(kind: kind, slotIndex: 2),
            growthPulseT: 0.2,
          ).paint(canvas, canvasSize),
          returnsNormally,
          reason: 'pulse on $kind',
        );
      }
    });
  });
}
