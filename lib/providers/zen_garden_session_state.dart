import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/sandbox_entity.dart';
import 'package:focusNexus/progressive_visuals/zen_placeable_bounds.dart'
    show zenReferenceGardenSize;

/// Ephemeral drag state for a single placeable.
class ZenDragSession {
  const ZenDragSession({
    required this.isPlant,
    required this.id,
    required this.nx,
    required this.ny,
  });

  final bool isPlant;
  final String id;
  final double nx;
  final double ny;

  ZenDragSession copyWith({double? nx, double? ny}) {
    return ZenDragSession(
      isPlant: isPlant,
      id: id,
      nx: nx ?? this.nx,
      ny: ny ?? this.ny,
    );
  }
}

/// Bulk drag offsets for multi-select moves.
class ZenBulkDragSession {
  const ZenBulkDragSession({
    required this.anchorNx,
    required this.anchorNy,
    required this.plantOrigins,
    required this.decorOrigins,
    this.dx = 0,
    this.dy = 0,
  });

  final double anchorNx;
  final double anchorNy;
  final Map<String, Offset> plantOrigins;
  final Map<String, Offset> decorOrigins;
  final double dx;
  final double dy;

  ZenBulkDragSession copyWith({double? dx, double? dy}) {
    return ZenBulkDragSession(
      anchorNx: anchorNx,
      anchorNy: anchorNy,
      plantOrigins: plantOrigins,
      decorOrigins: decorOrigins,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
    );
  }
}

/// Riverpod-driven UI state for [ZenGardenScreen] (controllers stay on the widget).
class ZenGardenSessionState {
  const ZenGardenSessionState({
    required this.garden,
    required this.generation,
    this.chromeVisible = true,
    this.placingDecorInventoryId,
    this.placingPlant = false,
    this.placingPlantInventoryId,
    this.gardenLayoutSize = zenReferenceGardenSize,
    this.bulkPlantPreview,
    this.bulkDecorPreview,
    this.pointerDownGlobal,
    this.pointerPick,
    this.pointerDragging = false,
    this.areaSelectStartNorm,
    this.areaSelectCurrentNorm,
    this.areaSelecting = false,
    this.viewportMoved = false,
    this.drag,
    this.bulkDrag,
  });

  factory ZenGardenSessionState.initial() {
    return const ZenGardenSessionState(
      garden: GardenState(pointsBalance: 0, items: []),
      generation: 0,
    );
  }

  final GardenState garden;
  final int generation;
  final bool chromeVisible;
  final String? placingDecorInventoryId;
  final bool placingPlant;
  final String? placingPlantInventoryId;
  final Size gardenLayoutSize;
  final Map<String, Offset>? bulkPlantPreview;
  final Map<String, Offset>? bulkDecorPreview;
  final Offset? pointerDownGlobal;
  final SandboxEntityRef? pointerPick;
  final bool pointerDragging;
  final Offset? areaSelectStartNorm;
  final Offset? areaSelectCurrentNorm;
  final bool areaSelecting;
  final bool viewportMoved;
  final ZenDragSession? drag;
  final ZenBulkDragSession? bulkDrag;

  ZenGardenSessionState copyWith({
    GardenState? garden,
    int? generation,
    bool? chromeVisible,
    String? placingDecorInventoryId,
    bool? placingPlant,
    String? placingPlantInventoryId,
    Size? gardenLayoutSize,
    Map<String, Offset>? bulkPlantPreview,
    Map<String, Offset>? bulkDecorPreview,
    Offset? pointerDownGlobal,
    SandboxEntityRef? pointerPick,
    bool? pointerDragging,
    Offset? areaSelectStartNorm,
    Offset? areaSelectCurrentNorm,
    bool? areaSelecting,
    bool? viewportMoved,
    ZenDragSession? drag,
    ZenBulkDragSession? bulkDrag,
    bool clearPlacingDecorInventoryId = false,
    bool clearPlacingPlantInventoryId = false,
    bool clearPointerDownGlobal = false,
    bool clearPointerPick = false,
    bool clearAreaSelectStart = false,
    bool clearAreaSelectCurrent = false,
    bool clearDrag = false,
    bool clearBulkDrag = false,
    bool clearBulkPlantPreview = false,
    bool clearBulkDecorPreview = false,
  }) {
    return ZenGardenSessionState(
      garden: garden ?? this.garden,
      generation: generation ?? this.generation,
      chromeVisible: chromeVisible ?? this.chromeVisible,
      placingDecorInventoryId: clearPlacingDecorInventoryId
          ? null
          : (placingDecorInventoryId ?? this.placingDecorInventoryId),
      placingPlant: placingPlant ?? this.placingPlant,
      placingPlantInventoryId: clearPlacingPlantInventoryId
          ? null
          : (placingPlantInventoryId ?? this.placingPlantInventoryId),
      gardenLayoutSize: gardenLayoutSize ?? this.gardenLayoutSize,
      bulkPlantPreview: clearBulkPlantPreview
          ? null
          : (bulkPlantPreview ?? this.bulkPlantPreview),
      bulkDecorPreview: clearBulkDecorPreview
          ? null
          : (bulkDecorPreview ?? this.bulkDecorPreview),
      pointerDownGlobal: clearPointerDownGlobal
          ? null
          : (pointerDownGlobal ?? this.pointerDownGlobal),
      pointerPick:
          clearPointerPick ? null : (pointerPick ?? this.pointerPick),
      pointerDragging: pointerDragging ?? this.pointerDragging,
      areaSelectStartNorm: clearAreaSelectStart
          ? null
          : (areaSelectStartNorm ?? this.areaSelectStartNorm),
      areaSelectCurrentNorm: clearAreaSelectCurrent
          ? null
          : (areaSelectCurrentNorm ?? this.areaSelectCurrentNorm),
      areaSelecting: areaSelecting ?? this.areaSelecting,
      viewportMoved: viewportMoved ?? this.viewportMoved,
      drag: clearDrag ? null : (drag ?? this.drag),
      bulkDrag: clearBulkDrag ? null : (bulkDrag ?? this.bulkDrag),
    );
  }

  ZenGardenSessionState bump() => copyWith(generation: generation + 1);
}
