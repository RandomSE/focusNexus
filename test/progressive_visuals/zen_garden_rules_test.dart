import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';

void main() {
  test('zenGardenTransitionRules defines four staged transitions', () {
    final rules = zenGardenTransitionRules();
    expect(rules.length, 4);
    expect(rules.map((r) => r.fromStageIndex).toList(), [0, 1, 2, 3]);
    expect(rules.every((r) => r.skipWaitPointCost == 75), isTrue);
  });
}
