import 'dart:math' as math;
import 'dart:ui';

import 'decor_item.dart';
import 'garden_item.dart';
import 'garden_state.dart';
import 'sandbox_entity.dart';
import 'visual_theme_id.dart';

import '../screens/zen_garden/zen_placeable_layout.dart';
import '../screens/zen_garden/zen_garden_decor_painters.dart';
/// Pixel footprint of decor / plant widgets on the zen garden canvas.
const double zenDecorVisualWidth = 96;
const double zenDecorVisualHeight = 90;
const double zenPlantVisualWidth = 96;
const double zenPlantVisualHeight = 118;

/// Reference garden size for norm-space hit tests when live size is unknown.
const Size zenReferenceGardenSize = Size(360, 480);

/// Converts a pixel half-extent on the garden canvas to normalized coordinates.
double zenNormHalfExtent(double pixels, double gardenAxis) {
  if (gardenAxis <= 0) return 0;
  return (pixels / 2) / gardenAxis;
}

/// Normalized axis-aligned bounds for an entity's visual footprint (logical position).
Rect zenPlantVisualNormRect(GardenItem item, Size gardenSize) {
  final center = Offset(item.positionX, item.positionY) +
      zenPlantVisualCenterOffsetNorm(item, gardenSize);
  final (pw, ph) = zenPlantHitFootprintPx(item);
  return Rect.fromCenter(
    center: center,
    width: pw / gardenSize.width,
    height: ph / gardenSize.height,
  );
}

Rect zenDecorVisualNormRect(DecorItem item, Size gardenSize) {
  if (item.kind == 'zen.stone_path') {
    return zenStonePathUnionNormRect(item, gardenSize);
  }
  final center = Offset(item.positionX, item.positionY) +
      zenDecorVisualCenterOffsetNorm(item, gardenSize);
  final (pw, ph) = zenDecorHitFootprintPx(item);
  return Rect.fromCenter(
    center: center,
    width: pw / gardenSize.width,
    height: ph / gardenSize.height,
  );
}

bool zenPlantHitNorm(
  double nx,
  double ny,
  GardenItem item, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  final rect = zenPlantVisualNormRect(item, gardenSize);
  return rect.inflate(0.008).contains(Offset(nx, ny));
}

bool zenDecorHitNorm(
  double nx,
  double ny,
  DecorItem d, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  if (d.kind == 'zen.stone_path') {
    return zenStonePathHitNorm(nx, ny, d, gardenSize);
  }
  return zenDecorVisualNormRect(d, gardenSize).inflate(0.006).contains(Offset(nx, ny));
}

double _distToRectCenter(double nx, double ny, Rect rect) {
  final c = rect.center;
  return math.sqrt(math.pow(nx - c.dx, 2) + math.pow(ny - c.dy, 2));
}

/// Picks the nearest entity whose visual bounds contain the tap.
SandboxEntityRef? zenGardenNearestPick(
  double nx,
  double ny,
  GardenState garden, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  final candidates = <({SandboxEntityRef pick, double dist})>[];
  for (final p in garden.items) {
    if (!zenPlantHitNorm(nx, ny, p, gardenSize: gardenSize)) continue;
    final d = _distToRectCenter(nx, ny, zenPlantVisualNormRect(p, gardenSize));
    candidates.add((
      pick: SandboxEntityRef(id: p.id, kind: SandboxEntityKind.primary),
      dist: d,
    ));
  }
  for (final d in garden.decor) {
    if (!zenDecorHitNorm(nx, ny, d, gardenSize: gardenSize)) continue;
    final dist = _distToRectCenter(nx, ny, zenDecorVisualNormRect(d, gardenSize));
    candidates.add((
      pick: SandboxEntityRef(id: d.id, kind: SandboxEntityKind.decoration),
      dist: dist,
    ));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final dc = a.dist.compareTo(b.dist);
    if (dc != 0) return dc;
    if (a.pick.isPrimary != b.pick.isPrimary) {
      return a.pick.isPrimary ? -1 : 1;
    }
    return a.pick.id.compareTo(b.pick.id);
  });
  return candidates.first.pick;
}

