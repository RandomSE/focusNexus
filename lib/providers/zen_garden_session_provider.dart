import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_op_result.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_state.dart';
import 'package:focusNexus/repositories/app_repositories.dart';

part 'zen_garden_session_provider.g.dart';

/// Zen garden sandbox session; persisted via [GardenRepository].
@Riverpod(keepAlive: true)
class ZenGardenSession extends _$ZenGardenSession {
  final SandboxSelectionState selection = SandboxSelectionState();
  late final ProgressiveGardenEngine _engine = ProgressiveGardenEngine(
    transitionRules: zenGardenTransitionRules(),
  );
  Timer? _growthTicker;
  bool _hasLoadedFromDisk = false;
  bool _notifierDisposed = false;
  Future<void>? _persistQueue;

  /// True after [loadGarden] has completed at least once this session.
  bool get hasLoadedFromDisk => _hasLoadedFromDisk;

  ProgressiveGardenEngine get engine => _engine;

  AppRepositories get _repos => ref.read(appRepositoriesProvider);

  @override
  ZenGardenSessionState build() {
    _notifierDisposed = false;
    final gardenRepo = ref.read(appRepositoriesProvider).garden;
    ref.onDispose(() {
      _notifierDisposed = true;
      _growthTicker?.cancel();
      if (_hasLoadedFromDisk) {
        final snapshot = state.garden;
        unawaited(
          gardenRepo.save(snapshot).catchError((Object e, StackTrace st) {
            debugPrint('Zen garden flush on dispose failed: $e\n$st');
          }),
        );
      }
    });
    return ZenGardenSessionState.initial();
  }

  void patch(ZenGardenSessionState Function(ZenGardenSessionState current) transform) {
    if (_notifierDisposed) return;
    state = transform(state).bump();
  }

  void touch() {
    if (_notifierDisposed) return;
    state = state.bump();
  }

  Future<void> loadGarden() async {
    final garden = await _repos.garden.load();
    if (_notifierDisposed) return;
    _hasLoadedFromDisk = true;
    state = state.copyWith(garden: garden).bump();
    syncGrowthTicker();
  }

  /// Keeps [GardenState.pointsBalance] aligned with the app-wide wallet.
  Future<void> syncWalletBalance() async {
    final balance = await _repos.points.readBalance();
    final garden = state.garden;
    if (garden.pointsBalance == balance) return;
    setGarden(garden.copyWith(pointsBalance: balance));
  }

  void applyWalletBalance(int balance) {
    final garden = state.garden;
    if (garden.pointsBalance == balance) return;
    setGarden(garden.copyWith(pointsBalance: balance));
  }

  /// Persists [snapshot] (or current garden) in order; skips until [loadGarden] completes.
  Future<void> persist({GardenState? snapshot}) {
    if (!_hasLoadedFromDisk) return Future.value();
    final toSave = snapshot ?? state.garden;
    _persistQueue = (_persistQueue ?? Future.value()).then((_) async {
      await _repos.garden.save(toSave);
    }).catchError((Object e, StackTrace st) {
      debugPrint('Zen garden persist failed: $e\n$st');
    });
    return _persistQueue!;
  }

  void setGarden(GardenState garden) {
    if (_notifierDisposed) return;
    state = state.copyWith(garden: garden).bump();
    syncGrowthTicker();
  }

  /// Applies a successful engine op, persists, and updates growth timers.
  GardenState? applyOp(GardenOpResult result) {
    if (!result.isSuccess) return null;
    final next = result.state!;
    setGarden(next);
    unawaited(persist(snapshot: next));
    return next;
  }

  void syncGrowthTicker() {
    bool waiting(dynamic x) =>
        x.nextAdvanceAllowedAt != null &&
        DateTime.now().isBefore(x.nextAdvanceAllowedAt!);
    final garden = state.garden;
    final needs = garden.items.any(waiting) || garden.decor.any(waiting);
    _growthTicker?.cancel();
    if (!needs) {
      _growthTicker = null;
      return;
    }
    _growthTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_notifierDisposed) {
        _growthTicker?.cancel();
        _growthTicker = null;
        return;
      }
      final g = state.garden;
      final still = g.items.any(waiting) || g.decor.any(waiting);
      if (!still) {
        _growthTicker?.cancel();
        _growthTicker = null;
      }
      touch();
    });
  }

  void setViewportMoved(bool moved) {
    if (_notifierDisposed) return;
    if (state.viewportMoved == moved) return;
    patch((s) => s.copyWith(viewportMoved: moved));
  }
}
