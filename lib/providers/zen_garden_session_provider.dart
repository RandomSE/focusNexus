import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_op_result.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_unlock.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_achievement_sync.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_rules.dart';
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
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
            debugLog('Zen garden flush on dispose failed: $e\n$st');
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
    unawaited(_syncZenGardenAchievements(garden));
  }

  /// Keeps [GardenState.pointsBalance] aligned with the app-wide wallet.
  Future<void> syncWalletBalance() async {
    final balance = await _repos.points.readBalance();
    final garden = state.garden;
    if (garden.pointsBalance == balance) return;
    _commitGarden(garden.copyWith(pointsBalance: balance));
  }

  void applyWalletBalance(int balance) {
    final garden = state.garden;
    if (garden.pointsBalance == balance && garden.cherryBlossomTreeUnlocked) {
      return;
    }
    if (garden.pointsBalance == balance) return;
    _commitGarden(garden.copyWith(pointsBalance: balance));
  }

  /// Persists [snapshot] (or current garden) in order; skips until [loadGarden] completes.
  Future<void> persist({GardenState? snapshot}) {
    if (!_hasLoadedFromDisk) return Future.value();
    final toSave = snapshot ?? state.garden;
    _persistQueue = (_persistQueue ?? Future.value()).then((_) async {
      await _repos.garden.save(toSave);
    }).catchError((Object e, StackTrace st) {
      debugLog('Zen garden persist failed: $e\n$st');
    });
    return _persistQueue!;
  }

  void setGarden(GardenState garden) {
    if (_notifierDisposed) return;
    _commitGarden(garden);
  }

  void setSuppressRestartGrowthPrompt(bool suppress) {
    if (_notifierDisposed) return;
    final next = state.garden.copyWith(suppressRestartGrowthPrompt: suppress);
    state = state.copyWith(garden: next).bump();
    unawaited(persist(snapshot: next));
  }

  void clearPendingCherryBlossomUnlockToast() {
    if (_notifierDisposed || !state.pendingCherryBlossomUnlockToast) return;
    patch((s) => s.copyWith(pendingCherryBlossomUnlockToast: false));
  }

  /// Applies a successful engine op, persists, and updates growth timers.
  GardenState? applyOp(GardenOpResult result) {
    if (!result.isSuccess) return null;
    _commitGarden(result.state!);
    final saved = state.garden;
    unawaited(persist(snapshot: saved));
    return saved;
  }

  void _commitGarden(GardenState incoming) {
    final before = state.garden;
    var after = evaluateCherryBlossomUnlock(incoming);
    var pendingUnlockToast = state.pendingCherryBlossomUnlockToast;

    if (!before.cherryBlossomTreeUnlocked &&
        after.cherryBlossomTreeUnlocked &&
        !after.cherryBlossomUnlockToastShown) {
      after = after.copyWith(cherryBlossomUnlockToastShown: true);
      pendingUnlockToast = true;
    }

    state = state
        .copyWith(
          garden: after,
          pendingCherryBlossomUnlockToast: pendingUnlockToast,
        )
        .bump();
    if (after.pointsBalance != before.pointsBalance) {
      ref.read(pointsBalanceProvider.notifier).adoptBalance(after.pointsBalance);
    }
    syncGrowthTicker();
    unawaited(_syncZenGardenAchievements(after));
  }

  Future<void> _syncZenGardenAchievements(GardenState garden) async {
    try {
      final ready = await syncZenGardenAchievements(
        storage: _repos.storage,
        achievements: ref.read(achievementServiceProvider),
        garden: garden,
      );
      if (ready.isNotEmpty) {
        ref
            .read(achievementReadyToastQueueProvider.notifier)
            .enqueueTitles(ready.map((a) => a.title));
      }
    } catch (e, st) {
      debugLog('Zen garden achievement sync failed: $e\n$st');
    }
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
