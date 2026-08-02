import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_fx_timing.dart';

void main() {
  group('CherryBlossomFxTiming', () {
    test('clampSimulationDt never skips long frames', () {
      expect(CherryBlossomFxTiming.clampSimulationDt(0), 0);
      expect(CherryBlossomFxTiming.clampSimulationDt(-1), 0);
      expect(
        CherryBlossomFxTiming.clampSimulationDt(0.016),
        closeTo(0.016, 1e-9),
      );
      expect(
        CherryBlossomFxTiming.clampSimulationDt(0.25),
        CherryBlossomFxTiming.maxSimulationDtSec,
      );
    });

    test('inner 60% band excludes edges; center is inside', () {
      const canvas = Size(100, 100);
      expect(
        CherryBlossomFxTiming.isInInnerBand(const Offset(50, 50), canvas),
        isTrue,
      );
      expect(
        CherryBlossomFxTiming.isInInnerBand(const Offset(25, 25), canvas),
        isTrue,
      );
      expect(
        CherryBlossomFxTiming.isInInnerBand(const Offset(10, 50), canvas),
        isFalse,
      );
      expect(
        CherryBlossomFxTiming.isInInnerBand(const Offset(50, 5), canvas),
        isFalse,
      );
      expect(
        CherryBlossomFxTiming.isInInnerBand(const Offset(90, 90), canvas),
        isFalse,
      );
    });
  });
}
