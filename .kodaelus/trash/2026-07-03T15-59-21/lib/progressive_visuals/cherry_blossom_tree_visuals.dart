import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cherry_blossom_tree_composition.dart';
import 'cherry_blossom_tree_sequence.dart';
import 'cherry_blossom_tree_state.dart';

/// Stage palette and layout constants for cherry blossom tree rendering.
abstract final class CherryBlossomTreeVisuals {
  CherryBlossomTreeVisuals._();

  static const anchorYRatio = 0.88;
  static const maxTrunkHeightRatio = 0.28;
  static const seedlingTrunkHeightRatio = 0.08;
  static const canopyWidthAtPerfect = 0.88;

  static const trunkBrown = Color(0xFF5C3317);
  static const trunkDark = Color(0xFF3D1F0A);
  static const trunkMid = Color(0xFF6B3A1F);
  static const trunkHighlight = Color(0xFF7A4A2A);
  static const rootBrown = Color(0xFF4A2810);
  static const blossomPink = Color(0xFFFFB7C5);
  static const blossomCenter = Color(0xFFFFC8D3);
  static const blossomEdge = Color(0xFFFF8FAB);
  static const blossomBack = Color(0xFFE8879A);
  static const blossomPale = Color(0xFFFFD4E0);
  static const blossomDeep = Color(0xFFD4789A);
  static const blossomShadow = Color(0xFFC45A7A);
  static const leafGreen = Color(0xFF2D4A1E);
  static const stamenYellow = Color(0xFFFFE566);

  /// Tree anchor and trunk height from canvas size and growth progress.
  static ({Offset base, double trunkH, double canopyW, double growthT}) layout(
    Size size,
    int completedSteps,
    CherryBlossomVisualBand band,
  ) {
    final composition = CherryBlossomTreeComposition.forStep(
      size,
      completedSteps,
      band,
    );
    final growthT =
        (completedSteps / CherryBlossomTreeSequence.totalSteps).clamp(0.0, 1.0);
    return (
      base: composition.base,
      trunkH: composition.trunkH,
      canopyW: composition.canopyRadiusX * 2,
      growthT: growthT,
    );
  }

  /// Fraction of canvas height used by the tree trunk+canopy (legacy callers).
  static double treeHeightRatio(CherryBlossomVisualBand band) => switch (band) {
        CherryBlossomVisualBand.seedling => 0.36,
        CherryBlossomVisualBand.basic => 0.48,
        CherryBlossomVisualBand.good => 0.58,
        CherryBlossomVisualBand.great => 0.66,
        CherryBlossomVisualBand.perfect => 0.70,
      };

  /// Inset factor so sway / canopy effects stay inside the painted scene.
  static double treeScaleInset(CherryBlossomVisualBand band) => switch (band) {
        CherryBlossomVisualBand.perfect => 0.88,
        CherryBlossomVisualBand.great => 0.94,
        _ => 1.0,
      };

  /// Scaffold / letterbox color when the viewer is not filled.
  static Color scaffoldColorFor(CherryBlossomVisualBand band) => switch (band) {
        CherryBlossomVisualBand.seedling => const Color(0xFFC8D8E0),
        CherryBlossomVisualBand.basic => const Color(0xFFD4E8F0),
        CherryBlossomVisualBand.good => const Color(0xFFC8E4F4),
        CherryBlossomVisualBand.great => const Color(0xFFF4C98A),
        CherryBlossomVisualBand.perfect => const Color(0xFF1A1A2E),
      };

  static void paintBackground(
    Canvas canvas,
    Size size,
    CherryBlossomVisualBand band, {
    required double ambientT,
  }) {
    switch (band) {
      case CherryBlossomVisualBand.seedling:
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFFC8D8E0),
        );
        _paintGroundStrip(
          canvas,
          size,
          dirt: const Color(0xFF6B4F2A),
        );
      case CherryBlossomVisualBand.basic:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(0, size.height),
              const [Color(0xFFB8D4E8), Color(0xFFD4E8F0)],
            ),
        );
        _paintGroundStrip(
          canvas,
          size,
          dirt: const Color(0xFF7A5C32),
          grass: const Color(0xFF8A9E6A),
        );
      case CherryBlossomVisualBand.good:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(0, size.height),
              const [Color(0xFFA8CCEA), Color(0xFFC8E4F4)],
            ),
        );
        _paintGroundStrip(
          canvas,
          size,
          dirt: const Color(0xFF8A6A3A),
          grass: const Color(0xFF7A9E5A),
        );
        _paintSoftGlow(
          canvas,
          Offset(size.width * 0.5, size.height * 0.55),
          size.width * 0.35,
          const Color(0x26FFFFFF),
        );
      case CherryBlossomVisualBand.great:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(0, size.height),
              const [Color(0xFF87CEEB), Color(0xFFF4C98A)],
            ),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.06),
          Paint()..color = const Color(0x4DF0A86A),
        );
        _paintGroundStrip(
          canvas,
          size,
          dirt: const Color(0xFF6B4A24),
          grass: const Color(0xFF6A9448),
          shadow: true,
        );
      case CherryBlossomVisualBand.perfect:
        _paintPerfectTwilightBackground(canvas, size, ambientT);
    }
  }

  static void _paintPerfectTwilightBackground(
    Canvas canvas,
    Size size,
    double ambientT,
  ) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          const [
            Color(0xFF1A1A2E),
            Color(0xFF4A2060),
            Color(0xFFC4547A),
          ],
          [0.0, 0.52, 1.0],
        ),
    );

    _paintStars(canvas, size, ambientT);

    final horizonCenter = Offset(size.width * 0.78, size.height * 0.72);
    canvas.drawCircle(
      horizonCenter,
      size.width,
      Paint()
        ..shader = ui.Gradient.radial(
          horizonCenter,
          size.width,
          [
            const Color(0x59FF8C64),
            const Color(0x00FF8C64),
          ],
        ),
    );

    _paintPerfectMoon(canvas, size);

    final groundTop = size.height * 0.92;
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height - groundTop),
      Paint()..color = const Color(0xFF3A2410),
    );
  }

  static void _paintPerfectMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.12);
    for (final (radius, alpha) in [(52.0, 0.08), (38.0, 0.20), (28.0, 0.90)]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFE8E6D0).withValues(alpha: alpha),
      );
    }
  }

  static void _paintGroundStrip(
    Canvas canvas,
    Size size, {
    required Color dirt,
    Color? grass,
    bool shadow = false,
    Color? pinkGlow,
  }) {
    final top = size.height * 0.88;
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, size.height - top),
      Paint()..color = dirt,
    );
    if (grass != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width, size.height * 0.012),
        Paint()..color = grass,
      );
    }
    if (shadow) {
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width * 0.35, size.height - top),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
    }
    if (pinkGlow != null) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.25, top, size.width * 0.5, size.height * 0.02),
        Paint()..color = pinkGlow,
      );
    }
  }

  static void _paintSoftGlow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color, color.withValues(alpha: 0)],
        ),
    );
  }

  static void _paintStars(Canvas canvas, Size size, double ambientT) {
    final rng = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.45;
      final phase = (ambientT + i * 0.17) % 1.0;
      final opacity = 0.4 + 0.5 * math.sin(phase * math.pi * 2);
      canvas.drawCircle(
        Offset(x, y),
        1.0 + rng.nextDouble(),
        Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.4, 0.9)),
      );
    }
  }

  /// Pop-in scale for a freshly grown piece (0 = hidden, 1 = full).
  static double popScale(double t) {
    final curved = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
    return curved.clamp(0.0, 1.15);
  }
}
