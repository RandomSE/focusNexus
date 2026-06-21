// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$achievementServiceHash() =>
    r'30d493fd896a6ec7385ec4da0bb6b84745a088eb';

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
String _$achievementTrackingWiringHash() =>
    r'ddf95e8fcbd6c8289b1faac14fafdb7ea96fb166';

/// Binds [AchievementTrackingVariables] to scoped storage.
///
/// Copied from [achievementTrackingWiring].
@ProviderFor(achievementTrackingWiring)
final achievementTrackingWiringProvider = Provider<void>.internal(
  achievementTrackingWiring,
  name: r'achievementTrackingWiringProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$achievementTrackingWiringHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AchievementTrackingWiringRef = ProviderRef<void>;
String _$appServicesWiredHash() => r'fd6e64f85497d29132a7b026e2dc463e410c1305';

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
