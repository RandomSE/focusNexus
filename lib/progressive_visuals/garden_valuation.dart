import 'decor_catalog.dart';
import 'decor_item.dart';
import 'garden_item.dart';
import 'zen_garden_rules.dart';

/// Cumulative point cost to reach [stageIndex] from a fresh purchase (decor).
int decorInvestmentPoints(String kind, int stageIndex) {
  final base = decorPrice(kind) ?? 0;
  final rules = zenGardenTransitionRules();
  var growth = 0;
  for (var s = 0; s < stageIndex && s < rules.length; s++) {
    growth += rules[s].pointCost;
  }
  return base + growth;
}

/// Sell value for a decor item — half of investment, independent of restart discounts.
int decorSellValue(DecorItem item) => decorInvestmentPoints(item.kind, item.stageIndex) ~/ 2;

/// Cumulative growth cost for a plant at [stageIndex] (no purchase price).
int plantInvestmentPoints(int stageIndex) {
  final rules = zenGardenTransitionRules();
  var growth = 0;
  for (var s = 0; s < stageIndex && s < rules.length; s++) {
    growth += rules[s].pointCost;
  }
  return growth;
}

int plantSellValue(GardenItem item) => plantInvestmentPoints(item.stageIndex) ~/ 2;

/// Human-readable label for inventory / placement UI.
String zenDecorKindLabel(String kind) => decorEntryByKind(kind)?.label ?? kind;
