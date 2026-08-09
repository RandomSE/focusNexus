import 'package:flutter/foundation.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

typedef PointsBalanceListener = void Function();

/// Wallet / reward points (`StorageKeys.points`).
class PointsRepository {
  PointsRepository(this._storage);

  final KeyValueStorage _storage;
  final List<PointsBalanceListener> _balanceListeners = [];
  int? _cachedBalance;

  static const defaultBalance = 50;

  /// Shared-wallet floor (never negative).
  static const minBalance = 0;

  /// Shared-wallet ceiling enforced on every write/credit path.
  static const maxBalance = 99999999;

  /// Clamps [balance] into [[minBalance], [maxBalance]].
  static int clampBalance(int balance) {
    if (balance < minBalance) return minBalance;
    if (balance > maxBalance) return maxBalance;
    return balance;
  }

  void addBalanceListener(PointsBalanceListener listener) {
    _balanceListeners.add(listener);
  }

  void removeBalanceListener(PointsBalanceListener listener) {
    _balanceListeners.remove(listener);
  }

  void _notifyBalanceChanged() {
    for (final listener in List<PointsBalanceListener>.from(_balanceListeners)) {
      listener();
    }
  }

  Future<int> _readStoredBalance() async {
    final raw = await _storage.read(key: StorageKeys.points);
    if (raw == null) return defaultBalance;
    return int.tryParse(raw) ?? defaultBalance;
  }

  Future<void> _writeBalance(int balance, {required bool notify}) async {
    final clamped = clampBalance(balance);
    _cachedBalance = clamped;
    await _storage.write(key: StorageKeys.points, value: clamped.toString());
    if (notify) {
      _notifyBalanceChanged();
    }
  }

  Future<int> readBalance() async {
    if (_cachedBalance != null) return _cachedBalance!;
    final stored = clampBalance(await _readStoredBalance());
    _cachedBalance = stored;
    return stored;
  }

  /// Updates in-memory balance immediately (listeners fire before disk write).
  void creditBalance(int delta) {
    if (delta == 0) return;
    final next = clampBalance((_cachedBalance ?? defaultBalance) + delta);
    _cachedBalance = next;
    _notifyBalanceChanged();
  }

  /// Sets in-memory balance and notifies listeners without writing storage.
  void setCachedBalance(int balance) {
    final clamped = clampBalance(balance);
    if (_cachedBalance == clamped) return;
    _cachedBalance = clamped;
    _notifyBalanceChanged();
  }

  /// Sets in-memory balance without notifying listeners.
  void primeCachedBalance(int balance) {
    _cachedBalance = clampBalance(balance);
  }

  /// Ensures a persisted balance exists; returns the effective balance.
  Future<int> ensureInitialized() async {
    final raw = await _storage.read(key: StorageKeys.points);
    if (raw == null) {
      await _writeBalance(defaultBalance, notify: false);
      return defaultBalance;
    }
    final parsed = clampBalance(int.tryParse(raw) ?? defaultBalance);
    _cachedBalance = parsed;
    if (parsed.toString() != raw) {
      await _writeBalance(parsed, notify: false);
    }
    return parsed;
  }

  Future<void> writeBalance(int balance) async {
    await _writeBalance(balance, notify: true);
  }

  /// Writes the in-memory balance to storage without notifying listeners.
  ///
  /// Use after [creditBalance] when the UI was already updated optimistically.
  Future<void> persistCachedBalance() async {
    final balance = _cachedBalance ?? await readBalance();
    await _writeBalance(balance, notify: false);
  }

  @visibleForTesting
  void clearBalanceCacheForTesting() => _cachedBalance = null;

  /// After storage wipe, re-seed wallet and notify listeners.
  Future<void> resetToDefaultBalance() async {
    _cachedBalance = null;
    await _writeBalance(defaultBalance, notify: true);
  }

  /// Deducts [amount] when sufficient; returns new balance or null if insufficient.
  ///
  /// Successful spends increment [StorageKeys.lifetimePointsSpent] (FU-3 breadth).
  Future<int?> trySpend(int amount) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be non-negative');
    }
    final current = await readBalance();
    if (current < amount) return null;
    final next = current - amount;
    await writeBalance(next);
    if (amount > 0) {
      await recordLifetimeSpent(amount);
    }
    return next;
  }

  /// Cumulative wallet spends used for cherry unlock (alongside zen garden field).
  Future<int> readLifetimeSpent() async {
    final raw = await _storage.read(key: StorageKeys.lifetimePointsSpent);
    return int.tryParse(raw ?? '') ?? 0;
  }

  /// Adds to [StorageKeys.lifetimePointsSpent] (zen sync and trySpend).
  Future<void> recordLifetimeSpent(int amount) async {
    if (amount <= 0) return;
    final current = await readLifetimeSpent();
    await _storage.write(
      key: StorageKeys.lifetimePointsSpent,
      value: (current + amount).toString(),
    );
  }

  /// Raises lifetime spent to at least [minimum] (garden -> wallet sync).
  Future<void> ensureLifetimeSpentAtLeast(int minimum) async {
    if (minimum <= 0) return;
    final current = await readLifetimeSpent();
    if (minimum <= current) return;
    await _storage.write(
      key: StorageKeys.lifetimePointsSpent,
      value: minimum.toString(),
    );
  }

  /// Removes previously granted points; floored at [minBalance] via clamp.
  Future<void> clawback(int amount) async {
    if (amount <= 0) return;
    final current = await readBalance();
    await writeBalance(current - amount);
  }

  /// Adds [amount] to the persisted balance and syncs [_cachedBalance].
  ///
  /// Uses storage as the source of truth for the increment so an optimistic
  /// [creditBalance] cannot cause a double award when persistence runs.
  Future<void> add(int amount) async {
    if (amount <= 0) return;
    final stored = await _readStoredBalance();
    await _writeBalance(stored + amount, notify: true);
  }
}
