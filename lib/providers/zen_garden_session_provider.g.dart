// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zen_garden_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$zenGardenSessionHash() => r'c41368eed3c58ec1ca5d071346cad8feb02db461';

/// Zen garden sandbox session; persisted via [GardenRepository].
///
/// Copied from [ZenGardenSession].
@ProviderFor(ZenGardenSession)
final zenGardenSessionProvider =
    NotifierProvider<ZenGardenSession, ZenGardenSessionState>.internal(
      ZenGardenSession.new,
      name: r'zenGardenSessionProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$zenGardenSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ZenGardenSession = Notifier<ZenGardenSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
