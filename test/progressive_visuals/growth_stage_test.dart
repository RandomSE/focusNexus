import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/growth_stage.dart';

void main() {
  test('growthStageFromIndex maps valid indices', () {
    expect(growthStageFromIndex(0), GrowthStage.seed);
    expect(growthStageFromIndex(4), GrowthStage.mature);
  });

  test('growthStageFromIndex throws for out-of-range indices', () {
    expect(() => growthStageFromIndex(-1), throwsRangeError);
    expect(() => growthStageFromIndex(5), throwsRangeError);
  });

  test('GrowthStageIndex extension matches enum order', () {
    for (var i = 0; i < GrowthStage.values.length; i++) {
      expect(GrowthStage.values[i].index, i);
    }
  });
}
