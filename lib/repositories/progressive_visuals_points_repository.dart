import 'package:flutter/foundation.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

typedef ProgressiveVisualsPointsListener = void Function();

/// Progressive-visuals currency (`StorageKeys.progressiveVisualsPoints`).
///
/// Spent before shared [PointsRepository] wallet on PV purchases. Earn via
/// [credit] from achievement claims and daily goal momentum.
class ProgressiveVisualsPointsRepository {
  ProgressiveVisualsPointsRepository(this._storage);

  final KeyValueStorage _storage;
  final List<ProgressiveVisualsPointsListener> _listeners = [];
  int? _cachedBalance;

  static const defaultBalance = 0;
  static const minBalance = 0;

  /// Balance ceiling only (no lifetime-earned PV cap); raised for the 2026-08
  /// PV-earn rebalance where several achievements grant 5-figure PV amounts.
  static const maxBalance = 1000000;

  static int clampBalance(int balance) {
    if (balance < minBalance) return minBalance;
    if (balance > maxBalance) return maxBalance;
    return balance;
  }

  void addBalanceListener(ProgressiveVisualsPointsListener listener) {
    _listeners.add(listener);
  }

  void removeBalanceListener(ProgressiveVisualsPointsListener listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<ProgressiveVisualsPointsListener>.from(_listeners)) {
      listener();
    }
  }

  Future<int> _readStored() async {
    final raw = await _storage.read(key: StorageKeys.progressiveVisualsPoints);
    if (raw == null) return defaultBalance;
    return int.tryParse(raw) ?? defaultBalance;
  }

  Future<void> _write(int balance, {required bool notify}) async {
    final clamped = clampBalance(balance);
    _cachedBalance = clamped;
    await _storage.write(
      key: StorageKeys.progressiveVisualsPoints,
      value: clamped.toString(),
    );
    if (notify) _notify();
  }

  Future<int> ensureInitialized() async {
    _cachedBalance ??= await _readStored();
    return _cachedBalance!;
  }

  Future<int> readBalance() => ensureInitialized();

  Future<void> writeBalance(int balance) => _write(balance, notify: true);

  /// Account wipe: zero balance and drop stale cache.
  Future<void> resetToZero() async {
    _cachedBalance = null;
    await _write(defaultBalance, notify: true);
  }

  @visibleForTesting
  void clearCacheForTesting() {
    _cachedBalance = null;
  }

  Future<int> credit(int amount) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be non-negative');
    }
    final current = await ensureInitialized();
    final next = clampBalance(current + amount);
    await _write(next, notify: true);
    return next;
  }
}
