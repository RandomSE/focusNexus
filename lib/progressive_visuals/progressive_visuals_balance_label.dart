import 'package:focusNexus/progressive_visuals/garden_state.dart';

/// Dual wallet label for progressive-visuals surfaces.
String progressiveVisualsBalanceLabel(GardenState garden) {
  return 'PV: ${garden.progressiveVisualsPointsBalance} · Points: ${garden.pointsBalance}';
}

String progressiveVisualsBalanceLabelFromParts({
  required int progressiveVisualsPoints,
  required int points,
}) {
  return 'PV: $progressiveVisualsPoints · Points: $points';
}
