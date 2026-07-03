import 'garden_state.dart';

/// Which part of the tree was just grown (for pop-in animation).
enum CherryBlossomGrowthKind { base, branch, leaf }

class CherryBlossomGrowthFocus {
  const CherryBlossomGrowthFocus({required this.kind, this.slotIndex = 0});

  final CherryBlossomGrowthKind kind;
  final int slotIndex;

  @override
  bool operator ==(Object other) =>
      other is CherryBlossomGrowthFocus &&
      other.kind == kind &&
      other.slotIndex == slotIndex;

  @override
  int get hashCode => Object.hash(kind, slotIndex);
}

/// One fast-grow step: garden after the upgrade and which piece popped in.
class CherryBlossomGrowthStep {
  const CherryBlossomGrowthStep({
    required this.focus,
    required this.gardenAfter,
  });

  final CherryBlossomGrowthFocus focus;
  final GardenState gardenAfter;
}
