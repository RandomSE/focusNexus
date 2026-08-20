import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_storage.dart';

/// Production [KeyValueStorage] using [FlutterSecureStorage].
///
/// Android uses EncryptedSharedPreferences. iOS Keychain items are limited to
/// this device after first unlock. Cloud backup of app data is disabled in the
/// Android manifest where configured; uninstall/clear-data still wipes local
/// FocusNexus preferences (no import/export in this build).
class FlutterSecureKeyValueStorage implements KeyValueStorage {
  FlutterSecureKeyValueStorage([FlutterSecureStorage? delegate])
      : _delegate = delegate ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

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
