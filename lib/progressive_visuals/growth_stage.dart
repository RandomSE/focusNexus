/// Logical growth steps shared across all visual metaphors (garden, coral, sky, …).
enum GrowthStage {
  seed,
  sprout,
  vegetative,
  bloom,
  mature,
}

extension GrowthStageIndex on GrowthStage {
  int get index => GrowthStage.values.indexOf(this);
}

GrowthStage growthStageFromIndex(int index) {
  if (index < 0 || index >= GrowthStage.values.length) {
    throw RangeError.index(index, GrowthStage.values, 'index', null, GrowthStage.values.length);
  }
  return GrowthStage.values[index];
}