/// Half-extents in normalized coords for keeping the visual on screen (not separation).
(double, double) zenPlantPlacementMargins(
  GardenItem item, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  final rect = zenPlantVisualNormRect(item, gardenSize);
  return (rect.width / 2, rect.height / 2);
}

(double, double) zenDecorPlacementMargins(
  DecorItem item, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  final rect = zenDecorVisualNormRect(item, gardenSize);
  return (rect.width / 2, rect.height / 2);
}

(double, double) zenDecorKindPlacementMargins(
  String kind,
  int stageIndex, {
  Size gardenSize = zenReferenceGardenSize,
}) {
  return zenDecorPlacementMargins(
    DecorItem(
      id: '_',
      themeId: VisualThemeId.zenGarden,
      kind: kind,
      stageIndex: stageIndex,
    ),
    gardenSize: gardenSize,
  );
}

/// Entities whose visual bounds intersect [normRect] (for box selection).
void zenGardenCollectInNormRect(
  Rect normRect,
  GardenState garden,
  Size gardenSize, {
  required Set<String> bulkPrimary,
  required Set<String> bulkDecor,
}) {
  for (final p in garden.items) {
    if (zenPlantVisualNormRect(p, gardenSize).overlaps(normRect)) {
      bulkPrimary.add(p.id);
    }
  }
  for (final d in garden.decor) {
    if (zenDecorVisualNormRect(d, gardenSize).overlaps(normRect)) {
      bulkDecor.add(d.id);
    }
  }
}

/// Paint order key — lower [positionY] draws first (behind).
double zenEntityPaintOrderKey(double positionY, {required bool isPlant}) {
  return positionY + (isPlant ? 0.0001 : 0);
}

/// Cosmetic display offset so overlapping visuals separate slightly (logical pos unchanged).
Offset zenVisualSeparationOffset({
  required String id,
  required Rect selfBounds,
  required Iterable<({String id, Rect bounds})> others,
}) {
  var ox = 0.0;
  var oy = 0.0;
  for (final other in others) {
    if (other.id == id) continue;
    final overlap = selfBounds.intersect(other.bounds);
    if (overlap.isEmpty) continue;
    final overlapArea = overlap.width * overlap.height;
    final selfArea = selfBounds.width * selfBounds.height;
    if (selfArea <= 0 || overlapArea / selfArea < 0.08) continue;
    final dx = selfBounds.center.dx - other.bounds.center.dx;
    final dy = selfBounds.center.dy - other.bounds.center.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) continue;
    final push = math.min(0.012, overlapArea * 0.04);
    ox += (dx / len) * push;
    oy += (dy / len) * push;
  }
  return Offset(ox.clamp(-0.025, 0.025), oy.clamp(-0.025, 0.025));
}

/// Clamps a group move delta so every member stays inside garden margins.
({double dx, double dy}) zenClampGroupDelta({
  required double dx,
  required double dy,
  required Iterable<({double x, double y, double rx, double ry})> members,
}) {
  var maxDxPos = double.infinity;
  var maxDxNeg = double.infinity;
  var maxDyPos = double.infinity;
  var maxDyNeg = double.infinity;
  for (final m in members) {
    maxDxPos = math.min(maxDxPos, 1 - m.rx - m.x);
    maxDxNeg = math.min(maxDxNeg, m.x - m.rx);
    maxDyPos = math.min(maxDyPos, 1 - m.ry - m.y);
    maxDyNeg = math.min(maxDyNeg, m.y - m.ry);
  }
  return (
    dx: dx.clamp(-maxDxNeg, maxDxPos),
    dy: dy.clamp(-maxDyNeg, maxDyPos),
  );
}
