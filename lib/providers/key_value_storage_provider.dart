import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';

part 'key_value_storage_provider.g.dart';

/// Default secure storage; override in tests with [InMemoryKeyValueStorage].
@Riverpod(keepAlive: true)
KeyValueStorage keyValueStorage(Ref ref) {
  return const FlutterSecureKeyValueStorage();
}
