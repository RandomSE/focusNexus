import 'package:focusNexus/services/storage/key_value_storage.dart';

/// Test [KeyValueStorage] that optionally delays [write] for selected keys.
class DelayingKeyValueStorage implements KeyValueStorage {
  DelayingKeyValueStorage(
    this._inner, {
    this.delayKeys = const {},
    this.writeDelay = const Duration(milliseconds: 250),
  });

  final KeyValueStorage _inner;
  final Set<String> delayKeys;
  final Duration writeDelay;

  var delayedWriteInFlight = false;
  var delayedWriteCompleted = false;

  @override
  Future<void> delete({required String key}) => _inner.delete(key: key);

  @override
  Future<String?> read({required String key}) => _inner.read(key: key);

  @override
  Future<void> write({required String key, required String value}) async {
    if (delayKeys.contains(key)) {
      delayedWriteInFlight = true;
      await Future<void>.delayed(writeDelay);
      delayedWriteInFlight = false;
      delayedWriteCompleted = true;
    }
    await _inner.write(key: key, value: value);
  }

  @override
  Future<void> deleteAll() => _inner.deleteAll();
}
