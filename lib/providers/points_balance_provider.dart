import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';

part 'points_balance_provider.g.dart';

/// Live wallet balance; refreshes when [PointsRepository] balance changes.
@Riverpod(keepAlive: true)
class PointsBalance extends _$PointsBalance {
  @override
  Future<int> build() async {
    final points = ref.read(appRepositoriesProvider).points;
    void onBalanceChanged() {
      ref.invalidateSelf();
    }
    points.addBalanceListener(onBalanceChanged);
    ref.onDispose(() => points.removeBalanceListener(onBalanceChanged));
    return points.readBalance();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(appRepositoriesProvider).points.readBalance(),
    );
  }
}
