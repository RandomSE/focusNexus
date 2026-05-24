import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_storage.dart';

/// Production [KeyValueStorage] using [FlutterSecureStorage].
class FlutterSecureKeyValueStorage implements KeyValueStorage {
  const FlutterSecureKeyValueStorage([this._delegate = const FlutterSecureStorage()]);

  final FlutterSecureStorage _delegate;

  @override
  Future<String?> read({required String key}) => _delegate.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _delegate.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _delegate.delete(key: key);

  @override
  Future<void> deleteAll() => _delegate.deleteAll();
}
