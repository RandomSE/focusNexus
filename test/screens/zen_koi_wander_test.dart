import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_painters.dart';

void main() {
  group('koiWanderAt', () {
    const center = Offset(47, 39);
    const pondW = 80.0;
    const pondH = 46.0;

    test('moves visibly over one second', () {
      final a = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 0,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 0,
      );
      final b = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 0,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 1,
      );
      expect((b.position - a.position).distance, greaterThan(1.5));
    });

    test('moves smoothly without teleporting over elapsed time', () {
      final a = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 0,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 12,
      );
      final b = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 0,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 12.2,
      );
      final step = (b.position - a.position).distance;
      expect(step, lessThan(8));
      expect(step, greaterThan(0));
    });

    test('stays inside pond bounds at many time samples', () {
      const bodyRadius = 11.0;
      for (var fish = 0; fish < 4; fish++) {
        for (var t = 0.0; t < 40; t += 0.35) {
          final w = koiWanderAt(
            pondCenter: center,
            pondW: pondW,
            pondH: pondH,
            fishIndex: fish,
            pondId: 'pond-bounds',
            stageIndex: 3,
            elapsedSeconds: t,
          );
          final maxRx = math.max(4.0, pondW * 0.36 - bodyRadius);
          final maxRy = math.max(4.0, pondH * 0.30 - bodyRadius);
          final dx = w.position.dx - center.dx;
          final dy = w.position.dy - center.dy;
          final inEllipse =
              (dx * dx) / (maxRx * maxRx) + (dy * dy) / (maxRy * maxRy);
          expect(inEllipse, lessThanOrEqualTo(1.001));
        }
      }
    });

    test('faces swim direction without reversing on turns', () {
      for (var t = 0.0; t < 25; t += 0.2) {
        final w = koiWanderAt(
          pondCenter: center,
          pondW: pondW,
          pondH: pondH,
          fishIndex: 2,
          pondId: 'pond-facing',
          stageIndex: 2,
          elapsedSeconds: t,
        );
        final w2 = koiWanderAt(
          pondCenter: center,
          pondW: pondW,
          pondH: pondH,
          fishIndex: 2,
          pondId: 'pond-facing',
          stageIndex: 2,
          elapsedSeconds: t + 0.04,
        );
        final vel = w2.position - w.position;
        if (vel.distance < 0.15) continue;
        final facing = Offset(
          math.cos(w.angle),
          math.sin(w.angle),
        );
        expect(
          facing.dx * vel.dx + facing.dy * vel.dy,
          greaterThan(0),
          reason: 'facing backwards at t=$t',
        );
      }
    });

    test('different fish take different paths', () {
      final f0 = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 0,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 20,
      );
      final f1 = koiWanderAt(
        pondCenter: center,
        pondW: pondW,
        pondH: pondH,
        fishIndex: 1,
        pondId: 'pond-a',
        stageIndex: 2,
        elapsedSeconds: 20,
      );
      expect(f0.position, isNot(equals(f1.position)));
    });
  });
}
