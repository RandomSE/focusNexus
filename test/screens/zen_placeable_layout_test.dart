import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/zen_garden/zen_placeable_layout.dart';

void main() {
  test('koi pond widths grow by stage and stay monotonic', () {
    final widths = List.generate(5, zenKoiPondNominalWidth);
    expect(widths[0], 68.0);
    expect(widths[1], 77.0);
    expect(widths[2], 92.0);
    expect(widths[3], 102.0);
    expect(widths[4], closeTo(108.8, 0.1));
    expect(widths[4] / widths[0], closeTo(1.6, 0.01));
    for (var i = 1; i < widths.length; i++) {
      expect(widths[i], greaterThan(widths[i - 1]));
    }
  });

  test('koi pond fitted width grows with stage on stage-aware canvas', () {
    final fitted = <double>[];
    for (var st = 0; st < 5; st++) {
      final canvasW = zenKoiPondCanvasWidth(st);
      final canvasH = zenKoiPondCanvasHeight(st, canvasW);
      fitted.add(zenKoiPondFitWidth(st, canvasW, canvasHeight: canvasH));
    }
    expect(fitted[4] / fitted[0], closeTo(1.6, 0.05));
    for (var i = 1; i < fitted.length; i++) {
      expect(fitted[i], greaterThan(fitted[i - 1]));
    }
  });

  test('resolveZenGardenPlacement keeps tap position when not on waterfall', () {
    final (mrx, mry) = zenDecorKindSeparationRadii('zen.stone_lantern', 4);
    final resolved = resolveZenGardenPlacement(
      nx: 0.5,
      ny: 0.5,
      moverRx: mrx,
      moverRy: mry,
    );
    expect(resolved.x, 0.5);
    expect(resolved.y, 0.5);
  });

  test('resolveZenGardenPlacement nudges only off the waterfall zone', () {
    final (mrx, mry) = zenDecorKindSeparationRadii('zen.koi_pond', 0);
    final resolved = resolveZenGardenPlacement(
      nx: 0.86,
      ny: 0.30,
      moverRx: mrx,
      moverRy: mry,
    );
    expect(zenGardenPointInWaterfall(resolved.x, resolved.y), isFalse);
  });
}
