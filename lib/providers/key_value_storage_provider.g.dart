// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$keyValueStorageHash() => r'e110ff1d09d9c447b1590313745b29172c3069c4';

/// Default secure storage; override in tests with [InMemoryKeyValueStorage].
///
/// Copied from [keyValueStorage].
@ProviderFor(keyValueStorage)
final keyValueStorageProvider = Provider<KeyValueStorage>.internal(
  keyValueStorage,
  name: r'keyValueStorageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$keyValueStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KeyValueStorageRef = ProviderRef<KeyValueStorage>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
