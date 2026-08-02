import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_falling_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('ground top matches catalog ground inset', () {
    const size = Size(400, 600);
    expect(
      CherryBlossomFallingPetals.groundTopY(size),
      size.height * (1.0 - CherryBlossomStageCatalog.groundInsetFraction),
    );
  });

  test('land fade duration is positive', () {
    expect(CherryBlossomFallingPetals.landFadeSeconds, greaterThan(0.2));
  });
}
