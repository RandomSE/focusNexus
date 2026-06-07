// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zen_garden_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$zenGardenSessionHash() => r'cf9a0f53f38745ae6e7c642cd0051ae59d9984be';

/// Zen garden sandbox session (auto-dispose when leaving the screen).
///
/// Copied from [ZenGardenSession].
@ProviderFor(ZenGardenSession)
final zenGardenSessionProvider = AutoDisposeNotifierProvider<
  ZenGardenSession,
  ZenGardenSessionState
>.internal(
  ZenGardenSession.new,
  name: r'zenGardenSessionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$zenGardenSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ZenGardenSession = AutoDisposeNotifier<ZenGardenSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
