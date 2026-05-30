import 'package:flutter/material.dart';

/// Bold outlines, saturated fills, and highlight spots for cartoon zen art.
abstract final class ZenCartoonStyle {
  static const ink = Color(0xFF2A2520);
  static const outlineWidth = 2.6;
  static const outlineThin = 1.9;

  static const plantSage = Color(0xFF6B9E5E);
  static const plantSageHi = Color(0xFF8FB878);
  static const plantMutant = Color(0xFF00FFD1);
  static const plantMutantHi = Color(0xFF80FFE8);
  static const trunk = Color(0xFF6D4C3D);
  static const trunkHi = Color(0xFF9A6B4F);

  static Paint fill(Color color) => Paint()..color = color;

  static Paint outline([double width = outlineWidth, Color color = ink]) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
  }

  static Color saturate(Color color, {double by = 0.22}) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation + by).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0))
        .toColor();
  }

  static Color plantFill(Color themePrimary, {bool selected = false, bool mutated = false}) {
    if (mutated) {
      return saturate(plantMutant, by: selected ? 0.12 : 0.06);
    }
    return plantSage;
  }

  static void highlightSpot(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );
  }

  static void drawOutlinedOval(
    Canvas canvas,
    Rect rect,
    Color fillColor, {
    double stroke = outlineWidth,
    Color strokeColor = ink,
  }) {
    canvas.drawOval(rect, fill(fillColor));
    canvas.drawOval(rect, outline(stroke, strokeColor));
  }

  static void drawOutlinedRRect(
    Canvas canvas,
    RRect rrect,
    Color fillColor, {
    double stroke = outlineWidth,
    Color strokeColor = ink,
  }) {
    canvas.drawRRect(rrect, fill(fillColor));
    canvas.drawRRect(rrect, outline(stroke, strokeColor));
  }

  static void drawOutlinedPath(
    Canvas canvas,
    Path path,
    Color fillColor, {
    double stroke = outlineWidth,
    Color strokeColor = ink,
  }) {
    canvas.drawPath(path, fill(fillColor));
    canvas.drawPath(path, outline(stroke, strokeColor));
  }

  /// Top-left light: contact shadow offset bottom-right (3px, 4px), blur 6, 18% black.
  static const placeableShadowOffset = Offset(3, 4);
  static const placeableShadowBlur = 6.0;
  static const placeableShadowAlpha = 0.18;

  static void celShadow(Canvas canvas, Path shape, {Offset? offset}) {
    final off = offset ?? placeableShadowOffset;
    canvas.save();
    canvas.translate(off.dx, off.dy);
    canvas.drawPath(
      shape,
      Paint()
        ..color = Colors.black.withValues(alpha: placeableShadowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, placeableShadowBlur),
    );
    canvas.restore();
  }

  /// Offset contact shadow beneath placeables — consistent top-left light source.
  static void drawGroundShadow(
    Canvas canvas,
    Offset center, {
    double width = 56,
    double height = 14,
    Offset? offset,
  }) {
    final off = offset ?? placeableShadowOffset;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + off,
        width: width,
        height: height,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: placeableShadowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, placeableShadowBlur),
    );
  }

  static void drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double stroke = outlineWidth,
  }) {
    const dash = 10.0;
    const gap = 7.0;
    final paint = outline(stroke, color)..style = PaintingStyle.stroke;
    final circumference = 2 * 3.141592653589793 * radius;
    final step = dash + gap;
    for (var d = 0.0; d < circumference; d += step) {
      final sweep = (dash / circumference) * 2 * 3.141592653589793;
      final start = (d / circumference) * 2 * 3.141592653589793;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }
}
