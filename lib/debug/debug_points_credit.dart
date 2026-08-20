import 'package:focusNexus/services/daily_open_reward_service.dart';

/// Debug-only wallet credit rules (never used in release UI).
abstract final class DebugPointsCredit {
  DebugPointsCredit._();

  /// Exclusive upper bound (below 100 million). Wallet ceiling is 99,999,999.
  static const int maxExclusive = 100000000;

  static const int minInclusive = 1;

  /// Returns an error string when [raw] is not a valid credit amount.
  static String? validateAmount(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a whole number of points';
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Must be a whole number';
    }
    if (parsed < minInclusive) {
      return 'Must be at least $minInclusive';
    }
    if (parsed >= maxExclusive) {
      return 'Must be below 100 million';
    }
    return null;
  }

  static int? parseAmount(String? raw) {
    if (validateAmount(raw) != null) return null;
    return int.parse(raw!.trim());
  }

  /// Same local calendar day as [DailyOpenRewardService] streak grants.
  static bool isAvailableOnDay({
    required String? lastCreditDay,
    required DateTime now,
  }) {
    final last = lastCreditDay?.trim() ?? '';
    if (last.isEmpty) return true;
    return last != DailyOpenRewardService.formatLocalDay(now);
  }
}
