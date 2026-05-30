import 'dart:math' as math;
import 'dart:ui';

import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';

/// Nominal koi pond width before fitting to the decor canvas.
/// Stage 5 (index 4) is ~60% wider than stage 1 (index 0).
double zenKoiPondNominalWidth(int stageIndex) {
  return switch (stageIndex.clamp(0, 4)) {
    0 => 68.0,
    1 => 77.0,
    2 => 92.0,
    3 => 102.0,
    _ => 108.8,
  };
}

/// Paint canvas width for koi ponds — grows with stage so later sizes are not clamped flat.
double zenKoiPondCanvasWidth(int stageIndex) {
  final st = stageIndex.clamp(0, 4);
  return 94.0 + st * 4.0;
}

/// Paint canvas height for koi ponds — keeps pond height plus rim detail visible.
double zenKoiPondCanvasHeight(int stageIndex, double pondWidth) {
  return math.max(78.0, pondWidth * 0.58 + 14.0);
}

/// Fit pond width inside the decor paint canvas without bleeding into neighbors.
double zenKoiPondFitWidth(int stageIndex, double canvasWidth, {double canvasHeight = 78}) {
  final nominal = zenKoiPondNominalWidth(stageIndex);
  final maxW = canvasWidth * 0.98;
  final maxH = canvasHeight * 0.90;
  final maxFromHeight = maxH / 0.58;
  return math.min(nominal, math.min(maxW, maxFromHeight));
}

/// Vertical extent of bamboo stalks above canvas center (px).
const double zenBambooFenceStalkExtent = 45.0;

/// Default decor paint canvas width.
const double zenDefaultDecorPaintWidth = 94.0;

/// Default decor paint canvas height.
const double zenDefaultDecorPaintHeight = 78.0;

/// Taller canvas so bamboo stalk tips are not hard-clipped.
const double zenBambooFencePaintHeight = 100.0;

/// Rounded clip radius at the top of the bamboo fence paint region.
const double zenBambooFenceTopClipRadius = 12.0;

/// Widget slot sizes on the garden canvas (must match [ZenDecorVisual] / [_PlantVisual]).
const double zenDecorSlotWidth = 96.0;
const double zenDecorSlotHeight = 90.0;
const double zenDecorPaintBottomInset = 2.0;

const double zenPlantSlotWidth = 96.0;
const double zenPlantSlotHeight = 118.0;
const double zenPlantPaintBottomInset = 6.0;
const double zenPlantPaintWidth = 72.0;
const double zenPlantPaintHeight = 92.0;

/// Offset from the logical anchor (slot center) to painted visual center, in pixels.
Offset zenDecorVisualCenterOffsetPx(DecorItem item) {
  final canvas = zenDecorPaintCanvasSize(item);
  final oy = zenDecorSlotHeight -
      zenDecorPaintBottomInset -
      canvas.height / 2 -
      zenDecorSlotHeight / 2;
  return Offset(0, oy);
}

Offset zenDecorVisualCenterOffsetNorm(DecorItem item, Size gardenSize) {
  final o = zenDecorVisualCenterOffsetPx(item);
  if (gardenSize.width <= 0 || gardenSize.height <= 0) return Offset.zero;
  return Offset(o.dx / gardenSize.width, o.dy / gardenSize.height);
}

Offset zenPlantVisualCenterOffsetPx(GardenItem item) {
  final oy = zenPlantSlotHeight -
      zenPlantPaintBottomInset -
      zenPlantPaintHeight / 2 -
      zenPlantSlotHeight / 2;
  return Offset(0, oy);
}

Offset zenPlantVisualCenterOffsetNorm(GardenItem item, Size gardenSize) {
  final o = zenPlantVisualCenterOffsetPx(item);
  if (gardenSize.width <= 0 || gardenSize.height <= 0) return Offset.zero;
  return Offset(o.dx / gardenSize.width, o.dy / gardenSize.height);
}

/// Hit-target footprint in pixels, aligned to painted art (not full widget slot).
(double, double) zenDecorHitFootprintPx(DecorItem item) {
  final canvas = zenDecorPaintCanvasSize(item);
  final st = item.stageIndex.clamp(0, 4);
  return switch (item.kind) {
    'zen.stone_path' => st == 0
        ? (22.0, 14.0)
        : (
            canvas.width * (0.86 + st * 0.035),
            canvas.height * (0.40 + st * 0.045),
          ),
    'zen.koi_pond' => () {
        final pondW = zenKoiPondFitWidth(
          st,
          canvas.width,
          canvasHeight: canvas.height,
        );
        return (pondW * 0.96, pondW * 0.58 * 1.02);
      }(),
    'zen.bamboo_fence' => (canvas.width * 0.90, canvas.height * 0.90),
    'zen.wood_bench' => (canvas.width * 0.80, canvas.height * 0.46),
    'zen.stone_lantern' => (canvas.width * 0.40, canvas.height * 0.76),
    'zen.moss_rock' => (canvas.width * 0.70, canvas.height * 0.58),
    _ => (canvas.width * 0.72, canvas.height * 0.62),
  };
}

