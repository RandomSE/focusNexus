import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Shared FX timing / spatial helpers for cherry blossom particle layers.
abstract final class CherryBlossomFxTiming {
  CherryBlossomFxTiming._();

  /// Max simulation step. Skipping large dt freezes FX under sustained jank.
  static const double maxSimulationDtSec = 0.05;

  /// Clamp a ticker delta for simulation (never skip a long frame entirely).
  static double clampSimulationDt(double dt) {
    if (dt <= 0) return 0;
    return math.min(dt, maxSimulationDtSec);
  }

  /// True when [p] lies in the centered [band] fraction of [canvas] (default 60%).
  static bool isInInnerBand(
    Offset p,
    Size canvas, {
    double band = 0.60,
  }) {
    if (canvas.width <= 0 || canvas.height <= 0) return false;
    final margin = ((1.0 - band) / 2.0).clamp(0.0, 0.5);
    final nx = (p.dx / canvas.width).clamp(0.0, 1.0);
    final ny = (p.dy / canvas.height).clamp(0.0, 1.0);
    return nx >= margin &&
        nx <= 1.0 - margin &&
        ny >= margin &&
        ny <= 1.0 - margin;
  }
}
