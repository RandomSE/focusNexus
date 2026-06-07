// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$achievementServiceHash() =>
    r'219f817556d1b8827c4bc9018dbabbb0f3d3a579';

/// Achievement facade with injected storage and points.
///
/// Copied from [achievementService].
@ProviderFor(achievementService)
final achievementServiceProvider = Provider<AchievementService>.internal(
  achievementService,
  name: r'achievementServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$achievementServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AchievementServiceRef = ProviderRef<AchievementService>;
String _$soundServiceHash() => r'eff7bbec075f4c82f19389144d9a3bea00684edf';

/// Sound playback with injected storage.
///
/// Copied from [soundService].
@ProviderFor(soundService)
final soundServiceProvider = Provider<SoundService>.internal(
  soundService,
  name: r'soundServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$soundServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SoundServiceRef = ProviderRef<SoundService>;
String _$aiChatServiceHash() => r'e7fdd2a8b8730caf3efc85b35e4569000626a51c';

/// AI chat client (override in tests with a fake implementation).
///
/// Copied from [aiChatService].
@ProviderFor(aiChatService)
final aiChatServiceProvider = Provider<AiChatService>.internal(
  aiChatService,
  name: r'aiChatServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiChatServiceRef = ProviderRef<AiChatService>;
String _$goalNotifierWiringHash() =>
    r'ce11afbea2f51ecbb095da35b308a49d8a1b2dad';

/// Binds [GoalNotifier] to scoped storage (replaces static storage assignment).
///
/// Copied from [goalNotifierWiring].
@ProviderFor(goalNotifierWiring)
final goalNotifierWiringProvider = Provider<void>.internal(
  goalNotifierWiring,
  name: r'goalNotifierWiringProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$goalNotifierWiringHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoalNotifierWiringRef = ProviderRef<void>;
String _$appServicesWiredHash() => r'7c0d0b6befe1da1f230a29eb9ae75aece1eb4668';

/// Ensures injected app services are constructed for this [ProviderScope].
///
/// Copied from [appServicesWired].
@ProviderFor(appServicesWired)
final appServicesWiredProvider = Provider<void>.internal(
  appServicesWired,
  name: r'appServicesWiredProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appServicesWiredHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppServicesWiredRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
