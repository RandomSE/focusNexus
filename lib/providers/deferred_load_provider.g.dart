// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deferred_load_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deferredScreenLoadHash() =>
    r'6ce8364f836ded2d6383a3816f555922c68afe7a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Async load with optional minimum loading duration (skeleton stability).
///
/// Copied from [deferredScreenLoad].
@ProviderFor(deferredScreenLoad)
const deferredScreenLoadProvider = DeferredScreenLoadFamily();

/// Async load with optional minimum loading duration (skeleton stability).
///
/// Copied from [deferredScreenLoad].
class DeferredScreenLoadFamily extends Family<AsyncValue<Object?>> {
  /// Async load with optional minimum loading duration (skeleton stability).
  ///
  /// Copied from [deferredScreenLoad].
  const DeferredScreenLoadFamily();

  /// Async load with optional minimum loading duration (skeleton stability).
  ///
  /// Copied from [deferredScreenLoad].
  DeferredScreenLoadProvider call(DeferredLoadParams params) {
    return DeferredScreenLoadProvider(params);
  }

  @override
  DeferredScreenLoadProvider getProviderOverride(
    covariant DeferredScreenLoadProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deferredScreenLoadProvider';
}

/// Async load with optional minimum loading duration (skeleton stability).
///
/// Copied from [deferredScreenLoad].
class DeferredScreenLoadProvider extends AutoDisposeFutureProvider<Object?> {
  /// Async load with optional minimum loading duration (skeleton stability).
  ///
  /// Copied from [deferredScreenLoad].
  DeferredScreenLoadProvider(DeferredLoadParams params)
    : this._internal(
        (ref) => deferredScreenLoad(ref as DeferredScreenLoadRef, params),
        from: deferredScreenLoadProvider,
        name: r'deferredScreenLoadProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$deferredScreenLoadHash,
        dependencies: DeferredScreenLoadFamily._dependencies,
        allTransitiveDependencies:
            DeferredScreenLoadFamily._allTransitiveDependencies,
        params: params,
      );

  DeferredScreenLoadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final DeferredLoadParams params;

  @override
  Override overrideWith(
    FutureOr<Object?> Function(DeferredScreenLoadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeferredScreenLoadProvider._internal(
        (ref) => create(ref as DeferredScreenLoadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Object?> createElement() {
    return _DeferredScreenLoadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeferredScreenLoadProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeferredScreenLoadRef on AutoDisposeFutureProviderRef<Object?> {
  /// The parameter `params` of this provider.
  DeferredLoadParams get params;
}

class _DeferredScreenLoadProviderElement
    extends AutoDisposeFutureProviderElement<Object?>
    with DeferredScreenLoadRef {
  _DeferredScreenLoadProviderElement(super.provider);

  @override
  DeferredLoadParams get params =>
      (origin as DeferredScreenLoadProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
