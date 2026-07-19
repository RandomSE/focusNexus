import 'dart:math';

import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';

/// Outcome of an idempotent daily first-open reward attempt.
class DailyOpenRewardResult {
  const DailyOpenRewardResult({
    required this.granted,
    required this.amount,
    required this.newStreak,
  });

  final bool granted;
  final int amount;
  final int newStreak;

  static const none = DailyOpenRewardResult(
    granted: false,
    amount: 0,
    newStreak: 0,
  );
}

/// Grants points on the first eligible open of each local calendar day.
///
/// Formula: `min(50 + 10 * (streakDay - 1), 350)`.
/// Streak counts consecutive local calendar days with at least one grant;
/// missing a day resets to 1. Open events stay on-device (no upload).
class DailyOpenRewardService {
  DailyOpenRewardService({
    required KeyValueStorage storage,
    required PointsRepository points,
  })  : _storage = storage,
        _points = points;

  static const baseReward = 50;
  static const perStreakBonus = 10;
  static const maxReward = 350;

  /// Documented alternate soft-cap for A/B tests (`rewardForStreak(..., maxCap: softCapAlt)`).
  static const softCapAlt = 200;

  final KeyValueStorage _storage;
  final PointsRepository _points;

  /// Point amount for [streakDay] (1-based). Defaults to [maxReward]; pass [maxCap]
  /// to parameterize (e.g. [softCapAlt] = 200).
  static int rewardForStreak(int streakDay, {int? maxCap}) {
    final day = streakDay < 1 ? 1 : streakDay;
    final cap = maxCap ?? maxReward;
    return min(baseReward + perStreakBonus * (day - 1), cap);
  }

  /// Local calendar day key `yyyy-MM-dd`.
  static String formatLocalDay(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Attempts a daily grant. Safe to call multiple times; same-day returns
  /// [granted] false. Storage/points failures fail soft (no throw).
  Future<DailyOpenRewardResult> tryGrant({DateTime? now}) async {
    try {
      final clock = now ?? DateTime.now();
      final today = formatLocalDay(clock);
      final lastGrant =
          await _storage.read(key: StorageKeys.lastAppOpenGrantDate) ?? '';
      final priorStreak = int.tryParse(
            await _storage.read(key: StorageKeys.consecutiveDaysAppOpened) ??
                '',
          ) ??
          0;

      if (lastGrant == today) {
        return DailyOpenRewardResult(
          granted: false,
          amount: 0,
          newStreak: priorStreak < 1 ? 1 : priorStreak,
        );
      }

      final yesterday = formatLocalDay(
        DateTime(clock.year, clock.month, clock.day)
            .subtract(const Duration(days: 1)),
      );
      final newStreak =
          (lastGrant.isNotEmpty && lastGrant == yesterday) ? priorStreak + 1 : 1;
      final amount = rewardForStreak(newStreak);

      await _points.add(amount);
      await _storage.write(key: StorageKeys.lastAppOpenGrantDate, value: today);
      await _storage.write(
        key: StorageKeys.consecutiveDaysAppOpened,
        value: newStreak.toString(),
      );

      return DailyOpenRewardResult(
        granted: true,
        amount: amount,
        newStreak: newStreak,
      );
    } catch (e, stack) {
      debugLog('DailyOpenRewardService.tryGrant failed soft: $e\n$stack');
      return DailyOpenRewardResult.none;
    }
  }
}
