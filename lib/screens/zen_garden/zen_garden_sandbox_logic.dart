import 'dart:ui';

import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/zen_placeable_bounds.dart';

enum ZenPaintEntityKind { plant, decor }

class ZenPaintEntity {
  const ZenPaintEntity({
    required this.kind,
    required this.id,
    required this.displayX,
    required this.displayY,
    required this.plant,
    required this.decor,
  });

  final ZenPaintEntityKind kind;
  final String id;
  final double displayX;
  final double displayY;
  final GardenItem? plant;
  final DecorItem? decor;
}

/// Depth-sorted paint list with cosmetic separation offsets (logical positions unchanged).
List<ZenPaintEntity> zenBuildPaintEntities(
  GardenState garden,
  Size gardenSize, {
  Map<String, Offset>? plantOverrides,
  Map<String, Offset>? decorOverrides,
}) {
  final dragging = (plantOverrides?.isNotEmpty ?? false) ||
      (decorOverrides?.isNotEmpty ?? false);
  final boundsEntries = <({String id, Rect bounds})>[];
  final staging = <ZenPaintEntity>[];

  for (final p in garden.items) {
    final pos = plantOverrides?[p.id] ?? Offset(p.positionX, p.positionY);
    final bounds = zenPlantVisualNormRect(
      p.copyWith(positionX: pos.dx, positionY: pos.dy),
      gardenSize,
    );
    boundsEntries.add((id: p.id, bounds: bounds));
    staging.add(
      ZenPaintEntity(
        kind: ZenPaintEntityKind.plant,
        id: p.id,
        displayX: pos.dx,
        displayY: pos.dy,
        plant: p,
        decor: null,
      ),
    );
  }
  for (final d in garden.decor) {
    final pos = decorOverrides?[d.id] ?? Offset(d.positionX, d.positionY);
    final bounds = zenDecorVisualNormRect(
      d.copyWith(positionX: pos.dx, positionY: pos.dy),
      gardenSize,
    );
    boundsEntries.add((id: d.id, bounds: bounds));
    staging.add(
      ZenPaintEntity(
        kind: ZenPaintEntityKind.decor,
        id: d.id,
        displayX: pos.dx,
        displayY: pos.dy,
        plant: null,
        decor: d,
      ),
    );
  }

  staging.sort((a, b) {
    final ka = zenEntityPaintOrderKey(a.displayY, isPlant: a.kind == ZenPaintEntityKind.plant);
    final kb = zenEntityPaintOrderKey(b.displayY, isPlant: b.kind == ZenPaintEntityKind.plant);
    return ka.compareTo(kb);
  });

  final boundsById = {for (final b in boundsEntries) b.id: b.bounds};

  return [
    for (final e in staging)
      if (dragging)
        e
      else
        ZenPaintEntity(
          kind: e.kind,
          id: e.id,
          displayX: e.displayX +
              zenVisualSeparationOffset(
                id: e.id,
                selfBounds: boundsById[e.id]!,
                others: boundsEntries,
              ).dx,
          displayY: e.displayY +
              zenVisualSeparationOffset(
                id: e.id,
                selfBounds: boundsById[e.id]!,
                others: boundsEntries,
              ).dy,
          plant: e.plant,
          decor: e.decor,
        ),
  ];
}
