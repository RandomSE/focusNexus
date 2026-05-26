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
import 'package:focusNexus/progressive_visuals/visual_bridge.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:intl/intl.dart';

import 'zen_garden_painters.dart';

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

bool _zenPlantHitNorm(double nx, double ny, GardenItem item) {
  final dx = nx - item.positionX;
  final dy = ny - item.positionY;
  final st = item.stageIndex.clamp(0, 4);
  final rx = 0.088 + st * 0.016;
  final ry = 0.12 + st * 0.022;
  return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
}

bool _zenDecorHitNorm(double nx, double ny, DecorItem d) {
  final dx = nx - d.positionX;
  final dy = ny - d.positionY;
  final st = d.stageIndex.clamp(0, 4);
  switch (d.kind) {
    case 'zen.stone_path':
      final rx = 0.2 + st * 0.022;
      final ry = 0.12 + st * 0.018;
      return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
    case 'zen.koi_pond':
      final rx = 0.17 + st * 0.03;
      final ry = 0.13 + st * 0.024;
      return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
    case 'zen.bamboo_fence':
      final rx = 0.22 + st * 0.024;
      final ry = 0.12 + st * 0.018;
      return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
    case 'zen.wood_bench':
      final rx = 0.16 + st * 0.02;
      final ry = 0.1 + st * 0.014;
      return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
    default:
      final rx = 0.15 + st * 0.022;
      final ry = 0.12 + st * 0.02;
      return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0;
  }
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

class _EntityPick {
  const _EntityPick({required this.id, required this.isPlant});
  final String id;
  final bool isPlant;
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

class _ZenGardenScreenState extends State<ZenGardenScreen> {
  final _repos = AppRepositories.instance;
  final _engine = ProgressiveGardenEngine(
    transitionRules: zenGardenTransitionRules(),
    // TODO: change to 0.05 once testing concludes.
    mutationProbability: 0.5,
  );
  final _random = Random();

  GardenState _garden = const GardenState(pointsBalance: 0, items: []);
  String? _focusPlantId;
  String? _focusDecorId;
  bool _multiMode = false;
  final Set<String> _bulkPlants = {};
  final Set<String> _bulkDecor = {};
  String? _placingDecorKind;
  _DragSession? _drag;
  Offset? _pointerDownGlobal;
  _EntityPick? _pointerPick;
  bool _pointerDragging = false;
  Timer? _ticker;
  Future<void>? _gardenLoadFuture;

  static const double _pointerSlop = 14.0;
  static const double _plantVisualW = 96;
  static const double _plantVisualH = 118;
  static const double _decorVisualW = 96;
  static const double _decorVisualH = 90;

  Duration get _zenFirstWait =>
      zenGardenTransitionRules().firstWhere((r) => r.fromStageIndex == 0).waitBeforeNextAdvance ??
      const Duration(minutes: 2);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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

  GardenItem? get _focusPlant {
    if (_focusPlantId == null) return null;
    try {
      return _garden.items.firstWhere((e) => e.id == _focusPlantId);
    } catch (_) {
      return null;
    }
  }

  DecorItem? get _focusDecor {
    if (_focusDecorId == null) return null;
    try {
      return _garden.decor.firstWhere((e) => e.id == _focusDecorId);
    } catch (_) {
      return null;
    }
  }

  void _setMultiMode(bool v) {
    setState(() {
      _multiMode = v;
      if (v) {
        _focusPlantId = null;
        _focusDecorId = null;
        _placingDecorKind = null;
      } else {
        _bulkPlants.clear();
        _bulkDecor.clear();
      }
    });
  }

  void _toggleBulkPlant(String id) {
    setState(() {
      if (_bulkPlants.contains(id)) {
        _bulkPlants.remove(id);
      } else {
        _bulkPlants.add(id);
      }
    });
  }

  void _toggleBulkDecor(String id) {
    setState(() {
      if (_bulkDecor.contains(id)) {
        _bulkDecor.remove(id);
      } else {
        _bulkDecor.add(id);
      }
    });
  }

  void _bulkDelete() {
    final pn = Set<String>.from(_bulkPlants);
    final dn = Set<String>.from(_bulkDecor);
    if (pn.isEmpty && dn.isEmpty) {
      _snack('Select items first.');
      return;
    }
    var next = _garden;
    if (pn.isNotEmpty) {
      final r = _engine.removeItemsBulk(next, pn);
      if (!r.isSuccess) {
        _snack(r.error ?? 'Could not remove plants');
        return;
      }
      next = r.state!;
    }
    if (dn.isNotEmpty) {
      final r = _engine.removeDecorsBulk(next, dn);
      if (!r.isSuccess) {
        _snack(r.error ?? 'Could not remove decorations');
        return;
      }
      next = r.state!;
    }
    setState(() {
      _garden = next;
      _bulkPlants.clear();
      _bulkDecor.clear();
    });
    _persist();
    SemanticsService.announce('Removed selection.', Directionality.of(context));
  }

  void _addPlant() {
    final id = 'zen_${DateTime.now().millisecondsSinceEpoch}';
    final r = _engine.placeItem(
      state: _garden,
      id: id,
      themeId: VisualThemeId.zenGarden,
      x: 0.45 + _random.nextDouble() * 0.1,
      y: 0.45 + _random.nextDouble() * 0.1,
    );
    _apply(r, announce: 'New plant added.');
    if (r.isSuccess) {
      setState(() {
        _focusPlantId = id;
        _focusDecorId = null;
      });
    }
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

  void _openInventory() {
    final entries = _garden.decorStash.entries.where((e) => e.value > 0).toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Inventory is empty. Buy decorations from the shop.',
                    style: widget.textStyle.copyWith(fontWeight: FontWeight.normal),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Inventory', style: widget.textStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  ...entries.map((e) {
                    final meta = decorEntryByKind(e.key);
                    return ListTile(
                      leading: Icon(meta?.icon ?? Icons.inventory_2_outlined),
                      title: Text(meta?.label ?? e.key),
                      subtitle: Text('Owned: ${e.value}'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _placingDecorKind = e.key;
                            _focusPlantId = null;
                            _focusDecorId = null;
                          });
                          _snack('Tap the garden where you want it.');
                        },
                        child: const Text('Place'),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  void _placeDecorAt(double nx, double ny) {
    final kind = _placingDecorKind;
    if (kind == null) return;
    final id = 'd_${DateTime.now().millisecondsSinceEpoch}';
    _apply(
      _engine.placeDecorFromStash(
        state: _garden,
        kind: kind,
        id: id,
        x: nx,
        y: ny,
        themeId: VisualThemeId.zenGarden,
      ),
      announce: 'Decoration placed.',
    );
    setState(() {
      _placingDecorKind = null;
      _focusDecorId = id;
    });
  }

  void _growSelected() {
    final id = _focusPlantId;
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
    final id = _focusPlantId;
    if (id == null) return;
    _apply(_engine.skipGrowthWait(_garden, id, DateTime.now()), announce: 'Growth wait skipped.');
  }

  void _removeMutation() {
    final id = _focusPlantId;
    if (id == null) return;
    _apply(
      _engine.removeMutation(_garden, id),
      announce: 'Special variant removed.',
    );
  }

  void _removeFocusPlant() {
    final id = _focusPlantId;
    if (id == null) return;
    _apply(_engine.removeItem(_garden, id), announce: 'Plant removed.');
    setState(() => _focusPlantId = null);
  }

  void _removeFocusDecor() {
    final id = _focusDecorId;
    if (id == null) return;
    _apply(_engine.removeDecor(_garden, id), announce: 'Decoration removed.');
    setState(() => _focusDecorId = null);
  }

  void _growDecorSelected() {
    final id = _focusDecorId;
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
    final id = _focusDecorId;
    if (id == null) return;
    _apply(_engine.skipDecorGrowthWait(_garden, id, DateTime.now()));
  }

  void _removeDecorMutation() {
    final id = _focusDecorId;
    if (id == null) return;
    _apply(_engine.removeDecorMutation(_garden, id));
  }

  Future<void> _confirmDecorRestart() async {
    final id = _focusDecorId;
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
    final id = _focusPlantId;
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

  void _commitPlantDrag(String id) {
    final d = _drag;
    if (d != null && d.isPlant && d.id == id) {
      _apply(_engine.moveItem(_garden, id, x: d.nx, y: d.ny));
    }
    setState(() => _drag = null);
  }

  void _commitDecorDrag(String id) {
    final d = _drag;
    if (d != null && !d.isPlant && d.id == id) {
      _apply(_engine.moveDecor(_garden, id, x: d.nx, y: d.ny));
    }
    setState(() => _drag = null);
  }

  void _resetPointer() {
    _pointerDownGlobal = null;
    _pointerPick = null;
    _pointerDragging = false;
    if (_drag != null) {
      setState(() => _drag = null);
    }
  }

  _EntityPick? _nearestPick(double nx, double ny) {
    final candidates = <({_EntityPick pick, double dist})>[];
    for (final p in _garden.items) {
      if (!_zenPlantHitNorm(nx, ny, p)) continue;
      final d = sqrt(pow(nx - p.positionX, 2) + pow(ny - p.positionY, 2));
      candidates.add((pick: _EntityPick(id: p.id, isPlant: true), dist: d));
    }
    for (final d in _garden.decor) {
      if (!_zenDecorHitNorm(nx, ny, d)) continue;
      final dist = sqrt(pow(nx - d.positionX, 2) + pow(ny - d.positionY, 2));
      candidates.add((pick: _EntityPick(id: d.id, isPlant: false), dist: dist));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final dc = a.dist.compareTo(b.dist);
      if (dc != 0) return dc;
      if (a.pick.isPlant != b.pick.isPlant) {
        return a.pick.isPlant ? -1 : 1;
      }
      return a.pick.id.compareTo(b.pick.id);
    });
    return candidates.first.pick;
  }

  void _onSandPointerDown(PointerDownEvent e, RenderBox box, double w, double h) {
    final local = box.globalToLocal(e.position);
    final nx = (local.dx / w).clamp(0.0, 1.0);
    final ny = (local.dy / h).clamp(0.0, 1.0);
    _pointerDownGlobal = e.position;
    _pointerDragging = false;
    if (_multiMode) {
      _pointerPick = _nearestPick(nx, ny);
      return;
    }
    if (_placingDecorKind != null) {
      _pointerPick = null;
      return;
    }
    _pointerPick = _nearestPick(nx, ny);
  }

  void _onSandPointerMove(PointerMoveEvent e, RenderBox box, double w, double h) {
    final local = box.globalToLocal(e.position);
    final nx = (local.dx / w).clamp(0.02, 0.98);
    final ny = (local.dy / h).clamp(0.02, 0.98);
    if (_pointerDragging && _drag != null) {
      setState(() {
        _drag!.nx = nx;
        _drag!.ny = ny;
      });
      return;
    }
    if (_pointerDownGlobal == null ||
        _multiMode ||
        _placingDecorKind != null ||
        _pointerPick == null) {
      return;
    }
    if ((e.position - _pointerDownGlobal!).distance > _pointerSlop) {
      setState(() {
        _pointerDragging = true;
        _drag = _DragSession(
          isPlant: _pointerPick!.isPlant,
          id: _pointerPick!.id,
          nx: nx,
          ny: ny,
        );
      });
    }
  }

  void _onSandPointerUp(PointerUpEvent e, RenderBox box, double w, double h) {
    final local = box.globalToLocal(e.position);
    final nx = (local.dx / w).clamp(0.02, 0.98);
    final ny = (local.dy / h).clamp(0.02, 0.98);
    if (_pointerDragging && _drag != null) {
      if (_drag!.isPlant) {
        _commitPlantDrag(_drag!.id);
      } else {
        _commitDecorDrag(_drag!.id);
      }
      _resetPointer();
      return;
    }
    if (_multiMode && _pointerPick != null) {
      if (_pointerPick!.isPlant) {
        _toggleBulkPlant(_pointerPick!.id);
      } else {
        _toggleBulkDecor(_pointerPick!.id);
      }
      _resetPointer();
      return;
    }
    if (_placingDecorKind != null && _pointerDownGlobal != null) {
      if ((e.position - _pointerDownGlobal!).distance <= _pointerSlop * 2) {
        _placeDecorAt(nx, ny);
      }
      _resetPointer();
      return;
    }
    if (_pointerPick != null) {
      setState(() {
        if (_pointerPick!.isPlant) {
          _focusPlantId = _pointerPick!.id;
          _focusDecorId = null;
        } else {
          _focusDecorId = _pointerPick!.id;
          _focusPlantId = null;
        }
      });
    }
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final focusPlant = _focusPlant;
    final focusDecor = _focusDecor;
    final bulkCount = _bulkPlants.length + _bulkDecor.length;

    return Theme(
      data: widget.themeData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    child: Text('Points: ${_garden.pointsBalance}', style: widget.textStyle),
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
                  onPressed: _addPlant,
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
                  onPressed: () => _setMultiMode(!_multiMode),
                  icon: Icon(_multiMode ? Icons.check_box : Icons.check_box_outline_blank),
                  label: Text(_multiMode ? 'Selection on' : 'Select'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: _multiMode
                        ? widget.primaryColor.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                if (_multiMode && bulkCount > 0)
                  FilledButton.icon(
                    onPressed: _bulkDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text('Delete ($bulkCount)'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      foregroundColor: Colors.red.shade900,
                    ),
                  ),
              ],
            ),
          ),
          if (_placingDecorKind != null)
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
                        'Placing: ${decorEntryByKind(_placingDecorKind!)?.label ?? _placingDecorKind}. Tap sand.',
                        style: widget.textStyle.copyWith(fontWeight: FontWeight.normal, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _placingDecorKind = null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Builder(
                      builder: (sandContext) {
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            CustomPaint(
                              size: Size(w, h),
                              painter: RakedSandPainter(
                                line: Color.lerp(
                                  widget.primaryColor,
                                  const Color(0xFF7A6B5C),
                                  0.35,
                                )!.withValues(alpha: 0.11),
                                washTop: Color.lerp(
                                  widget.secondaryColor,
                                  const Color(0xFFF2EBDF),
                                  0.5,
                                )!,
                                washBottom: Color.lerp(
                                  widget.secondaryColor,
                                  const Color(0xFFD9CFC0),
                                  0.28,
                                )!,
                              ),
                            ),
                            ..._garden.decor.map((d) {
                              final sel = _multiMode
                                  ? _bulkDecor.contains(d.id)
                                  : _focusDecorId == d.id;
                              final dispX = _drag?.id == d.id && !(_drag?.isPlant ?? true)
                                  ? _drag!.nx
                                  : d.positionX;
                              final dispY = _drag?.id == d.id && !(_drag?.isPlant ?? true)
                                  ? _drag!.ny
                                  : d.positionY;
                              final left = dispX * w - _decorVisualW / 2;
                              final top = dispY * h - _decorVisualH / 2;
                              final tProg = _timerProgressDecor(d);
                              return Positioned(
                                left: left.clamp(2.0, w - _decorVisualW - 2),
                                top: top.clamp(2.0, h - _decorVisualH - 2),
                                child: IgnorePointer(
                                  child: _DecorVisual(
                                    item: d,
                                    selected: sel,
                                    primary: widget.primaryColor,
                                    secondary: widget.secondaryColor,
                                    reduceMotion: reduceMotion,
                                    timerProgress: tProg,
                                  ),
                                ),
                              );
                            }),
                            ..._garden.items.map((item) {
                              final sel = _multiMode
                                  ? _bulkPlants.contains(item.id)
                                  : _focusPlantId == item.id;
                              final dispX =
                                  _drag?.isPlant == true && _drag?.id == item.id
                                      ? _drag!.nx
                                      : item.positionX;
                              final dispY =
                                  _drag?.isPlant == true && _drag?.id == item.id
                                      ? _drag!.ny
                                      : item.positionY;
                              final left = dispX * w - _plantVisualW / 2;
                              final top = dispY * h - _plantVisualH / 2;
                              final tProg = _timerProgress(item);
                              return Positioned(
                                left: left.clamp(2.0, w - _plantVisualW - 2),
                                top: top.clamp(2.0, h - _plantVisualH - 2),
                                child: IgnorePointer(
                                  child: _PlantVisual(
                                    item: item,
                                    primary: widget.primaryColor,
                                    selected: sel,
                                    timerProgress: tProg,
                                    reduceMotion: reduceMotion,
                                  ),
                                ),
                              );
                            }),
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
                            Positioned.fill(
                              child: Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: (e) {
                                  final box = sandContext.findRenderObject() as RenderBox?;
                                  if (box == null || !box.hasSize) return;
                                  _onSandPointerDown(e, box, w, h);
                                },
                                onPointerMove: (e) {
                                  final box = sandContext.findRenderObject() as RenderBox?;
                                  if (box == null || !box.hasSize) return;
                                  _onSandPointerMove(e, box, w, h);
                                },
                                onPointerUp: (e) {
                                  final box = sandContext.findRenderObject() as RenderBox?;
                                  if (box == null || !box.hasSize) return;
                                  _onSandPointerUp(e, box, w, h);
                                },
                                onPointerCancel: (_) => _resetPointer(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          if (_multiMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                bulkCount == 0
                    ? 'Selection mode: tap plants or decorations to toggle. Then delete.'
                    : '$bulkCount selected.',
                style: widget.textStyle.copyWith(fontWeight: FontWeight.normal, fontSize: 13),
              ),
            ),
          if (!_multiMode)
            _BottomActions(
              textStyle: widget.textStyle,
              primary: widget.primaryColor,
              secondary: widget.secondaryColor,
              garden: _garden,
              plant: focusPlant,
              decor: focusDecor,
              growCost: focusPlant == null ? null : _growCostFor(focusPlant),
              growCostDecor: focusDecor == null ? null : _growCostDecor(focusDecor),
              isFirstPlantFree:
                  focusPlant != null && _isFirstPlantFree(focusPlant),
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
        ],
      ),
    );
  }
}

/// Visual only; hit-testing and drag are handled by the sand [Listener].
class _PlantVisual extends StatelessWidget {
  const _PlantVisual({
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
    final fill = applyMutationTint(base: primary, mutation: item.mutation)
        .withValues(alpha: selected ? 0.95 : 0.82);
    final outline = primary;

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
      ),
    );
  }
}

class _DecorVisual extends StatelessWidget {
  const _DecorVisual({
    required this.item,
    required this.selected,
    required this.primary,
    required this.secondary,
    required this.reduceMotion,
    this.timerProgress,
  });

  final DecorItem item;
  final bool selected;
  final Color primary;
  final Color secondary;
  final bool reduceMotion;
  final double? timerProgress;

  static const double _w = 96;
  static const double _h = 90;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: reduceMotion ? 1.0 : (selected ? 1.05 : 1.0),
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
                  top: -4,
                  child: Icon(Icons.arrow_drop_up, size: 30, color: primary.withValues(alpha: 0.85)),
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
                bottom: 2,
                child: CustomPaint(
                  size: const Size(94, 78),
                  painter: ZenDecorPainter(item: item, primary: primary, secondary: secondary),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tap a plant or decoration. Drag to reposition.',
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
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

      return Material(
        color: secondary,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  label: 'Remove this decoration from the garden',
                  child: OutlinedButton(
                    onPressed: onRemoveDecor,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    child: const Text('Remove decoration'),
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
            ),
          ),
        ),
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

    return Material(
      color: secondary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                label: 'Remove this plant from the garden',
                child: OutlinedButton(
                  onPressed: onRemovePlant,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('Remove plant'),
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
          ),
        ),
      ),
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
