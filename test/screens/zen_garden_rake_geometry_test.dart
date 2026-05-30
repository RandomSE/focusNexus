import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Mirrors [RakedSandPainter] clip: horizontal rakes visible only outside circle.
bool horizontalRakeVisibleAt({
  required Offset point,
  required Offset circleCenter,
  required double circleRadius,
}) {
  final dx = point.dx - circleCenter.dx;
  final dy = point.dy - circleCenter.dy;
  return dx * dx + dy * dy >= circleRadius * circleRadius;
}

void main() {
  group('zen garden rake circle vs horizontal lines', () {
    const center = Offset(250, 460);
    const maxR = 187.5; // 75% of 500px width

    test('innermost ring starts at 30px minimum radius', () {
      const minRingR = 30.0;
      const ringGap = 14.0;
      final radii = <double>[];
      var r = minRingR;
      while (r <= maxR) {
        radii.add(r);
        r += ringGap;
      }
      expect(radii.first, 30.0);
      expect(radii.length, greaterThan(3));
    });

    test('center of rake circle has no horizontal rake zone', () {
      expect(
        horizontalRakeVisibleAt(
          point: center,
          circleCenter: center,
          circleRadius: maxR,
        ),
        isFalse,
      );
    });

    test('point below outer ring is outside circle', () {
      expect(
        horizontalRakeVisibleAt(
          point: Offset(center.dx, center.dy + maxR + 1),
          circleCenter: center,
          circleRadius: maxR,
        ),
        isTrue,
      );
    });

    test('point on left margin beside circle is outside circle', () {
      final y = center.dy;
      final halfChord = math.sqrt(maxR * maxR - 1);
      expect(
        horizontalRakeVisibleAt(
          point: Offset(center.dx - halfChord - 2, y),
          circleCenter: center,
          circleRadius: maxR,
        ),
        isTrue,
      );
    });
  });
}
