import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_op_result.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/growth_stage.dart';
import 'package:focusNexus/progressive_visuals/sandbox_entity.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';
import 'package:focusNexus/progressive_visuals/sandbox_viewport.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/progressive_visuals/garden_valuation.dart';
import 'package:focusNexus/progressive_visuals/zen_placeable_bounds.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_hit_test.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:intl/intl.dart';

import 'zen_garden_cartoon_style.dart';
import 'zen_garden_decor_visual.dart';
import 'zen_garden_painters.dart';
import 'zen_inventory_stacks.dart';
import 'zen_placeable_layout.dart';
import 'zen_garden_sandbox_logic.dart';
import 'zen_garden_static_scenery.dart';
import 'zen_garden_waterfall.dart';

String zenGardenStageLabel(int index) {
  final stage = growthStageFromIndex(index);
  return switch (stage) {
    GrowthStage.seed => 'seed',
    GrowthStage.sprout => 'sprout',
    GrowthStage.vegetative => 'full foliage',
    GrowthStage.bloom => 'bloom',
    GrowthStage.mature => 'mature tree',
  };
}

Duration _zenWaitAfterAdvancingFrom(int fromStage) {
  final rules = zenGardenTransitionRules();
  if (fromStage < 0) {
    return rules.first.waitBeforeNextAdvance ?? const Duration(minutes: 2);
  }
  final r = rules.firstWhere((x) => x.fromStageIndex == fromStage);
  return r.waitBeforeNextAdvance ?? const Duration(minutes: 2);
}

class _DragSession {
  _DragSession({
    required this.isPlant,
    required this.id,
    required this.nx,
    required this.ny,
  });

  final bool isPlant;
  final String id;
  double nx;
  double ny;
}

class _BulkDragSession {
  _BulkDragSession({
    required this.anchorNx,
    required this.anchorNy,
    required this.plantOrigins,
    required this.decorOrigins,
  });

  final double anchorNx;
  final double anchorNy;
  final Map<String, Offset> plantOrigins;
  final Map<String, Offset> decorOrigins;
  double dx = 0;
  double dy = 0;
}

/// Calm, playable Zen garden: plants, growth, decorations, selection, drag preview.
class ZenGardenScreen extends StatefulWidget {
  const ZenGardenScreen({
    super.key,
    required this.themeData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
  });

  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;

  @override
  State<ZenGardenScreen> createState() => _ZenGardenScreenState();
}

class _AreaSelectBoxPainter extends CustomPainter {
  _AreaSelectBoxPainter({
    required this.startNorm,
    required this.endNorm,
    required this.color,
  });

  final Offset startNorm;
  final Offset endNorm;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(
      Offset(startNorm.dx * size.width, startNorm.dy * size.height),
      Offset(endNorm.dx * size.width, endNorm.dy * size.height),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaSelectBoxPainter oldDelegate) {
    return oldDelegate.startNorm != startNorm ||
        oldDelegate.endNorm != endNorm ||
        oldDelegate.color != color;
  }
}

