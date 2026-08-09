import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/utils/debug_log.dart';

/// After achievement claims that may mutate garden (path bonsai), refresh the
/// in-memory zen session tree from disk so a later persist cannot clobber it.
Future<void> refreshZenAfterAchievementClaim(WidgetRef ref) async {
  try {
    await ref
        .read(zenGardenSessionProvider.notifier)
        .refreshCherryTreeFromDisk();
  } catch (e, st) {
    debugLog('refreshZenAfterAchievementClaim failed soft: $e\n$st');
  }
  ref.invalidate(pointsBalanceProvider);
}
