import 'dart:async';

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

/// Zen garden sandbox session (auto-dispose when leaving the screen).
@riverpod
class ZenGardenSession extends _$ZenGardenSession {
  final SandboxSelectionState selection = SandboxSelectionState();
  late final ProgressiveGardenEngine _engine = ProgressiveGardenEngine(
    transitionRules: zenGardenTransitionRules(),
    mutationProbability: 0.5,
  );
  Timer? _growthTicker;

  ProgressiveGardenEngine get engine => _engine;

  AppRepositories get _repos => ref.read(appRepositoriesProvider);

  @override
  ZenGardenSessionState build() {
    ref.onDispose(() => _growthTicker?.cancel());
    return ZenGardenSessionState.initial();
  }

  void patch(ZenGardenSessionState Function(ZenGardenSessionState current) transform) {
    state = transform(state).bump();
  }

  void touch() {
    state = state.bump();
  }

  Future<void> loadGarden() async {
    final garden = await _repos.garden.load();
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

  Future<void> persist() async {
    await _repos.garden.save(state.garden);
  }

  void setGarden(GardenState garden) {
    state = state.copyWith(garden: garden).bump();
    syncGrowthTicker();
  }

  /// Applies a successful engine op, persists, and updates growth timers.
  GardenState? applyOp(GardenOpResult result) {
    if (!result.isSuccess) return null;
    final next = result.state!;
    setGarden(next);
    unawaited(persist());
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
    if (state.viewportMoved == moved) return;
    patch((s) => s.copyWith(viewportMoved: moved));
  }
}
