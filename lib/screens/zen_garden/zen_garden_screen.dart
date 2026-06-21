import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_state.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_op_result.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/sandbox_entity.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';
import 'package:focusNexus/progressive_visuals/sandbox_viewport.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/progressive_visuals/zen_placeable_bounds.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_hit_test.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';
import 'zen_garden_area_select_painter.dart';
import 'zen_garden_bulk_select_overlay.dart';
import 'zen_garden_decor_visual.dart';
import 'zen_garden_focus_action_overlay.dart';
import 'zen_garden_inventory_sheet.dart';
import 'zen_inventory_stacks.dart';
import 'zen_garden_painters.dart';
import 'zen_garden_plant_visual.dart';
import 'zen_garden_sandbox_logic.dart';
import 'zen_garden_shop_sheet.dart';
import 'zen_garden_stage_labels.dart';
import 'zen_garden_static_scenery.dart';
import 'zen_garden_waterfall.dart';
import 'zen_placeable_layout.dart';

/// Calm, playable Zen garden: plants, growth, decorations, selection, drag preview.
class ZenGardenScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ZenGardenScreen> createState() => _ZenGardenScreenState();
}

class _ZenGardenScreenState extends ConsumerState<ZenGardenScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final SandboxHitTester _hitTester = const ZenGardenHitTester();
  final TransformationController _viewportTransform = TransformationController();
  late final AnimationController _viewportResetAnim;
  bool _centeringViewport = false;
  Future<void>? _gardenLoadFuture;

  ZenGardenSessionState get _ui => ref.watch(zenGardenSessionProvider);
  ZenGardenSession get _session => ref.read(zenGardenSessionProvider.notifier);
  SandboxSelectionState get _selection => _session.selection;
  ProgressiveGardenEngine get _engine => _session.engine;
  GardenState get _garden => _ui.garden;
  bool get _chromeVisible => _ui.chromeVisible;
  String? get _placingDecorInventoryId => _ui.placingDecorInventoryId;
  bool get _placingPlant => _ui.placingPlant;
  String? get _placingPlantInventoryId => _ui.placingPlantInventoryId;
  ZenDragSession? get _drag => _ui.drag;
  ZenBulkDragSession? get _bulkDrag => _ui.bulkDrag;
  Size get _gardenLayoutSize => _ui.gardenLayoutSize;
  Map<String, Offset>? get _bulkPlantPreview => _ui.bulkPlantPreview;
  Map<String, Offset>? get _bulkDecorPreview => _ui.bulkDecorPreview;
  Offset? get _pointerDownGlobal => _ui.pointerDownGlobal;
  SandboxEntityRef? get _pointerPick => _ui.pointerPick;
  bool get _pointerDragging => _ui.pointerDragging;
  Offset? get _areaSelectStartNorm => _ui.areaSelectStartNorm;
  Offset? get _areaSelectCurrentNorm => _ui.areaSelectCurrentNorm;
  bool get _areaSelecting => _ui.areaSelecting;
  bool get _viewportMoved => _ui.viewportMoved;

  void _patch(ZenGardenSessionState Function(ZenGardenSessionState) transform) {
    _session.patch(transform);
  }

  void _touch() => _session.touch();

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
    ref.listenManual(pointsBalanceProvider, (previous, next) {
      next.whenData((balance) {
        ref.read(zenGardenSessionProvider.notifier).applyWalletBalance(balance);
      });
    }, fireImmediately: true);
  }

  int get _walletBalance {
    final fromProvider = ref.watch(pointsBalanceProvider).valueOrNull;
    if (fromProvider != null) return fromProvider;
    return _garden.pointsBalance;
  }

  void _showZenGardenHelp() {
    CommonUtils.showBasicAlertDialog(
      context,
      'Zen garden & points',
      'Points are shared with the dashboard: earn them by completing goals, '
      'then spend them here on plants, growth, and decorations.\n\n'
      'Once you have placed a plant or decoration, tap it to select it. Drag to reposition on the sand.',
      widget.textStyle,
      widget.secondaryColor,
    );
  }

  @override
  void dispose() {
    final garden = ref.read(zenGardenSessionProvider).garden;
    unawaited(ref.read(zenGardenSessionProvider.notifier).persist(snapshot: garden));
    _viewportTransform.removeListener(_syncViewportMoved);
    _viewportResetAnim.dispose();
    _viewportTransform.dispose();
    super.dispose();
  }

  void _syncViewportMoved() {
    final moved = !sandboxViewportIsDefault(_viewportTransform.value);
    if (moved != _viewportMoved && mounted) {
      _session.setViewportMoved(moved);
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
    await _session.loadGarden();
  }

  Future<void> _persist({GardenState? snapshot}) =>
      _session.persist(snapshot: snapshot);

  void _apply(GardenOpResult result, {String? announce}) {
    if (!result.isSuccess) {
      _snack(result.error ?? 'Something went wrong');
      return;
    }
    _session.applyOp(result);
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

  bool get _isPlacing {
    if (_placingDecorInventoryId != null) {
      return _decorInventoryItem(_placingDecorInventoryId) != null;
    }
    if (_placingPlant) {
      if (_placingPlantInventoryId != null) {
        return _plantInventoryItem(_placingPlantInventoryId) != null;
      }
      return true;
    }
    return false;
  }

  String? get _placingLabel {
    if (_placingPlant) {
      if (_placingPlantInventoryId != null) {
        final invPlant = _plantInventoryItem(_placingPlantInventoryId);
        if (invPlant == null) return null;
        final mut = invPlant.mutation != null ? ', variant' : '';
        return 'plant (${zenGardenStageLabel(invPlant.stageIndex)})$mut';
      }
      return 'seed';
    }
    final invDecor = _decorInventoryItem(_placingDecorInventoryId);
    if (invDecor != null) {
      final label = decorEntryByKind(invDecor.kind)?.label ?? invDecor.kind;
      final mut = invDecor.mutation != null ? ', variant' : '';
      return '$label, stage ${invDecor.stageIndex + 1}$mut';
    }
    return null;
  }

  void _clearStalePlacementIfNeeded() {
    final decorId = _placingDecorInventoryId;
    final plantInvId = _placingPlantInventoryId;
    if (decorId != null && _decorInventoryItem(decorId) == null) {
      _cancelPlacement();
      return;
    }
    if (_placingPlant && plantInvId != null && _plantInventoryItem(plantInvId) == null) {
      _cancelPlacement();
    }
  }

  void _cancelPlacement() {
    _patch(
      (s) => s.copyWith(
        clearPlacingDecorInventoryId: true,
        placingPlant: false,
        clearPlacingPlantInventoryId: true,
      ),
    );
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
    _selection.setMultiMode(v);
    if (v) {
      _cancelPlacement();
    } else {
      _touch();
    }
  }

  void _toggleChrome() {
    _patch((s) => s.copyWith(chromeVisible: !s.chromeVisible));
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
    _session.setGarden(next);
    _selection.bulkPrimary.clear();
    _selection.bulkDecor.clear();
    _touch();
    unawaited(_persist(snapshot: next));
    SemanticsService.announce('Moved selection to inventory.', Directionality.of(context));
  }

  void _startPlantPlacement() {
    _exitSelectionForPlacement();
    _patch(
      (s) => s.copyWith(
        placingPlant: true,
        clearPlacingPlantInventoryId: true,
        clearPlacingDecorInventoryId: true,
      ),
    );
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
    final nextGarden = r.state!;
    _exitSelectionForPlacement();
    String? nextPlantInvId;
    var stillPlacing = false;
    if (fromInventoryId != null && plantStackKey != null) {
      nextPlantInvId =
          nextPlantInventoryIdInStack(nextGarden.plantInventory, plantStackKey);
      stillPlacing = nextPlantInvId != null;
    }
    _selection.applyPick(
      SandboxEntityRef(id: placedId, kind: SandboxEntityKind.primary),
    );
    _session.setGarden(nextGarden);
    _patch(
      (s) => s.copyWith(
        placingPlant: stillPlacing,
        placingPlantInventoryId: nextPlantInvId,
        clearPlacingPlantInventoryId: nextPlantInvId == null,
      ),
    );
    unawaited(_persist(snapshot: nextGarden));
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

  Future<void> _openShop() async {
    await _session.syncWalletBalance();
    if (!mounted) return;
    final garden = ref.read(zenGardenSessionProvider).garden;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => ZenGardenShopSheet(
        textStyle: widget.textStyle,
        primary: widget.primaryColor,
        garden: garden,
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
    _session.applyOp(result);
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
    showZenGardenInventorySheet(
      context: context,
      textStyle: widget.textStyle,
      engine: _engine,
      onApplyInventoryOp: _applyInventoryOp,
      onExitSelectionForPlacement: _exitSelectionForPlacement,
      onPatch: _patch,
      onRefresh: _touch,
      onClearPlacementPrompts: _clearPlacementPrompts,
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
    final nextGarden = r.state!;
    _exitSelectionForPlacement();
    final nextDecorId =
        nextDecorInventoryIdInStack(nextGarden.decorInventory, stackKey);
    _selection.applyPick(
      SandboxEntityRef(id: inventoryId, kind: SandboxEntityKind.decoration),
    );
    _session.setGarden(nextGarden);
    _patch((s) => s.copyWith(placingDecorInventoryId: nextDecorId));
    unawaited(_persist(snapshot: nextGarden));
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
    _selection.clearFocus();
    _touch();
  }

  void _removeFocusDecor() {
    final id = _selection.focusDecorId;
    if (id == null) return;
    _apply(_engine.removeDecor(_garden, id), announce: 'Decoration moved to inventory.');
    _selection.clearFocus();
    _touch();
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
    _session.setGarden(next);
    _patch(
      (s) => s.copyWith(
        clearBulkDrag: true,
        clearBulkPlantPreview: true,
        clearBulkDecorPreview: true,
      ),
    );
    unawaited(_persist(snapshot: next));
  }

  void _updateBulkDragPreview(double nx, double ny) {
    final session = _bulkDrag;
    if (session == null) return;
    final dx = nx - session.anchorNx;
    final dy = ny - session.anchorNy;
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
    final moved = session.copyWith(dx: clamped.dx, dy: clamped.dy);
    _patch(
      (s) => s.copyWith(
        bulkDrag: moved,
        bulkPlantPreview: {
          for (final e in moved.plantOrigins.entries)
            e.key: Offset(e.value.dx + moved.dx, e.value.dy + moved.dy),
        },
        bulkDecorPreview: {
          for (final e in moved.decorOrigins.entries)
            e.key: Offset(e.value.dx + moved.dx, e.value.dy + moved.dy),
        },
      ),
    );
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
    _patch((s) => s.copyWith(clearDrag: true));
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
    _patch((s) => s.copyWith(clearDrag: true));
  }

  void _resetPointer() {
    if (_drag != null ||
        _bulkDrag != null ||
        _pointerDownGlobal != null ||
        _pointerPick != null ||
        _pointerDragging ||
        _areaSelectStartNorm != null ||
        _areaSelectCurrentNorm != null ||
        _areaSelecting) {
      _patch(
        (s) => s.copyWith(
          clearPointerDownGlobal: true,
          clearPointerPick: true,
          pointerDragging: false,
          clearAreaSelectStart: true,
          clearAreaSelectCurrent: true,
          areaSelecting: false,
          clearDrag: true,
          clearBulkDrag: true,
          clearBulkPlantPreview: true,
          clearBulkDecorPreview: true,
        ),
      );
    }
  }

  bool get _viewportScaleEnabled => !_pointerDragging && _bulkDrag == null;

  void _onSandPointerDown(PointerDownEvent e, double nx, double ny) {
    _patch(
      (s) => s.copyWith(
        pointerDownGlobal: e.position,
        pointerDragging: false,
        areaSelecting: false,
        areaSelectStartNorm: Offset(nx, ny),
        areaSelectCurrentNorm: Offset(nx, ny),
        pointerPick: _isPlacing
            ? null
            : _hitTester.nearestPick(
                nx,
                ny,
                _garden,
                gardenSize: _gardenLayoutSize,
              ),
        clearPointerPick: _isPlacing,
      ),
    );
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
      _patch(
        (s) => s.copyWith(
          drag: s.drag!.copyWith(nx: clamped.nx, ny: clamped.ny),
        ),
      );
      return;
    }
    if (_pointerDownGlobal == null || _isPlacing) {
      return;
    }
    if ((e.position - _pointerDownGlobal!).distance <= _pointerSlop) {
      return;
    }
    if (_selection.multiMode && _selection.bulkCount > 0) {
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
      _patch(
        (s) => s.copyWith(
          pointerDragging: true,
          bulkDrag: ZenBulkDragSession(
            anchorNx: nx,
            anchorNy: ny,
            plantOrigins: plantOrigins,
            decorOrigins: decorOrigins,
          ),
        ),
      );
      _updateBulkDragPreview(nx, ny);
      return;
    }
    if (_selection.multiMode &&
        _selection.bulkSelectStyle == BulkSelectStyle.area) {
      _patch(
        (s) => s.copyWith(
          areaSelecting: true,
          areaSelectCurrentNorm: Offset(nx, ny),
        ),
      );
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
    _patch(
      (s) => s.copyWith(
        pointerDragging: true,
        drag: ZenDragSession(
          isPlant: pick.isPrimary,
          id: pick.id,
          nx: clamped.nx,
          ny: clamped.ny,
        ),
      ),
    );
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
      _commitAreaSelection(); _touch();
      _resetPointer();
      return;
    }
    if (_selection.multiMode) {
      if (_pointerPick != null) {
        _selection.toggleBulk(_pointerPick!);
      } else {
        _selection.deselectOnEmptyTap();
      }
      _touch();
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
    _touch();
    _resetPointer();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearStalePlacementIfNeeded();
    });
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
                  child: Row(
                    children: [
                      Icon(Icons.spa_outlined, color: widget.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Points: $_walletBalance',
                          style: widget.textStyle,
                        ),
                      ),
                      IconButton(
                        tooltip: 'How points and the garden work',
                        onPressed: _showZenGardenHelp,
                        icon: Icon(Icons.info_outline, color: widget.primaryColor),
                      ),
                    ],
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
                              'Placing ${_placingLabel ?? 'item'} - tap the garden',
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
                      final layoutSize = Size(w, h);
                      if (_gardenLayoutSize != layoutSize) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _patch((s) => s.copyWith(gardenLayoutSize: layoutSize));
                        });
                      }
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
                                        child: ZenGardenPlantVisual(
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
                                        painter: ZenGardenAreaSelectBoxPainter(
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
                              ZenGardenBulkSelectOverlay(
                                selection: _selection,
                                bulkCount: bulkCount,
                                textStyle: widget.textStyle,
                                secondaryColor: widget.secondaryColor,
                                gardenLayoutSize: _gardenLayoutSize,
                                onBulkSelectStyleChanged: _selection.setBulkSelectStyle,
                                onTouch: _touch,
                              ),
                            if (!_selection.multiMode)
                              ZenGardenFocusActionOverlay(
                                multiMode: _selection.multiMode,
                                focusPlant: focusPlant,
                                focusDecor: focusDecor,
                                textStyle: widget.textStyle,
                                primary: widget.primaryColor,
                                secondary: widget.secondaryColor,
                                garden: _garden,
                                growCost: focusPlant == null ? null : _growCostFor(focusPlant),
                                growCostDecor:
                                    focusDecor == null ? null : _growCostDecor(focusDecor),
                                isFirstPlantFree:
                                    focusPlant != null && _isFirstPlantFree(focusPlant),
                                chromeVisible: _chromeVisible,
                                gardenLayoutSize: _gardenLayoutSize,
                                onGrow: _growSelected,
                                onGrowDecor: _growDecorSelected,
                                onSkip: _skipWait,
                                onSkipDecor: _skipDecorWait,
                                onRemoveMutation: _removeMutation,
                                onRemoveDecorMutation: _removeDecorMutation,
                                onRestart: _confirmRestart,
                                onRestartDecor: _confirmDecorRestart,
                                onRemovePlant: _removeFocusPlant,
                                onRemoveDecor: _removeFocusDecor,
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
