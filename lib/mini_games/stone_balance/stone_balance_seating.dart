import 'dart:math' as math;
import 'dart:ui';

import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';

/// Pure seating math for cairn stones (matches Flutter clockwise [Canvas.rotate]).
abstract final class StoneBalanceSeating {
  /// Clockwise rotation used by [Canvas.rotate].
  static Offset localToWorld({
    required double cx,
    required double cy,
    required double tilt,
    required Offset local,
  }) {
    final c = math.cos(tilt);
    final s = math.sin(tilt);
    return Offset(
      cx + local.dx * c + local.dy * s,
      cy - local.dx * s + local.dy * c,
    );
  }

  /// World center so the upper stone's bottom edge lies on the support top edge.
  ///
  /// [aimCx] is the player aim in world X. [tilt] is the shared contact tilt
  /// (support tilt plus any overhang lean).
  static Offset seatedCenter({
    required double supportCx,
    required double supportCy,
    required double supportHeight,
    required double fallHeight,
    required double tilt,
    required double aimCx,
  }) {
    final halfGap = supportHeight / 2 + fallHeight / 2;
    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);
    // Base stack along the face normal, then slide along the face for aim.
    // Clockwise R*(0, -halfGap) = (-halfGap*sin, -halfGap*cos).
    final baseCx = supportCx - halfGap * sinT;
    final baseCy = supportCy - halfGap * cosT;
    // Edge direction = R*(1, 0) = (cos, -sin).
    final d = cosT.abs() < 1e-6 ? 0.0 : (aimCx - baseCx) / cosT;
    return Offset(baseCx + d * cosT, baseCy - d * sinT);
  }

  /// Platform / foundation: horizontal seat on [platformTopY].
  static Offset seatedOnPlatform({
    required double platformTopY,
    required double fallHeight,
    required double aimCx,
  }) {
    return Offset(aimCx, platformTopY - fallHeight / 2);
  }

  /// Landing tilt: match support, plus overhang lean. Large lean topples.
  static double landingTilt({
    required double supportTilt,
    required double overhang,
    required double leanSign,
  }) {
    final capped = overhang.clamp(
      0.0,
      StoneBalanceConstants.overhangImmediateTopple,
    );
    final extra = leanSign *
        (capped / StoneBalanceConstants.overhangImmediateTopple) *
        StoneBalanceConstants.maxStableTilt;
    return supportTilt + extra;
  }
}
