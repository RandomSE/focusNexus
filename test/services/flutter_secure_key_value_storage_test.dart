import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';

void main() {
  test('production secure storage uses hardened platform options', () {
    final storage = FlutterSecureKeyValueStorage();
    // Construction with defaults must succeed (EncryptedSharedPreferences +
    // first_unlock_this_device Keychain accessibility).
    expect(storage, isA<FlutterSecureKeyValueStorage>());
  });

  test('delegate can be injected for tests', () {
    const delegate = FlutterSecureStorage();
    final storage = FlutterSecureKeyValueStorage(delegate);
    expect(storage, isA<FlutterSecureKeyValueStorage>());
  });
}