(double, double) zenPlantHitFootprintPx(GardenItem item) {
  final st = item.stageIndex.clamp(0, 4);
  final canopyScale = 0.55 + st * 0.09;
  return (
    zenPlantPaintWidth * canopyScale,
    zenPlantPaintHeight * (0.68 + st * 0.045),
  );
}

/// Ground contact shadows anchor elevated decor; sand-flush items sit without one.
bool zenDecorUsesGroundShadow(String kind) {
  return switch (kind) {
    'zen.stone_path' ||
    'zen.koi_pond' ||
    'zen.stone_lantern' ||
    'zen.bamboo_fence' ||
    'zen.moss_rock' => false,
    _ => true,
  };
}

/// Paint canvas size for a decor item.
({double width, double height}) zenDecorPaintCanvasSize(DecorItem item) {
  final st = item.stageIndex.clamp(0, 4);
  if (item.kind == 'zen.koi_pond') {
    final w = zenKoiPondCanvasWidth(st);
    final fitW = zenKoiPondFitWidth(st, w, canvasHeight: zenKoiPondCanvasHeight(st, w));
    return (width: w, height: zenKoiPondCanvasHeight(st, fitW));
  }
  if (item.kind == 'zen.bamboo_fence') {
    return (width: zenDefaultDecorPaintWidth, height: zenBambooFencePaintHeight);
  }
  return (width: zenDefaultDecorPaintWidth, height: zenDefaultDecorPaintHeight);
}

/// Non-zero when decor paint layer should use a rounded top clip (e.g. bamboo fence).
double zenDecorTopClipRadius(String kind) {
  return kind == 'zen.bamboo_fence' ? zenBambooFenceTopClipRadius : 0.0;
}

/// Normalized ellipse radii for decor–decor / decor–plant separation (garden coords).
(double, double) zenDecorSeparationRadii(DecorItem item) {
  final st = item.stageIndex.clamp(0, 4);
  return switch (item.kind) {
    'zen.stone_path' => (0.19 + st * 0.018, 0.11 + st * 0.014),
    'zen.koi_pond' => (0.11 + st * 0.013, 0.085 + st * 0.010),
    'zen.bamboo_fence' => (0.20 + st * 0.020, 0.11 + st * 0.014),
    'zen.wood_bench' => (0.14 + st * 0.016, 0.095 + st * 0.012),
    'zen.stone_lantern' => (0.12 + st * 0.012, 0.10 + st * 0.010),
    _ => (0.13 + st * 0.014, 0.10 + st * 0.012),
  };
}

(double, double) zenPlantSeparationRadii(GardenItem item) {
  final st = item.stageIndex.clamp(0, 4);
  return (0.085 + st * 0.014, 0.11 + st * 0.018);
}

(double, double) zenDecorKindSeparationRadii(String kind, int stageIndex) {
  final st = stageIndex.clamp(0, 4);
  return switch (kind) {
    'zen.stone_path' => (0.19 + st * 0.018, 0.11 + st * 0.014),
    'zen.koi_pond' => (0.11 + st * 0.013, 0.085 + st * 0.010),
    'zen.bamboo_fence' => (0.20 + st * 0.020, 0.11 + st * 0.014),
    'zen.wood_bench' => (0.14 + st * 0.016, 0.095 + st * 0.012),
    'zen.stone_lantern' => (0.12 + st * 0.012, 0.10 + st * 0.010),
    _ => (0.13 + st * 0.014, 0.10 + st * 0.012),
  };
}

/// Normalized waterfall feature on the right edge of the zen garden backdrop.
bool zenGardenPointInWaterfall(double nx, double ny) {
  const cx = 0.86;
  const cy = 0.30;
  const rx = 0.13;
  const ry = 0.24;
  final dx = nx - cx;
  final dy = ny - cy;
  return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) < 1.0;
}

(double, double) _nudgeOutOfWaterfall(double nx, double ny) {
  const cx = 0.86;
  const cy = 0.30;
  const rx = 0.13;
  const ry = 0.24;
  final dx = nx - cx;
  final dy = ny - cy;
  final norm = math.sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry));
  if (norm >= 1.0) return (nx, ny);
  final push = 1.03 / norm;
  return (cx + dx * push, cy + dy * push);
}

/// Clamps placement to garden bounds and keeps items off the static waterfall only.
({double x, double y}) resolveZenGardenPlacement({
  required double nx,
  required double ny,
  required double moverRx,
  required double moverRy,
}) {
  var x = nx.clamp(moverRx, 1 - moverRx);
  var y = ny.clamp(moverRy, 1 - moverRy);

  if (zenGardenPointInWaterfall(x, y)) {
    final (wx, wy) = _nudgeOutOfWaterfall(x, y);
    x = wx.clamp(moverRx, 1 - moverRx);
    y = wy.clamp(moverRy, 1 - moverRy);
  }

  return (x: x, y: y);
}
