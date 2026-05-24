import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Wallet / reward points (`StorageKeys.points`).
class PointsRepository {
  PointsRepository(this._storage);

  final KeyValueStorage _storage;

  static const defaultBalance = 50;

  Future<int> readBalance() async {
    final raw = await _storage.read(key: StorageKeys.points);
    if (raw == null) return defaultBalance;
    return int.tryParse(raw) ?? defaultBalance;
  }

  /// Ensures a persisted balance exists; returns the effective balance.
  Future<int> ensureInitialized() async {
    final raw = await _storage.read(key: StorageKeys.points);
    if (raw == null) {
      await _storage.write(
        key: StorageKeys.points,
        value: defaultBalance.toString(),
      );
      return defaultBalance;
    }
    return int.tryParse(raw) ?? defaultBalance;
  }

  Future<void> writeBalance(int balance) async {
    await _storage.write(key: StorageKeys.points, value: balance.toString());
  }

  /// Deducts [amount] when sufficient; returns new balance or null if insufficient.
  Future<int?> trySpend(int amount) async {
    final current = await readBalance();
    if (current < amount) return null;
    final next = current - amount;
    await writeBalance(next);
    return next;
  }

  Future<void> add(int amount) async {
    final current = await readBalance();
    await writeBalance(current + amount);
  }
}