class _ZenGardenScreenState extends State<ZenGardenScreen>
    with SingleTickerProviderStateMixin {
  final _repos = AppRepositories.instance;
  final _engine = ProgressiveGardenEngine(
    transitionRules: zenGardenTransitionRules(),
    // TODO: change to 0.05 once testing concludes.
    mutationProbability: 0.5,
  );
  final _random = Random();

  GardenState _garden = const GardenState(pointsBalance: 0, items: []);
  final SandboxSelectionState _selection = SandboxSelectionState();
  final SandboxHitTester _hitTester = const ZenGardenHitTester();
  final TransformationController _viewportTransform = TransformationController();
  bool _chromeVisible = true;
  String? _placingDecorInventoryId;
  bool _placingPlant = false;
  String? _placingPlantInventoryId;
  _DragSession? _drag;
  _BulkDragSession? _bulkDrag;
  Size _gardenLayoutSize = zenReferenceGardenSize;
  Map<String, Offset>? _bulkPlantPreview;
  Map<String, Offset>? _bulkDecorPreview;
  Offset? _pointerDownGlobal;
  SandboxEntityRef? _pointerPick;
  bool _pointerDragging = false;
  Offset? _areaSelectStartNorm;
  Offset? _areaSelectCurrentNorm;
  bool _areaSelecting = false;
  bool _viewportMoved = false;
  Timer? _ticker;
  late final AnimationController _viewportResetAnim;
  bool _centeringViewport = false;
  Future<void>? _gardenLoadFuture;

  static const double _pointerSlop = 14.0;
  static const double _plantVisualW = zenPlantVisualWidth;
  static const double _plantVisualH = zenPlantVisualHeight;
  static const double _decorVisualW = zenDecorVisualWidth;
  static const double _decorVisualH = zenDecorVisualHeight;

  Duration get _zenFirstWait =>
      zenGardenTransitionRules().firstWhere((r) => r.fromStageIndex == 0).waitBeforeNextAdvance ??
      const Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _viewportResetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _viewportTransform.addListener(_syncViewportMoved);
  }

  @override
  void dispose() {
    _viewportTransform.removeListener(_syncViewportMoved);
    _viewportResetAnim.dispose();
    _ticker?.cancel();
    _viewportTransform.dispose();
    super.dispose();
  }

  void _syncViewportMoved() {
    final moved = !sandboxViewportIsDefault(_viewportTransform.value);
    if (moved != _viewportMoved && mounted) {
      setState(() => _viewportMoved = moved);
    }
  }

  Future<void> _centerViewport() async {
    if (_centeringViewport) return;
    _centeringViewport = true;
    try {
      if (sandboxViewportIsDefault(_viewportTransform.value)) {
        resetSandboxViewport(_viewportTransform);
        _syncViewportMoved();
        return;
      }

      _viewportResetAnim.stop();
      _viewportResetAnim.reset();
      final begin = _viewportTransform.value.clone();
      final curve = CurvedAnimation(
        parent: _viewportResetAnim,
        curve: Curves.easeOutCubic,
      );
      void tick() {
        _viewportTransform.value = lerpSandboxViewportMatrix(
          begin,
          Matrix4.identity(),
          curve.value,
        );
      }

      _viewportResetAnim.addListener(tick);
      try {
        await _viewportResetAnim.forward();
      } finally {
        _viewportResetAnim.removeListener(tick);
        curve.dispose();
      }
      resetSandboxViewport(_viewportTransform);
      _syncViewportMoved();
    } finally {
      _centeringViewport = false;
    }
  }

  Future<void> _loadGarden() async {
    final garden = await _repos.garden.load();
    if (!mounted) return;
    setState(() => _garden = garden);
    _syncTicker();
  }

  void _syncTicker() {
    bool waiting(dynamic x) =>
        x.nextAdvanceAllowedAt != null &&
        DateTime.now().isBefore(x.nextAdvanceAllowedAt!);
    final needs =
        _garden.items.any(waiting) || _garden.decor.any(waiting);
    _ticker?.cancel();
    if (!needs) {
      _ticker = null;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final still =
          _garden.items.any(waiting) || _garden.decor.any(waiting);
      if (!still) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  Future<void> _persist() async {
    await _repos.garden.save(_garden);
  }

  void _apply(GardenOpResult result, {String? announce}) {
    if (!result.isSuccess) {
      _snack(result.error ?? 'Something went wrong');
      return;
    }
    setState(() {
      _garden = result.state!;
    });
    _syncTicker();
    _persist();
    if (announce != null && announce.isNotEmpty) {
      SemanticsService.announce(announce, Directionality.of(context));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _clearPlacementPrompts() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  SandboxEntityRef? _focusedEntityRef() {
    final pid = _selection.focusPrimaryId;
    if (pid != null) {
      return SandboxEntityRef(id: pid, kind: SandboxEntityKind.primary);
    }
    final did = _selection.focusDecorId;
    if (did != null) {
      return SandboxEntityRef(id: did, kind: SandboxEntityKind.decoration);
    }
    return null;
  }

  void _exitSelectionForPlacement() {
    _selection.setMultiMode(false);
    _selection.clearAll();
  }

  DecorItem? _decorInventoryItem(String? id) {
    if (id == null) return null;
    for (final d in _garden.decorInventory) {
      if (d.id == id) return d;
    }
    return null;
  }

  GardenItem? _plantInventoryItem(String? id) {
    if (id == null) return null;
    for (final p in _garden.plantInventory) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get _isPlacing => _placingDecorInventoryId != null || _placingPlant;

  String? get _placingLabel {
    if (_placingPlant) {
      final invPlant = _plantInventoryItem(_placingPlantInventoryId);
      if (invPlant != null) {
        final mut = invPlant.mutation != null ? ' · variant' : '';
        return 'plant (${zenGardenStageLabel(invPlant.stageIndex)})$mut';
      }
      return 'seed';
    }
    final invDecor = _decorInventoryItem(_placingDecorInventoryId);
    if (invDecor != null) {
      final label = decorEntryByKind(invDecor.kind)?.label ?? invDecor.kind;
      final mut = invDecor.mutation != null ? ' · variant' : '';
      return '$label · stage ${invDecor.stageIndex + 1}$mut';
    }
    return null;
  }

  void _cancelPlacement() {
    setState(() {
      _placingDecorInventoryId = null;
      _placingPlant = false;
      _placingPlantInventoryId = null;
    });
    _clearPlacementPrompts();
  }

  GardenItem? get _focusPlant {
    final id = _selection.focusPrimaryId;
    if (id == null) return null;
    try {
      return _garden.items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  DecorItem? get _focusDecor {
    final id = _selection.focusDecorId;
    if (id == null) return null;
    try {
      return _garden.decor.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setMultiMode(bool v) {
    setState(() {
      _selection.setMultiMode(v);
      if (v) {
        _cancelPlacement();
      }
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  void _bulkStashToInventory() {
    final pn = Set<String>.from(_selection.bulkPrimary);
    final dn = Set<String>.from(_selection.bulkDecor);
    if (pn.isEmpty && dn.isEmpty) {
      _snack('Select items first.');
      return;
    }
    var next = _garden;
    if (pn.isNotEmpty) {
      final r = _engine.stashPlantsToInventoryBulk(next, pn);
      if (!r.isSuccess) {
        _snack(r.error ?? 'Could not remove plants');
        return;
      }
      next = r.state!;
    }
    if (dn.isNotEmpty) {
      final r = _engine.stashDecorsToInventoryBulk(next, dn);
      if (!r.isSuccess) {
        _snack(r.error ?? 'Could not remove decorations');
        return;
      }
      next = r.state!;
    }
    setState(() {
      _garden = next;
      _selection.bulkPrimary.clear();
      _selection.bulkDecor.clear();
    });
    _persist();
    SemanticsService.announce('Moved selection to inventory.', Directionality.of(context));
  }

  void _startPlantPlacement() {
    setState(() {
      _placingPlant = true;
      _placingPlantInventoryId = null;
      _placingDecorInventoryId = null;
      _exitSelectionForPlacement();
    });
  }

  void _placePlantAt(double nx, double ny) {
    final seed = GardenItem(id: 'tmp', themeId: VisualThemeId.zenGarden);
    final (mrx, mry) = _placingPlantInventoryId != null
        ? zenPlantPlacementMargins(
            _garden.plantInventory.firstWhere(
              (p) => p.id == _placingPlantInventoryId,
            ),
            gardenSize: _gardenLayoutSize,
          )
        : zenPlantPlacementMargins(seed, gardenSize: _gardenLayoutSize);
    final resolved = _resolvePlacement(
      nx: nx,
      ny: ny,
      moverRx: mrx,
      moverRy: mry,
    );
    _clearPlacementPrompts();
    final fromInventoryId = _placingPlantInventoryId;
    String? plantStackKey;
    if (fromInventoryId != null) {
      final source = _plantInventoryItem(fromInventoryId);
      if (source != null) {
        plantStackKey = plantInventoryStackKey(source);
      }
    }
    final GardenOpResult r;
    if (fromInventoryId != null) {
      r = _engine.placePlantFromInventory(
        state: _garden,
        inventoryItemId: fromInventoryId,
        x: resolved.x,
        y: resolved.y,
      );
    } else {
      final id = 'zen_${DateTime.now().millisecondsSinceEpoch}';
      r = _engine.placeItem(
        state: _garden,
        id: id,
        themeId: VisualThemeId.zenGarden,
        x: resolved.x,
        y: resolved.y,
      );
    }
    if (!r.isSuccess) {
      _snack(r.error ?? 'Could not place plant');
      return;
    }
    final placedId = fromInventoryId ?? r.state!.items.last.id;
    setState(() {
      _garden = r.state!;
      _exitSelectionForPlacement();
      if (fromInventoryId != null && plantStackKey != null) {
        _placingPlantInventoryId =
            nextPlantInventoryIdInStack(_garden.plantInventory, plantStackKey);
        _placingPlant = _placingPlantInventoryId != null;
      } else {
        _placingPlant = false;
        _placingPlantInventoryId = null;
      }
      _selection.applyPick(
        SandboxEntityRef(id: placedId, kind: SandboxEntityKind.primary),
      );
    });
    _syncTicker();
    _persist();
    SemanticsService.announce('Plant placed.', Directionality.of(context));
  }

  void _showShopToast(String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final mq = MediaQuery.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: mq.padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.inverseSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 2), entry.remove);
  }

  void _openShop() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _ZenShopSheet(
        textStyle: widget.textStyle,
        primary: widget.primaryColor,
        garden: _garden,
        engine: _engine,
        onPurchased: (r) {
          _apply(r, announce: r.isSuccess ? 'Inventory updated.' : null);
        },
        onUserMessage: _showShopToast,
      ),
    );
  }

  void _applyInventoryOp(
    GardenOpResult result, {
    String? announce,
    int? pointsEarned,
  }) {
    if (!result.isSuccess) {
      _snack(result.error ?? 'Something went wrong');
      return;
    }
    setState(() => _garden = result.state!);
    _syncTicker();
    _persist();
    if (pointsEarned != null && pointsEarned > 0) {
      _showShopToast('Sold for +$pointsEarned points');
    } else if (announce != null && announce.isNotEmpty) {
      _snack(announce);
    }
    if (announce != null && announce.isNotEmpty && mounted) {
      SemanticsService.announce(announce, Directionality.of(context));
    }
  }

  ({double nx, double ny}) _clampDragNorm({
    required double nx,
    required double ny,
    required bool isPlant,
    required String id,
  }) {
    final (mx, my) = isPlant
        ? zenPlantPlacementMargins(
            _garden.items.firstWhere((e) => e.id == id),
            gardenSize: _gardenLayoutSize,
          )
        : zenDecorPlacementMargins(
            _garden.decor.firstWhere((e) => e.id == id),
            gardenSize: _gardenLayoutSize,
          );
    return (nx: nx.clamp(mx, 1 - mx), ny: ny.clamp(my, 1 - my));
  }

  ({double x, double y}) _resolvePlacement({
    required double nx,
    required double ny,
    required double moverRx,
    required double moverRy,
  }) {
    final resolved = resolveZenGardenPlacement(
      nx: nx,
      ny: ny,
      moverRx: moverRx,
      moverRy: moverRy,
    );
    return (x: resolved.x, y: resolved.y);
  }

  void _openInventory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            void refreshSheet() {
              if (mounted) setState(() {});
              setSheetState(() {});
            }

            final plantStacks = groupPlantInventory(_garden.plantInventory);
            final decorStacks = groupDecorInventory(_garden.decorInventory);
            final isEmpty = plantStacks.isEmpty && decorStacks.isEmpty;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Inventory',
                            style: widget.textStyle.copyWith(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  if (isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Inventory is empty. Buy decorations from the shop or move items here from the garden.',
                        style: widget.textStyle.copyWith(fontWeight: FontWeight.normal),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (plantStacks.isNotEmpty) ...[
                            Text('Plants', style: widget.textStyle.copyWith(fontSize: 15)),
                            const SizedBox(height: 8),
                            ...plantStacks.map((stack) {
                              final p = stack.representative;
                              final sell = plantSellValue(p);
                              final countLabel =
                                  stack.count > 1 ? ' ×${stack.count}' : '';
                              return ListTile(
                                leading: Badge(
                                  isLabelVisible: stack.count > 1,
                                  label: Text('${stack.count}'),
                                  child: const Icon(Icons.grass_outlined),
                                ),
                                title: Text(
                                  'Plant · ${zenGardenStageLabel(p.stageIndex)}$countLabel',
                                ),
                                subtitle: Text('Sell: $sell pts each'),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () {
                                        Navigator.pop(sheetCtx);
                                        setState(() {
                                          _placingPlant = true;
                                          _placingPlantInventoryId =
                                              stack.placeOrSellItemId;
                                          _placingDecorInventoryId = null;
                                          _exitSelectionForPlacement();
                                        });
                                      },
                                      child: const Text('Place'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        final itemId = stack.placeOrSellItemId;
                                        _applyInventoryOp(
                                          _engine.sellPlantInventoryItem(
                                            _garden,
                                            itemId,
                                          ),
                                          announce: 'Sold plant for $sell points.',
                                          pointsEarned: sell,
                                        );
                                        if (_placingPlantInventoryId == itemId) {
                                          final stackKey =
                                              plantInventoryStackKey(p);
                                          _placingPlantInventoryId =
                                              nextPlantInventoryIdInStack(
                                            _garden.plantInventory,
                                            stackKey,
                                          );
                                          _placingPlant =
                                              _placingPlantInventoryId != null;
                                        }
                                        refreshSheet();
                                        if (_garden.plantInventory.isEmpty &&
                                            _garden.decorInventory.isEmpty) {
                                          Navigator.pop(sheetCtx);
                                        }
                                      },
                                      child: const Text('Sell 1'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          if (decorStacks.isNotEmpty) ...[
                            Text('Decorations', style: widget.textStyle.copyWith(fontSize: 15)),
                            const SizedBox(height: 8),
                            ...decorStacks.map((stack) {
                              final d = stack.representative;
                              final meta = decorEntryByKind(d.kind);
                              final sell = decorSellValue(d);
                              final stackKey = decorInventoryStackKey(d);
                              final placingThis =
                                  _placingDecorInventoryId != null &&
                                  stack.itemIds.contains(_placingDecorInventoryId);
                              final countLabel =
                                  stack.count > 1 ? ' ×${stack.count}' : '';
                              return ListTile(
                                leading: Badge(
                                  isLabelVisible: stack.count > 1,
                                  label: Text('${stack.count}'),
                                  child: Icon(meta?.icon ?? Icons.inventory_2_outlined),
                                ),
                                title: Text('${meta?.label ?? d.kind}$countLabel'),
                                subtitle: Text(
                                  'Stage ${d.stageIndex + 1} · Sell: $sell pts each'
                                  '${d.mutation != null ? ' · variant' : ''}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () {
                                        Navigator.pop(sheetCtx);
                                        setState(() {
                                          _placingDecorInventoryId =
                                              stack.sellItemId;
                                          _placingPlant = false;
                                          _placingPlantInventoryId = null;
                                          _exitSelectionForPlacement();
                                        });
                                      },
                                      child: Text(placingThis ? 'Placing…' : 'Place'),
                                    ),
                                    if (placingThis)
                                      TextButton(
                                        onPressed: () {
                                          setState(() => _placingDecorInventoryId = null);
                                          _clearPlacementPrompts();
                                          refreshSheet();
                                        },
                                        child: const Text('Deselect'),
                                      ),
                                    OutlinedButton(
                                      onPressed: () {
                                        final itemId = stack.sellItemId;
                                        _applyInventoryOp(
                                          _engine.sellDecorInventoryItem(
                                            _garden,
                                            itemId,
                                          ),
                                          announce: 'Sold decoration for $sell points.',
                                          pointsEarned: sell,
                                        );
                                        if (_placingDecorInventoryId != null &&
                                            stack.itemIds.contains(
                                              _placingDecorInventoryId,
                                            )) {
                                          _placingDecorInventoryId =
                                              nextDecorInventoryIdInStack(
                                            _garden.decorInventory,
                                            stackKey,
                                          );
                                        }
                                        refreshSheet();
                                        if (_garden.plantInventory.isEmpty &&
                                            _garden.decorInventory.isEmpty) {
                                          Navigator.pop(sheetCtx);
                                        }
                                      },
                                      child: const Text('Sell 1'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _placeDecorAt(double nx, double ny) {
    final inventoryId = _placingDecorInventoryId;
    if (inventoryId == null) return;
    final invItem = _decorInventoryItem(inventoryId);
    if (invItem == null) return;
    final stackKey = decorInventoryStackKey(invItem);
    final (mrx, mry) = zenDecorPlacementMargins(
      invItem,
      gardenSize: _gardenLayoutSize,
    );
    final resolved = _resolvePlacement(
      nx: nx,
      ny: ny,
      moverRx: mrx,
      moverRy: mry,
    );
    _clearPlacementPrompts();
    final r = _engine.placeDecorFromInventory(
      state: _garden,
      inventoryItemId: inventoryId,
      x: resolved.x,
      y: resolved.y,
    );
    if (!r.isSuccess) {
      _snack(r.error ?? 'Could not place decoration');
      return;
    }
    setState(() {
      _garden = r.state!;
      _exitSelectionForPlacement();
      _placingDecorInventoryId =
          nextDecorInventoryIdInStack(_garden.decorInventory, stackKey);
      _selection.applyPick(
        SandboxEntityRef(id: inventoryId, kind: SandboxEntityKind.decoration),
      );
    });
    _persist();
    SemanticsService.announce('Decoration placed.', Directionality.of(context));
  }

  void _growSelected() {
    final id = _selection.focusPrimaryId;
    if (id == null) return;
    final r = _engine.advanceGrowth(
      state: _garden,
      itemId: id,
      now: DateTime.now(),
      random: _random,
    );
    GardenItem? grown;
    if (r.state != null) {
      for (final e in r.state!.items) {
        if (e.id == id) {
          grown = e;
          break;
        }
      }
    }
    final stageName = grown != null ? zenGardenStageLabel(grown.stageIndex) : '';
    final mut = grown?.mutation != null ? ' Rare visual variant unlocked.' : '';
    _apply(r, announce: r.isSuccess ? 'Plant grew to $stageName.$mut' : null);
  }

  void _skipWait() {
    final id = _selection.focusPrimaryId;
    if (id == null) return;
    _apply(_engine.skipGrowthWait(_garden, id, DateTime.now()), announce: 'Growth wait skipped.');
  }

  void _removeMutation() {
    final id = _selection.focusPrimaryId;
    if (id == null) return;
    _apply(
      _engine.removeMutation(_garden, id),
      announce: 'Special variant removed.',
    );
  }

  void _removeFocusPlant() {
    final id = _selection.focusPrimaryId;
    if (id == null) return;
    _apply(_engine.removeItem(_garden, id), announce: 'Plant moved to inventory.');
    setState(() => _selection.clearFocus());
  }

  void _removeFocusDecor() {
    final id = _selection.focusDecorId;
    if (id == null) return;
    _apply(_engine.removeDecor(_garden, id), announce: 'Decoration moved to inventory.');
    setState(() => _selection.clearFocus());
  }

  void _growDecorSelected() {
    final id = _selection.focusDecorId;
    if (id == null) return;
    final r = _engine.advanceDecorGrowth(
      state: _garden,
      decorId: id,
      now: DateTime.now(),
      random: _random,
    );
    _apply(r, announce: r.isSuccess ? 'Decoration grew.' : null);
  }

  void _skipDecorWait() {
    final id = _selection.focusDecorId;
    if (id == null) return;
    _apply(_engine.skipDecorGrowthWait(_garden, id, DateTime.now()));
  }

  void _removeDecorMutation() {
    final id = _selection.focusDecorId;
    if (id == null) return;
    _apply(_engine.removeDecorMutation(_garden, id));
  }

  Future<void> _confirmDecorRestart() async {
    final id = _selection.focusDecorId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart this decoration?'),
        content: const Text('It returns to the first stage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restart')),
        ],
      ),
    );
    if (ok == true && mounted) {
      _apply(_engine.restartDecorGrowthCycle(state: _garden, decorId: id, pointCost: 0));
    }
  }

  Future<void> _confirmRestart() async {
    final id = _selection.focusPrimaryId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart growth?'),
        content: const Text(
          'The plant returns to the seed stage. This helps unlock a new rare variant later.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restart')),
        ],
      ),
    );
    if (ok == true && mounted) {
      _apply(
        _engine.restartGrowthCycle(state: _garden, itemId: id, pointCost: 0),
        announce: 'Growth restarted from seed.',
      );
    }
  }

  int? _growCostFor(GardenItem item) {
    if (item.stageIndex >= GardenItem.maxStageIndex) return null;
    if (item.nextAdvanceAllowedAt != null &&
        DateTime.now().isBefore(item.nextAdvanceAllowedAt!)) {
      return null;
    }
    final from = item.stageIndex;
    final rule = zenGardenTransitionRules().firstWhere((r) => r.fromStageIndex == from);
    var cost = rule.pointCost;
    if (from == 0 &&
        !_garden.freeFirstGrowthEverConsumed &&
        _garden.freeFirstGrowthEligibleItemId == item.id) {
      cost = 0;
    } else if (item.regrowthDiscountActive) {
      cost = (cost + 4) ~/ 5;
    }
    return cost;
  }

  bool _isFirstPlantFree(GardenItem item) =>
      item.stageIndex == 0 &&
      !_garden.freeFirstGrowthEverConsumed &&
      _garden.freeFirstGrowthEligibleItemId == item.id;

  int? _growCostDecor(DecorItem d) {
    if (d.stageIndex >= DecorItem.maxStageIndex) return null;
    if (d.nextAdvanceAllowedAt != null &&
        DateTime.now().isBefore(d.nextAdvanceAllowedAt!)) {
      return null;
    }
    final rule = zenGardenTransitionRules().firstWhere((r) => r.fromStageIndex == d.stageIndex);
    return rule.pointCost;
  }

  double? _timerProgressDecor(DecorItem d) {
    final end = d.nextAdvanceAllowedAt;
    if (end == null) return null;
    final now = DateTime.now();
    if (!now.isBefore(end)) return 1.0;
    final prevStage = d.stageIndex - 1;
    if (prevStage < 0) return null;
    final rules = zenGardenTransitionRules();
    Duration totalWait = _zenFirstWait;
    for (final r in rules) {
      if (r.fromStageIndex == prevStage && r.waitBeforeNextAdvance != null) {
        totalWait = r.waitBeforeNextAdvance!;
        break;
      }
    }
    final totalMs = totalWait.inMilliseconds;
    if (totalMs <= 0) return null;
    final left = end.difference(now).inMilliseconds;
    return 1.0 - (left / totalMs).clamp(0.0, 1.0);
  }

  double? _timerProgress(GardenItem item) {
    final end = item.nextAdvanceAllowedAt;
    if (end == null) return null;
    final now = DateTime.now();
    if (!now.isBefore(end)) return 1.0;
    final prevStage = item.stageIndex - 1;
    if (prevStage < 0) return null;
    final rules = zenGardenTransitionRules();
    Duration totalWait = _zenFirstWait;
    for (final r in rules) {
      if (r.fromStageIndex == prevStage && r.waitBeforeNextAdvance != null) {
        totalWait = r.waitBeforeNextAdvance!;
        break;
      }
    }
    final totalMs = totalWait.inMilliseconds;
    if (totalMs <= 0) return null;
    final left = end.difference(now).inMilliseconds;
    return 1.0 - (left / totalMs).clamp(0.0, 1.0);
  }

  void _commitBulkDrag() {
    final session = _bulkDrag;
    if (session == null) return;
    var next = _garden;
    final plantMoves = <String, ({double x, double y})>{};
    for (final entry in session.plantOrigins.entries) {
      final item = _garden.items.firstWhere((e) => e.id == entry.key);
      final (mrx, mry) = zenPlantSeparationRadii(item);
      final resolved = resolveZenGardenPlacement(
        nx: entry.value.dx + session.dx,
        ny: entry.value.dy + session.dy,
        moverRx: mrx,
        moverRy: mry,
      );
      plantMoves[entry.key] = (x: resolved.x, y: resolved.y);
    }
    if (plantMoves.isNotEmpty) {
      final r = _engine.moveItemsBulk(next, plantMoves);
      if (r.isSuccess) next = r.state!;
    }
    final decorMoves = <String, ({double x, double y})>{};
    for (final entry in session.decorOrigins.entries) {
      final item = _garden.decor.firstWhere((e) => e.id == entry.key);
      final (mrx, mry) = zenDecorSeparationRadii(item);
      final resolved = resolveZenGardenPlacement(
        nx: entry.value.dx + session.dx,
        ny: entry.value.dy + session.dy,
        moverRx: mrx,
        moverRy: mry,
      );
      decorMoves[entry.key] = (x: resolved.x, y: resolved.y);
    }
    if (decorMoves.isNotEmpty) {
      final r = _engine.moveDecorsBulk(next, decorMoves);
      if (r.isSuccess) next = r.state!;
    }
    setState(() {
      _garden = next;
      _bulkDrag = null;
      _bulkPlantPreview = null;
      _bulkDecorPreview = null;
    });
    _persist();
  }

  void _updateBulkDragPreview(double nx, double ny) {
    final session = _bulkDrag;
    if (session == null) return;
    var dx = nx - session.anchorNx;
    var dy = ny - session.anchorNy;
    final members = <({double x, double y, double rx, double ry})>[];
    for (final entry in session.plantOrigins.entries) {
      final item = _garden.items.firstWhere((e) => e.id == entry.key);
      final (mrx, mry) = zenPlantPlacementMargins(
        item,
        gardenSize: _gardenLayoutSize,
      );
      members.add((x: entry.value.dx, y: entry.value.dy, rx: mrx, ry: mry));
    }
    for (final entry in session.decorOrigins.entries) {
      final item = _garden.decor.firstWhere((e) => e.id == entry.key);
      final (mrx, mry) = zenDecorPlacementMargins(
        item,
        gardenSize: _gardenLayoutSize,
      );
      members.add((x: entry.value.dx, y: entry.value.dy, rx: mrx, ry: mry));
    }
    final clamped = zenClampGroupDelta(dx: dx, dy: dy, members: members);
    session.dx = clamped.dx;
    session.dy = clamped.dy;
    setState(() {
      _bulkPlantPreview = {
        for (final e in session.plantOrigins.entries)
          e.key: Offset(e.value.dx + session.dx, e.value.dy + session.dy),
      };
      _bulkDecorPreview = {
        for (final e in session.decorOrigins.entries)
          e.key: Offset(e.value.dx + session.dx, e.value.dy + session.dy),
      };
    });
  }

  void _commitPlantDrag(String id) {
    final d = _drag;
    if (d != null && d.isPlant && d.id == id) {
      final item = _garden.items.firstWhere((e) => e.id == id);
      final (mrx, mry) = zenPlantPlacementMargins(
        item,
        gardenSize: _gardenLayoutSize,
      );
      final resolved = _resolvePlacement(
        nx: d.nx,
        ny: d.ny,
        moverRx: mrx,
        moverRy: mry,
      );
      _apply(_engine.moveItem(_garden, id, x: resolved.x, y: resolved.y));
    }
    setState(() => _drag = null);
  }

  void _commitDecorDrag(String id) {
    final d = _drag;
    if (d != null && !d.isPlant && d.id == id) {
      final item = _garden.decor.firstWhere((e) => e.id == id);
      final (mrx, mry) = zenDecorPlacementMargins(
        item,
        gardenSize: _gardenLayoutSize,
      );
      final resolved = _resolvePlacement(
        nx: d.nx,
        ny: d.ny,
        moverRx: mrx,
        moverRy: mry,
      );
      _apply(_engine.moveDecor(_garden, id, x: resolved.x, y: resolved.y));
    }
    setState(() => _drag = null);
  }

  void _resetPointer() {
    _pointerDownGlobal = null;
    _pointerPick = null;
    _pointerDragging = false;
    _areaSelectStartNorm = null;
    _areaSelectCurrentNorm = null;
    _areaSelecting = false;
    if (_drag != null || _bulkDrag != null) {
      setState(() {
        _drag = null;
        _bulkDrag = null;
        _bulkPlantPreview = null;
        _bulkDecorPreview = null;
      });
    } else if (_areaSelecting) {
      setState(() {});
    }
  }

  bool get _viewportScaleEnabled => !_pointerDragging && _bulkDrag == null;

  void _onSandPointerDown(PointerDownEvent e, double nx, double ny) {
    setState(() {
      _pointerDownGlobal = e.position;
      _pointerDragging = false;
      _areaSelecting = false;
      _areaSelectStartNorm = Offset(nx, ny);
      _areaSelectCurrentNorm = Offset(nx, ny);
      if (_isPlacing) {
        _pointerPick = null;
      } else {
        _pointerPick = _hitTester.nearestPick(
          nx,
          ny,
          _garden,
          gardenSize: _gardenLayoutSize,
        );
      }
    });
  }

  void _onSandPointerMove(PointerMoveEvent e, double nx, double ny) {
    if (_pointerDragging && _bulkDrag != null) {
      _updateBulkDragPreview(nx, ny);
      return;
    }
    if (_pointerDragging && _drag != null) {
      final clamped = _clampDragNorm(
        nx: nx,
        ny: ny,
        isPlant: _drag!.isPlant,
        id: _drag!.id,
      );
      setState(() {
        _drag!.nx = clamped.nx;
        _drag!.ny = clamped.ny;
      });
      return;
    }
    if (_pointerDownGlobal == null || _isPlacing) {
      return;
    }
    if ((e.position - _pointerDownGlobal!).distance <= _pointerSlop) {
      return;
    }
    if (_selection.multiMode && _selection.bulkCount > 0) {
      setState(() {
        _pointerDragging = true;
        final plantOrigins = <String, Offset>{};
        for (final id in _selection.bulkPrimary) {
          final item = _garden.items.firstWhere((p) => p.id == id);
          plantOrigins[id] = Offset(item.positionX, item.positionY);
        }
        final decorOrigins = <String, Offset>{};
        for (final id in _selection.bulkDecor) {
          final item = _garden.decor.firstWhere((d) => d.id == id);
          decorOrigins[id] = Offset(item.positionX, item.positionY);
        }
        _bulkDrag = _BulkDragSession(
          anchorNx: nx,
          anchorNy: ny,
          plantOrigins: plantOrigins,
          decorOrigins: decorOrigins,
        );
        _updateBulkDragPreview(nx, ny);
      });
      return;
    }
    if (_selection.multiMode &&
        _selection.bulkSelectStyle == BulkSelectStyle.area) {
      setState(() {
        _areaSelecting = true;
        _areaSelectCurrentNorm = Offset(nx, ny);
      });
      return;
    }
    if (_selection.multiMode) {
      return;
    }
    final pick = _selection.hasFocus ? _focusedEntityRef() : _pointerPick;
    if (pick == null) return;
    final clamped = _clampDragNorm(
      nx: nx,
      ny: ny,
      isPlant: pick.isPrimary,
      id: pick.id,
    );
    setState(() {
      _pointerDragging = true;
      _drag = _DragSession(
        isPlant: pick.isPrimary,
        id: pick.id,
        nx: clamped.nx,
        ny: clamped.ny,
      );
    });
  }

  void _commitAreaSelection() {
    final start = _areaSelectStartNorm;
    final end = _areaSelectCurrentNorm;
    if (start == null || end == null) return;
    final rect = Rect.fromPoints(start, end);
    if (rect.width < 0.008 && rect.height < 0.008) {
      _selection.deselectOnEmptyTap();
      return;
    }
    final primary = <String>{};
    final decor = <String>{};
    zenGardenCollectInNormRect(
      rect,
      _garden,
      _gardenLayoutSize,
      bulkPrimary: primary,
      bulkDecor: decor,
    );
    _selection.replaceBulkSelection(primaryIds: primary, decorIds: decor);
  }

  void _onSandPointerUp(PointerUpEvent e, double nx, double ny) {
    if (_pointerDragging && _bulkDrag != null) {
      _commitBulkDrag();
      _resetPointer();
      return;
    }
    if (_pointerDragging && _drag != null) {
      if (_drag!.isPlant) {
        _commitPlantDrag(_drag!.id);
      } else {
        _commitDecorDrag(_drag!.id);
      }
      _resetPointer();
      return;
    }
    if (_selection.multiMode &&
        _selection.bulkSelectStyle == BulkSelectStyle.area &&
        _areaSelecting) {
      setState(_commitAreaSelection);
      _resetPointer();
      return;
    }
    if (_selection.multiMode) {
      setState(() {
        if (_pointerPick != null) {
          _selection.toggleBulk(_pointerPick!);
        } else {
          _selection.deselectOnEmptyTap();
        }
      });
      _resetPointer();
      return;
    }
    if (_placingDecorInventoryId != null && _pointerDownGlobal != null) {
      if ((e.position - _pointerDownGlobal!).distance <= _pointerSlop * 2) {
        _placeDecorAt(nx, ny);
      }
      _resetPointer();
      return;
    }
    if (_placingPlant && _pointerDownGlobal != null) {
      if ((e.position - _pointerDownGlobal!).distance <= _pointerSlop * 2) {
        _placePlantAt(nx, ny);
      }
      _resetPointer();
      return;
    }
    setState(() {
      if (_pointerPick != null) {
        if (!_selection.multiMode &&
            _selection.hasFocus &&
            ((_selection.focusPrimaryId != null &&
                    _pointerPick!.isPrimary &&
                    _selection.focusPrimaryId == _pointerPick!.id) ||
                (_selection.focusDecorId != null &&
                    !_pointerPick!.isPrimary &&
                    _selection.focusDecorId == _pointerPick!.id))) {
          _selection.deselectOnEmptyTap();
        } else {
          _selection.applyPick(_pointerPick!);
        }
      } else {
        _selection.deselectOnEmptyTap();
      }
    });
    _resetPointer();
  }

  /// When the selected item sits low on the sand, anchor the action panel at the top
  /// so it does not cover the selection.
  bool _actionPanelUsesTopAnchor(double normY) => normY > 0.58;

  double _fullscreenTopInset(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return topPadding + (_chromeVisible ? 8 : 56);
  }

  Widget _buildGardenOverlayShell({
    required BuildContext context,
    required bool anchorTop,
    required Widget child,
  }) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: anchorTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          anchorTop ? _fullscreenTopInset(context) : 10,
          12,
          anchorTop ? 10 : bottomPadding + 10,
        ),
        child: Material(
          elevation: 10,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          color: widget.secondaryColor.withValues(alpha: 0.97),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: _gardenLayoutSize.height * 0.48,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkSelectOverlay(
    BuildContext context, {
    required int bulkCount,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          MediaQuery.paddingOf(context).bottom + 10,
        ),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          color: widget.secondaryColor.withValues(alpha: 0.97),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: _gardenLayoutSize.height * 0.32,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<BulkSelectStyle>(
                    segments: const [
                      ButtonSegment(
                        value: BulkSelectStyle.tap,
                        label: Text('Tap'),
                        icon: Icon(Icons.touch_app_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: BulkSelectStyle.area,
                        label: Text('Area'),
                        icon: Icon(Icons.crop_free, size: 18),
                      ),
                    ],
                    selected: {_selection.bulkSelectStyle},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selection.setBulkSelectStyle(selected.first);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selection.bulkSelectStyle == BulkSelectStyle.area
                        ? (bulkCount == 0
                            ? 'Drag a box over items to select them. Tap empty sand to clear.'
                            : '$bulkCount selected. Drag to move the group. Tap empty sand to clear.')
                        : (bulkCount == 0
                            ? 'Tap plants or decorations to toggle selection.'
                            : '$bulkCount selected. Drag to move the group. Tap empty sand to clear.'),
                    style: widget.textStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusActionOverlay(
    BuildContext context, {
    required GardenItem? focusPlant,
    required DecorItem? focusDecor,
  }) {
    if (_selection.multiMode) return const SizedBox.shrink();

    if (focusPlant == null && focusDecor == null) {
      if (!_chromeVisible) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: Text(
              'Tap a plant or decoration. Drag to reposition.',
              textAlign: TextAlign.center,
              style: widget.textStyle.copyWith(
                fontWeight: FontWeight.normal,
                color: widget.textStyle.color?.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      );
    }

    final anchorY = focusPlant?.positionY ?? focusDecor!.positionY;
    return _buildGardenOverlayShell(
      context: context,
      anchorTop: _actionPanelUsesTopAnchor(anchorY),
      child: _BottomActions(
        textStyle: widget.textStyle,
        primary: widget.primaryColor,
        secondary: widget.secondaryColor,
        garden: _garden,
        plant: focusPlant,
        decor: focusDecor,
        growCost: focusPlant == null ? null : _growCostFor(focusPlant),
        growCostDecor: focusDecor == null ? null : _growCostDecor(focusDecor),
        isFirstPlantFree: focusPlant != null && _isFirstPlantFree(focusPlant),
        onGrow: focusPlant == null ? null : _growSelected,
        onGrowDecor: focusDecor == null ? null : _growDecorSelected,
        onSkip: focusPlant == null ? null : _skipWait,
        onSkipDecor: focusDecor == null ? null : _skipDecorWait,
        onRemoveMutation: focusPlant == null ? null : _removeMutation,
        onRemoveDecorMutation: focusDecor == null ? null : _removeDecorMutation,
        onRestart: focusPlant == null ? null : _confirmRestart,
        onRestartDecor: focusDecor == null ? null : _confirmDecorRestart,
        onRemovePlant: focusPlant == null ? null : _removeFocusPlant,
        onRemoveDecor: focusDecor == null ? null : _removeFocusDecor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _gardenLoadFuture ??= _loadGarden();

    return FutureBuilder<void>(
      future: _gardenLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: widget.primaryColor),
          );
        }
        return _buildGarden(context);
      },
    );
  }

  Widget _buildGarden(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final focusPlant = _focusPlant;
    final focusDecor = _focusDecor;
    final bulkCount = _selection.bulkCount;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Theme(
      data: widget.themeData,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_chromeVisible) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Semantics(
                    container: true,
                    label:
                        'Focus points: ${_garden.pointsBalance}. Earn more from goals on the dashboard.',
                    child: Row(
                      children: [
                        Icon(Icons.spa_outlined, color: widget.primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Points: ${_garden.pointsBalance}',
                            style: widget.textStyle,
                          ),
                        ),
                        IconButton(
                          tooltip: 'How points work',
                          onPressed: () => _snack(
                            'Earn points from goals on the dashboard. Shared balance here.',
                          ),
                          icon: Icon(Icons.info_outline, color: widget.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _startPlantPlacement,
                        icon: const Icon(Icons.grass_outlined),
                        label: const Text('Add plant'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _openShop,
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Shop'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _openInventory,
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Inventory'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _setMultiMode(!_selection.multiMode),
                        icon: Icon(
                          _selection.multiMode
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        label: Text(_selection.multiMode ? 'Selection on' : 'Select'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: _selection.multiMode
                              ? widget.primaryColor.withValues(alpha: 0.15)
                              : null,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _toggleChrome,
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Fullscreen'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _centerViewport,
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Center'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                      if (_selection.multiMode && bulkCount > 0)
                        FilledButton.icon(
                          onPressed: _bulkStashToInventory,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text('To inventory ($bulkCount)'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isPlacing)
                  Material(
                    color: widget.secondaryColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: widget.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Placing ${_placingLabel ?? 'object'} — tap the garden',
                              style: widget.textStyle.copyWith(
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _cancelPlacement,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: _chromeVisible ? 12 : 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      _gardenLayoutSize = Size(w, h);
                      final plantOverrides = <String, Offset>{};
                      final decorOverrides = <String, Offset>{};
                      if (_drag != null) {
                        if (_drag!.isPlant) {
                          plantOverrides[_drag!.id] = Offset(_drag!.nx, _drag!.ny);
                        } else {
                          decorOverrides[_drag!.id] = Offset(_drag!.nx, _drag!.ny);
                        }
                      }
                      if (_bulkPlantPreview != null) {
                        plantOverrides.addAll(_bulkPlantPreview!);
                      }
                      if (_bulkDecorPreview != null) {
                        decorOverrides.addAll(_bulkDecorPreview!);
                      }
                      final paintEntities = zenBuildPaintEntities(
                        _garden,
                        _gardenLayoutSize,
                        plantOverrides: plantOverrides.isEmpty ? null : plantOverrides,
                        decorOverrides: decorOverrides.isEmpty ? null : decorOverrides,
                      );
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(_chromeVisible ? 12 : 0),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            ProgressiveSandboxViewport(
                              width: w,
                              height: h,
                              transformationController: _viewportTransform,
                              panEnabled: false,
                              scaleEnabled: _viewportScaleEnabled,
                              onPointerDown: _onSandPointerDown,
                              onPointerMove: _onSandPointerMove,
                              onPointerUp: _onSandPointerUp,
                              onPointerCancel: _resetPointer,
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  CustomPaint(
                                    size: Size(w, h),
                                    painter: RakedSandPainter.harmonized(
                                      themePrimary: widget.primaryColor,
                                      themeSecondary: widget.secondaryColor,
                                    ),
                                  ),
                                  CustomPaint(
                                    size: Size(w, h),
                                    painter: ZenGardenStaticSceneryPainter.harmonized(
                                      themePrimary: widget.primaryColor,
                                      themeSecondary: widget.secondaryColor,
                                    ),
                                  ),
                                  ZenGardenWaterfallLayer(
                                    size: Size(w, h),
                                    reduceMotion: reduceMotion,
                                  ),
                                  ...paintEntities.map((entity) {
                                    if (entity.kind == ZenPaintEntityKind.decor) {
                                      final d = entity.decor!;
                                      final sel = _selection.isDecorSelected(d.id);
                                      final left = entity.displayX * w - _decorVisualW / 2;
                                      final top = entity.displayY * h - _decorVisualH / 2;
                                      final tProg = _timerProgressDecor(d);
                                      return Positioned(
                                        left: left.clamp(2.0, w - _decorVisualW - 2),
                                        top: top.clamp(2.0, h - _decorVisualH - 2),
                                        child: IgnorePointer(
                                          child: RepaintBoundary(
                                            child: ZenDecorVisual(
                                              key: ValueKey('decor-${d.id}'),
                                              item: d,
                                              selected: sel,
                                              primary: widget.primaryColor,
                                              secondary: widget.secondaryColor,
                                              reduceMotion: reduceMotion,
                                              timerProgress: tProg,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final item = entity.plant!;
                                    final sel = _selection.isPrimarySelected(item.id);
                                    final left = entity.displayX * w - _plantVisualW / 2;
                                    final top = entity.displayY * h - _plantVisualH / 2;
                                    final tProg = _timerProgress(item);
                                    return Positioned(
                                      left: left.clamp(2.0, w - _plantVisualW - 2),
                                      top: top.clamp(2.0, h - _plantVisualH - 2),
                                      child: IgnorePointer(
                                        child: _PlantVisual(
                                          key: ValueKey('plant-${item.id}'),
                                          item: item,
                                          primary: widget.primaryColor,
                                          selected: sel,
                                          timerProgress: tProg,
                                          reduceMotion: reduceMotion,
                                        ),
                                      ),
                                    );
                                  }),
                                if (_areaSelecting &&
                                    _areaSelectStartNorm != null &&
                                    _areaSelectCurrentNorm != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _AreaSelectBoxPainter(
                                          startNorm: _areaSelectStartNorm!,
                                          endNorm: _areaSelectCurrentNorm!,
                                          color: widget.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                              if (_drag != null)
                                Positioned(
                                  left: _drag!.nx * w - 30,
                                  top: _drag!.ny * h - 30,
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      size: const Size(60, 60),
                                      painter: DropPreviewPainter(
                                        center: const Offset(30, 30),
                                        color: widget.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                ],
                              ),
                            ),
                            if (_viewportMoved)
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Material(
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  borderRadius: BorderRadius.circular(24),
                                  color: widget.secondaryColor.withValues(alpha: 0.94),
                                  child: IconButton(
                                    tooltip: 'Center garden',
                                    onPressed: _centerViewport,
                                    icon: Icon(
                                      Icons.center_focus_strong,
                                      color: widget.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            if (_selection.multiMode)
                              _buildBulkSelectOverlay(context, bulkCount: bulkCount),
                            if (!_selection.multiMode)
                              _buildFocusActionOverlay(
                                context,
                                focusPlant: focusPlant,
                                focusDecor: focusDecor,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (!_chromeVisible)
            Positioned(
              top: topPadding + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _toggleChrome,
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Show controls'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  ),
                  const Spacer(),
                  if (_selection.multiMode && bulkCount > 0)
                    FilledButton.icon(
                      onPressed: _bulkStashToInventory,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Text('To inventory ($bulkCount)'),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Visual only; hit-testing and drag are handled by the sand [Listener].
class _PlantVisual extends StatelessWidget {
  const _PlantVisual({
    super.key,
    required this.item,
    required this.primary,
    required this.selected,
    required this.timerProgress,
    required this.reduceMotion,
  });

  final GardenItem item;
  final Color primary;
  final bool selected;
  final double? timerProgress;
  final bool reduceMotion;

  static const double _w = 96;
  static const double _h = 118;

  @override
  Widget build(BuildContext context) {
    final fill = ZenCartoonStyle.plantFill(
      primary,
      selected: selected,
      mutated: item.mutation == MutationKind.invertedColors,
    );
    final outline = ZenCartoonStyle.ink;

    return Semantics(
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: reduceMotion ? 1.0 : (selected ? 1.04 : 1.0),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        child: SizedBox(
          width: _w,
          height: _h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (selected && !reduceMotion)
                Positioned(
                  top: -6,
                  child: Icon(Icons.arrow_drop_up, size: 32, color: primary.withValues(alpha: 0.85)),
                ),
              CustomPaint(
                size: const Size(_w, _h),
                painter: PlantHaloPainter(
                  selected: selected,
                  primary: primary,
                  timerProgress: timerProgress,
                ),
              ),
              Positioned(
                bottom: 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(72, 14),
                      painter: PlaceableGroundShadowPainter(
                        center: const Offset(36, 10),
                        width: 54,
                        height: 12,
                      ),
                    ),
                    DecoratedBox(
                      decoration: item.mutation == MutationKind.invertedColors
                          ? const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4D00FFD1),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ],
                            )
                          : const BoxDecoration(),
                      child: CustomPaint(
                        size: const Size(72, 92),
                        painter: ZenPlantPainter(
                          stageIndex: item.stageIndex,
                          fill: fill,
                          outline: outline,
                          mutation: item.mutation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.garden,
    required this.plant,
    required this.decor,
    required this.growCost,
    required this.growCostDecor,
    required this.isFirstPlantFree,
    required this.onGrow,
    required this.onGrowDecor,
    required this.onSkip,
    required this.onSkipDecor,
    required this.onRemoveMutation,
    required this.onRemoveDecorMutation,
    required this.onRestart,
    required this.onRestartDecor,
    required this.onRemovePlant,
    required this.onRemoveDecor,
  });

  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final GardenState garden;
  final GardenItem? plant;
  final DecorItem? decor;
  final int? growCost;
  final int? growCostDecor;
  final bool isFirstPlantFree;
  final VoidCallback? onGrow;
  final VoidCallback? onGrowDecor;
  final VoidCallback? onSkip;
  final VoidCallback? onSkipDecor;
  final VoidCallback? onRemoveMutation;
  final VoidCallback? onRemoveDecorMutation;
  final VoidCallback? onRestart;
  final VoidCallback? onRestartDecor;
  final VoidCallback? onRemovePlant;
  final VoidCallback? onRemoveDecor;

  static String _growPlantLabel(int? cost, bool firstPlantFree) {
    if (cost == null) return 'Grow next';
    if (firstPlantFree && cost == 0) return 'Grow next (free, first plant)';
    if (cost == 0) return 'Grow next (no points)';
    return 'Grow next ($cost pts)';
  }

  static String _growPlantSemanticsLabel(int? cost, bool firstPlantFree) {
    if (cost == null) return 'Grow to next stage';
    if (firstPlantFree && cost == 0) {
      return 'Grow to next stage, free for your first plant only';
    }
    if (cost == 0) return 'Grow to next stage, no points cost';
    return 'Grow to next stage, costs $cost points';
  }

  @override
  Widget build(BuildContext context) {
    if (plant == null && decor == null) {
      return Semantics(
        container: true,
        label: 'Nothing selected. Tap the garden or add a plant.',
        child: Text(
          'Tap a plant or decoration. Drag to reposition.',
          style: textStyle.copyWith(fontWeight: FontWeight.normal),
        ),
      );
    }

    if (decor != null) {
      final d = decor!;
      final label = decorEntryByKind(d.kind)?.label ?? d.kind;
      final now = DateTime.now();
      final waiting = d.nextAdvanceAllowedAt != null && now.isBefore(d.nextAdvanceAllowedAt!);
      final remaining = waiting ? d.nextAdvanceAllowedAt!.difference(now) : Duration.zero;
      final skipCost = d.pendingSkipWaitCost;
      final waitTotal = _zenWaitAfterAdvancingFrom(d.stageIndex - 1);
      final mutLabel = d.mutation == null
          ? ''
          : ', rare inverted-color variant active. Remove variant button available.';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label:
                'Selected decoration $label, stage ${d.stageIndex + 1} of five.$mutLabel Balance ${garden.pointsBalance} points.',
            child: Text(
              '$label · Stage ${d.stageIndex + 1} of 5'
              '${d.mutation != null ? ' · variant on' : ''}',
              style: textStyle,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Move this decoration to inventory',
            child: OutlinedButton(
              onPressed: onRemoveDecor,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('To inventory'),
            ),
          ),
          if (waiting && skipCost != null) ...[
            const SizedBox(height: 8),
            _CountdownRow(
              remaining: remaining,
              waitTotal: waitTotal,
              skipCost: skipCost,
              balance: garden.pointsBalance,
              textStyle: textStyle,
              primary: primary,
              onSkip: onSkipDecor,
            ),
          ],
          const SizedBox(height: 12),
          if (!waiting && d.stageIndex < DecorItem.maxStageIndex)
            Semantics(
              button: true,
              enabled:
                  growCostDecor != null && garden.pointsBalance >= (growCostDecor ?? 0),
              label: growCostDecor == 0
                  ? 'Grow decoration to next stage, no points cost'
                  : 'Grow decoration to next stage, costs $growCostDecor points',
              child: FilledButton(
                onPressed: (growCostDecor != null &&
                        garden.pointsBalance >= growCostDecor!)
                    ? onGrowDecor
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: primary,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1C1B1A),
                ),
                child: Text(
                  growCostDecor == 0
                      ? 'Grow next (no points)'
                      : 'Grow next ($growCostDecor pts)',
                ),
              ),
            ),
          if (d.stageIndex >= DecorItem.maxStageIndex) ...[
            Text(
              'This decoration is fully grown.',
              style: textStyle.copyWith(fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Restart growth from first stage for a new rare variant chance',
              child: OutlinedButton(
                onPressed: onRestartDecor,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Restart growth'),
              ),
            ),
          ],
          if (d.mutation != null) ...[
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Remove special color variant',
              child: TextButton(
                onPressed: onRemoveDecorMutation,
                child: const Text('Remove special variant'),
              ),
            ),
          ],
        ],
      );
    }

    final i = plant!;
    final stageLabel = zenGardenStageLabel(i.stageIndex);
    final now = DateTime.now();
    final waiting = i.nextAdvanceAllowedAt != null && now.isBefore(i.nextAdvanceAllowedAt!);
    final remaining = waiting ? i.nextAdvanceAllowedAt!.difference(now) : Duration.zero;
    final skipCost = i.pendingSkipWaitCost;
    final waitTotal = _zenWaitAfterAdvancingFrom(i.stageIndex - 1);
    final mutLabel = i.mutation == null
        ? ''
        : ', rare inverted-color variant active. Remove variant button available.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label:
              'Selected plant, stage $stageLabel of five.$mutLabel Balance ${garden.pointsBalance} points.',
          child: Text(
            'Stage: $stageLabel (${i.stageIndex + 1} of 5)'
            '${i.mutation != null ? ' · variant on' : ''}',
            style: textStyle,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Move this plant to inventory',
          child: OutlinedButton(
            onPressed: onRemovePlant,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('To inventory'),
          ),
        ),
        if (waiting && skipCost != null) ...[
          const SizedBox(height: 8),
          _CountdownRow(
            remaining: remaining,
            waitTotal: waitTotal,
            skipCost: skipCost,
            balance: garden.pointsBalance,
            textStyle: textStyle,
            primary: primary,
            onSkip: onSkip,
          ),
        ],
        const SizedBox(height: 12),
        if (!waiting && i.stageIndex < GardenItem.maxStageIndex)
          Semantics(
            button: true,
            enabled: growCost != null && garden.pointsBalance >= (growCost ?? 0),
            label: _growPlantSemanticsLabel(growCost, isFirstPlantFree),
            child: FilledButton(
              onPressed: (growCost != null && garden.pointsBalance >= growCost!)
                  ? onGrow
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: primary,
                foregroundColor:
                    ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1C1B1A),
              ),
              child: Text(_growPlantLabel(growCost, isFirstPlantFree)),
            ),
          ),
        if (i.stageIndex >= GardenItem.maxStageIndex) ...[
          Text(
            'This plant is fully grown.',
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Restart growth from seed for a new rare variant chance',
            child: OutlinedButton(
              onPressed: onRestart,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Restart growth from seed'),
            ),
          ),
        ],
        if (i.mutation != null) ...[
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Remove special color variant, keeps mature plant',
            child: TextButton(
              onPressed: onRemoveMutation,
              child: const Text('Remove special variant'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({
    required this.remaining,
    required this.skipCost,
    required this.balance,
    required this.textStyle,
    required this.primary,
    required this.onSkip,
    required this.waitTotal,
  });

  final Duration remaining;
  final Duration waitTotal;
  final int skipCost;
  final int balance;
  final TextStyle textStyle;
  final Color primary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('mm:ss').format(DateTime(0).add(remaining));
    final canSkip = balance >= skipCost;
    final denom = waitTotal.inMilliseconds <= 0 ? 1 : waitTotal.inMilliseconds;
    final progress = 1.0 - (remaining.inMilliseconds / denom).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                  color: primary.withValues(alpha: 0.55),
                  backgroundColor: primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(fmt, style: textStyle.copyWith(fontFeatures: const [])),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              'Pause before next growth. About $fmt remaining. Or skip for $skipCost points.',
          child: Text(
            'Pause before next growth · $fmt left',
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          enabled: canSkip,
          label: 'Skip wait for $skipCost points',
          child: FilledButton.tonal(
            onPressed: canSkip ? onSkip : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text('Skip wait ($skipCost pts)'),
          ),
        ),
      ],
    );
  }
}

class _ZenShopSheet extends StatefulWidget {
  const _ZenShopSheet({
    required this.textStyle,
    required this.primary,
    required this.garden,
    required this.engine,
    required this.onPurchased,
    this.onUserMessage,
  });

  final TextStyle textStyle;
  final Color primary;
  final GardenState garden;
  final ProgressiveGardenEngine engine;
  final void Function(GardenOpResult r) onPurchased;
  final void Function(String message)? onUserMessage;

  @override
  State<_ZenShopSheet> createState() => _ZenShopSheetState();
}

class _ZenShopSheetState extends State<_ZenShopSheet> {
  late final Map<String, TextEditingController> _qtyControllers;
  late GardenState _cartGarden;

  @override
  void initState() {
    super.initState();
    _cartGarden = widget.garden;
    _qtyControllers = {
      for (final e in decorCatalogFor(VisualThemeId.zenGarden))
        e.id: TextEditingController(text: '1'),
    };
  }

  @override
  void didUpdateWidget(covariant _ZenShopSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.garden, widget.garden)) {
      _cartGarden = widget.garden;
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _parsedQty(String kind) {
    final raw = _qtyControllers[kind]?.text ?? '';
    final v = int.tryParse(raw.trim());
    if (v == null || v < 1) return 1;
    return v.clamp(1, 999);
  }

  void _bumpQty(String kind, int delta) {
    final q = (_parsedQty(kind) + delta).clamp(1, 999);
    _qtyControllers[kind]!.text = '$q';
    setState(() {});
  }

  void _buy(DecorCatalogEntry entry) {
    final q = _parsedQty(entry.id);
    final r = widget.engine.purchaseDecor(_cartGarden, entry.id, quantity: q);
    if (r.isSuccess && r.state != null) {
      setState(() => _cartGarden = r.state!);
    }
    widget.onPurchased(r);
    if (r.isSuccess) {
      widget.onUserMessage?.call('Bought $q× ${entry.label}.');
    } else {
      widget.onUserMessage?.call(r.error ?? 'Could not buy');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = decorCatalogFor(VisualThemeId.zenGarden);
    final balance = _cartGarden.pointsBalance;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return Material(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Decoration shop',
                    style: widget.textStyle.copyWith(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Balance: $balance pts',
                    style: widget.textStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      final q = _parsedQty(e.id);
                      final total = e.pointCost * q;
                      final canBuy = balance >= total;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(e.icon, color: widget.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.label, style: widget.textStyle),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${e.pointCost} pts each · Total: $total pts',
                                          style: widget.textStyle.copyWith(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Fewer',
                                    onPressed: q > 1 ? () => _bumpQty(e.id, -1) : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _qtyControllers[e.id],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'Qty',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'More',
                                    onPressed: q < 999 ? () => _bumpQty(e.id, 1) : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: canBuy ? () => _buy(e) : null,
                                    child: const Text('Buy'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
