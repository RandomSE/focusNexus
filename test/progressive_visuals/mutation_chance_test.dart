import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  group('mutationChanceForRebirthCount', () {
    test('starts at 5% and adds 5% per rebirth', () {
      expect(mutationChanceForRebirthCount(0), 0.05);
      expect(mutationChanceForRebirthCount(1), 0.10);
      expect(mutationChanceForRebirthCount(3), 0.20);
    });

    test('caps at 100%', () {
      expect(mutationChanceForRebirthCount(20), 1.0);
    });
  });

  group('restartGrowthCycle rebirthCount', () {
    test('increments rebirth count for higher future mutation chance', () {
      final engine = ProgressiveGardenEngine();
      var state = GardenState(
        pointsBalance: 100,
        items: [
          const GardenItem(
            id: 'p',
            themeId: VisualThemeId.zenGarden,
            stageIndex: GardenItem.maxStageIndex,
          ),
        ],
      );
      state = engine.restartGrowthCycle(state: state, itemId: 'p').state!;
      expect(state.items.single.rebirthCount, 1);
      state = engine.restartGrowthCycle(state: state, itemId: 'p').state!;
      expect(state.items.single.rebirthCount, 2);
    });
  });
}
