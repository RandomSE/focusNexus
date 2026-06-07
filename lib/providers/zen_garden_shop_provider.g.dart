// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zen_garden_shop_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$zenGardenShopCartHash() => r'2984bb30a60f7b5c8d36b78fa92d6dcf11d18106';

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

abstract class _$ZenGardenShopCart
    extends BuildlessAutoDisposeNotifier<GardenState> {
  late final GardenState initial;

  GardenState build(GardenState initial);
}

/// In-sheet cart garden for the zen decoration shop bottom sheet.
///
/// Copied from [ZenGardenShopCart].
@ProviderFor(ZenGardenShopCart)
const zenGardenShopCartProvider = ZenGardenShopCartFamily();

/// In-sheet cart garden for the zen decoration shop bottom sheet.
///
/// Copied from [ZenGardenShopCart].
class ZenGardenShopCartFamily extends Family<GardenState> {
  /// In-sheet cart garden for the zen decoration shop bottom sheet.
  ///
  /// Copied from [ZenGardenShopCart].
  const ZenGardenShopCartFamily();

  /// In-sheet cart garden for the zen decoration shop bottom sheet.
  ///
  /// Copied from [ZenGardenShopCart].
  ZenGardenShopCartProvider call(GardenState initial) {
    return ZenGardenShopCartProvider(initial);
  }

  @override
  ZenGardenShopCartProvider getProviderOverride(
    covariant ZenGardenShopCartProvider provider,
  ) {
    return call(provider.initial);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'zenGardenShopCartProvider';
}

/// In-sheet cart garden for the zen decoration shop bottom sheet.
///
/// Copied from [ZenGardenShopCart].
class ZenGardenShopCartProvider
    extends AutoDisposeNotifierProviderImpl<ZenGardenShopCart, GardenState> {
  /// In-sheet cart garden for the zen decoration shop bottom sheet.
  ///
  /// Copied from [ZenGardenShopCart].
  ZenGardenShopCartProvider(GardenState initial)
    : this._internal(
        () => ZenGardenShopCart()..initial = initial,
        from: zenGardenShopCartProvider,
        name: r'zenGardenShopCartProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$zenGardenShopCartHash,
        dependencies: ZenGardenShopCartFamily._dependencies,
        allTransitiveDependencies:
            ZenGardenShopCartFamily._allTransitiveDependencies,
        initial: initial,
      );

  ZenGardenShopCartProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initial,
  }) : super.internal();

  final GardenState initial;

  @override
  GardenState runNotifierBuild(covariant ZenGardenShopCart notifier) {
    return notifier.build(initial);
  }

  @override
  Override overrideWith(ZenGardenShopCart Function() create) {
    return ProviderOverride(
      origin: this,
      override: ZenGardenShopCartProvider._internal(
        () => create()..initial = initial,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initial: initial,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ZenGardenShopCart, GardenState>
  createElement() {
    return _ZenGardenShopCartProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ZenGardenShopCartProvider && other.initial == initial;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initial.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ZenGardenShopCartRef on AutoDisposeNotifierProviderRef<GardenState> {
  /// The parameter `initial` of this provider.
  GardenState get initial;
}

class _ZenGardenShopCartProviderElement
    extends AutoDisposeNotifierProviderElement<ZenGardenShopCart, GardenState>
    with ZenGardenShopCartRef {
  _ZenGardenShopCartProviderElement(super.provider);

  @override
  GardenState get initial => (origin as ZenGardenShopCartProvider).initial;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
