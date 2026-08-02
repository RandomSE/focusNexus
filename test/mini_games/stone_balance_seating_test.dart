import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_seating.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_stone_paint.dart';

void main() {
  test('cairn top and bottom edges are horizontally flat', () {
    for (var seed = 0; seed < 40; seed++) {
      final path = cairnStonePath(100, 36, seed);
      final metrics = path.computeMetrics().toList();
      expect(metrics, isNotEmpty);
      // Sample extrema: all top-ish points share y=-18, bottom y=+18.
      final bounds = path.getBounds();
      expect(bounds.top, closeTo(-18, 0.01));
      expect(bounds.bottom, closeTo(18, 0.01));
    }
  });

  test('seated stones share a contact edge (two endpoints meet support top)', () {
    const supportTilt = 0.3; // ~17 deg
    const support = (cx: 200.0, cy: 500.0, h: 40.0, w: 120.0);
    const fallH = 36.0;
    final seat = StoneBalanceSeating.seatedCenter(
      supportCx: support.cx,
      supportCy: support.cy,
      supportHeight: support.h,
      fallHeight: fallH,
      tilt: supportTilt,
      aimCx: 210,
    );

    Offset toSupportLocal(Offset world) {
      final dx = world.dx - support.cx;
      final dy = world.dy - support.cy;
      final c = math.cos(supportTilt);
      final s = math.sin(supportTilt);
      // Inverse of clockwise canvas rotate.
      return Offset(dx * c - dy * s, dx * s + dy * c);
    }

    // Bottom edge samples of the upper stone must lie on support top y=-h/2.
    for (final x in [-25.0, 0.0, 25.0]) {
      final bottom = StoneBalanceSeating.localToWorld(
        cx: seat.dx,
        cy: seat.dy,
        tilt: supportTilt,
        local: Offset(x, fallH / 2),
      );
      final local = toSupportLocal(bottom);
      expect(local.dy, closeTo(-support.h / 2, 0.05));
    }
  });

  test('landing tilt inherits support tilt plus overhang lean', () {
    final tilt = StoneBalanceSeating.landingTilt(
      supportTilt: 0.25,
      overhang: 0.14,
      leanSign: 1,
    );
    expect(tilt, greaterThan(0.25));
    expect(tilt, lessThan(0.25 + 0.13));
  });

  test('zero overhang keeps support tilt', () {
    expect(
      StoneBalanceSeating.landingTilt(
        supportTilt: 0.2,
        overhang: 0,
        leanSign: -1,
      ),
      closeTo(0.2, 1e-9),
    );
  });

  test('localToWorld matches clockwise canvas rotate', () {
    // 90 deg clockwise: local (0, 10) -> world (10, 0) relative to origin.
    final p = StoneBalanceSeating.localToWorld(
      cx: 0,
      cy: 0,
      tilt: math.pi / 2,
      local: const Offset(0, 10),
    );
    expect(p.dx, closeTo(10, 1e-9));
    expect(p.dy, closeTo(0, 1e-9));
  });
}
