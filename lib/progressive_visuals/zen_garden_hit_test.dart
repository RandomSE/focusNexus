import 'dart:ui';

import 'garden_state.dart';
import 'sandbox_entity.dart';
import 'zen_placeable_bounds.dart';

export 'zen_placeable_bounds.dart'
    show
        zenDecorVisualHeight,
        zenDecorVisualWidth,
        zenGardenNearestPick,
        zenPlantVisualHeight,
        zenPlantVisualWidth,
        zenReferenceGardenSize;

/// Theme-specific hit testing for the zen garden sandbox.
abstract interface class SandboxHitTester {
  SandboxEntityRef? nearestPick(
    double nx,
    double ny,
    GardenState garden, {
    Size gardenSize,
  });
}

/// Default zen garden hit tester instance for injection in theme screens.
class ZenGardenHitTester implements SandboxHitTester {
  const ZenGardenHitTester();

  @override
  SandboxEntityRef? nearestPick(
    double nx,
    double ny,
    GardenState garden, {
    Size gardenSize = zenReferenceGardenSize,
  }) =>
      zenGardenNearestPick(nx, ny, garden, gardenSize: gardenSize);
}
