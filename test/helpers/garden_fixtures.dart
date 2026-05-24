import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

GardenState stateAtStage3({String id = 'm'}) {
  return GardenState(
    pointsBalance: 100,
    items: [
      GardenItem(
        id: id,
        themeId: VisualThemeId.coralReef,
        stageIndex: 3,
      ),
    ],
    freeFirstGrowthEverConsumed: true,
  );
}

GardenState emptyGarden({int points = 100}) {
  return GardenState(pointsBalance: points, items: const []);
}
