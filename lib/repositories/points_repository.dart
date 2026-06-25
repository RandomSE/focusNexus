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
    _cachedBalance = balance;
    await _storage.write(key: StorageKeys.points, value: balance.toString());
    if (notify) {
      _notifyBalanceChanged();
    }
  }

  Future<int> readBalance() async {
    if (_cachedBalance != null) return _cachedBalance!;
    final stored = await _readStoredBalance();
    _cachedBalance = stored;
    return stored;
  }

  /// Updates in-memory balance immediately (listeners fire before disk write).
  void creditBalance(int delta) {
    if (delta == 0) return;
    final next = (_cachedBalance ?? defaultBalance) + delta;
    _cachedBalance = next;
    _notifyBalanceChanged();
  }

  /// Ensures a persisted balance exists; returns the effective balance.
  Future<int> ensureInitialized() async {
    final raw = await _storage.read(key: StorageKeys.points);
    if (raw == null) {
      await _writeBalance(defaultBalance, notify: false);
      return defaultBalance;
    }
    _cachedBalance = int.tryParse(raw) ?? defaultBalance;
    return _cachedBalance!;
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
  Future<int?> trySpend(int amount) async {
    final current = await readBalance();
    if (current < amount) return null;
    final next = current - amount;
    await writeBalance(next);
    return next;
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
