import 'package:focusNexus/services/storage/key_value_storage.dart';

/// Wraps storage with per-operation delay (simulates slow secure storage).
class LatencyKeyValueStorage implements KeyValueStorage {
  LatencyKeyValueStorage({
    required KeyValueStorage inner,
    this.operationDelay = const Duration(milliseconds: 100),
  }) : _inner = inner;

  final KeyValueStorage _inner;
  final Duration operationDelay;

  Future<void> _delay() => Future<void>.delayed(operationDelay);

  @override
  Future<String?> read({required String key}) async {
    await _delay();
    return _inner.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _delay();
    await _inner.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) async {
    await _delay();
    await _inner.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _delay();
    await _inner.deleteAll();
  }
}

/// Budget for notifier-level create/complete (no widget tree).
/// Sync notifier mutation budget (allows headroom under parallel `flutter test`).
const int goalsUiUpdateBudgetMs = 350;

/// Budget for GoalsScreen tap → list repaint (sliver layout; notifier path uses [goalsUiUpdateBudgetMs]).
const int goalsWidgetUiUpdateBudgetMs = 2000;
