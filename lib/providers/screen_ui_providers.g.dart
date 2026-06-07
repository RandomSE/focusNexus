// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardPointsGenerationHash() =>
    r'c30a73b1b2d9fb66e3a3a0092aad175cdf3ecd6c';

/// See also [DashboardPointsGeneration].
@ProviderFor(DashboardPointsGeneration)
final dashboardPointsGenerationProvider =
    AutoDisposeNotifierProvider<DashboardPointsGeneration, int>.internal(
      DashboardPointsGeneration.new,
      name: r'dashboardPointsGenerationProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$dashboardPointsGenerationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardPointsGeneration = AutoDisposeNotifier<int>;
String _$settingsNotificationsAllowedHash() =>
    r'd935c1f2b6567d43c0e713306ce455e50dc86762';

/// See also [SettingsNotificationsAllowed].
@ProviderFor(SettingsNotificationsAllowed)
final settingsNotificationsAllowedProvider =
    AutoDisposeNotifierProvider<SettingsNotificationsAllowed, bool>.internal(
      SettingsNotificationsAllowed.new,
      name: r'settingsNotificationsAllowedProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$settingsNotificationsAllowedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsNotificationsAllowed = AutoDisposeNotifier<bool>;
String _$settingsDeletingAccountHash() =>
    r'8b424f961f9e3bdf26a9441f755ac82aee93cf95';

/// See also [SettingsDeletingAccount].
@ProviderFor(SettingsDeletingAccount)
final settingsDeletingAccountProvider =
    AutoDisposeNotifierProvider<SettingsDeletingAccount, bool>.internal(
      SettingsDeletingAccount.new,
      name: r'settingsDeletingAccountProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$settingsDeletingAccountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsDeletingAccount = AutoDisposeNotifier<bool>;
String _$onboardingPageIndexHash() =>
    r'979d3f33349a1f48e67f1f70e7f59fa97f1a7fb7';

/// See also [OnboardingPageIndex].
@ProviderFor(OnboardingPageIndex)
final onboardingPageIndexProvider =
    AutoDisposeNotifierProvider<OnboardingPageIndex, int>.internal(
      OnboardingPageIndex.new,
      name: r'onboardingPageIndexProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$onboardingPageIndexHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingPageIndex = AutoDisposeNotifier<int>;
String _$aiChatMessagesHash() => r'6a2b8c77c118ee6bb287b06eb3a08c189e806c65';

/// See also [AiChatMessages].
@ProviderFor(AiChatMessages)
final aiChatMessagesProvider = AutoDisposeNotifierProvider<
  AiChatMessages,
  List<Map<String, String>>
>.internal(
  AiChatMessages.new,
  name: r'aiChatMessagesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiChatMessages = AutoDisposeNotifier<List<Map<String, String>>>;
String _$aiChatDisclaimerAcceptedHash() =>
    r'f28ee8723c87f8f7fcc07356711f8a0405a2a0bd';

/// Session flag: user accepted the AI chat legal notice for this app run.
///
/// Copied from [AiChatDisclaimerAccepted].
@ProviderFor(AiChatDisclaimerAccepted)
final aiChatDisclaimerAcceptedProvider =
    AutoDisposeNotifierProvider<AiChatDisclaimerAccepted, bool>.internal(
      AiChatDisclaimerAccepted.new,
      name: r'aiChatDisclaimerAcceptedProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$aiChatDisclaimerAcceptedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatDisclaimerAccepted = AutoDisposeNotifier<bool>;
String _$soundVolumeLiveHash() => r'7d34aa68510c48dd46c294ac6b3f688bc9ba10b5';

/// See also [SoundVolumeLive].
@ProviderFor(SoundVolumeLive)
final soundVolumeLiveProvider =
    AutoDisposeNotifierProvider<SoundVolumeLive, int?>.internal(
      SoundVolumeLive.new,
      name: r'soundVolumeLiveProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$soundVolumeLiveHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SoundVolumeLive = AutoDisposeNotifier<int?>;
String _$achievementDetailDisabledHash() =>
    r'1f31cc082662ac3b1d0e22ea659a66d2ad180fe4';

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

abstract class _$AchievementDetailDisabled
    extends BuildlessAutoDisposeNotifier<bool> {
  late final String achievementId;

  bool build(String achievementId);
}

/// See also [AchievementDetailDisabled].
@ProviderFor(AchievementDetailDisabled)
const achievementDetailDisabledProvider = AchievementDetailDisabledFamily();

/// See also [AchievementDetailDisabled].
class AchievementDetailDisabledFamily extends Family<bool> {
  /// See also [AchievementDetailDisabled].
  const AchievementDetailDisabledFamily();

  /// See also [AchievementDetailDisabled].
  AchievementDetailDisabledProvider call(String achievementId) {
    return AchievementDetailDisabledProvider(achievementId);
  }

  @override
  AchievementDetailDisabledProvider getProviderOverride(
    covariant AchievementDetailDisabledProvider provider,
  ) {
    return call(provider.achievementId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'achievementDetailDisabledProvider';
}

/// See also [AchievementDetailDisabled].
class AchievementDetailDisabledProvider
    extends AutoDisposeNotifierProviderImpl<AchievementDetailDisabled, bool> {
  /// See also [AchievementDetailDisabled].
  AchievementDetailDisabledProvider(String achievementId)
    : this._internal(
        () => AchievementDetailDisabled()..achievementId = achievementId,
        from: achievementDetailDisabledProvider,
        name: r'achievementDetailDisabledProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$achievementDetailDisabledHash,
        dependencies: AchievementDetailDisabledFamily._dependencies,
        allTransitiveDependencies:
            AchievementDetailDisabledFamily._allTransitiveDependencies,
        achievementId: achievementId,
      );

  AchievementDetailDisabledProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.achievementId,
  }) : super.internal();

  final String achievementId;

  @override
  bool runNotifierBuild(covariant AchievementDetailDisabled notifier) {
    return notifier.build(achievementId);
  }

  @override
  Override overrideWith(AchievementDetailDisabled Function() create) {
    return ProviderOverride(
      origin: this,
      override: AchievementDetailDisabledProvider._internal(
        () => create()..achievementId = achievementId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        achievementId: achievementId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AchievementDetailDisabled, bool>
  createElement() {
    return _AchievementDetailDisabledProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementDetailDisabledProvider &&
        other.achievementId == achievementId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, achievementId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AchievementDetailDisabledRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `achievementId` of this provider.
  String get achievementId;
}

class _AchievementDetailDisabledProviderElement
    extends AutoDisposeNotifierProviderElement<AchievementDetailDisabled, bool>
    with AchievementDetailDisabledRef {
  _AchievementDetailDisabledProviderElement(super.provider);

  @override
  String get achievementId =>
      (origin as AchievementDetailDisabledProvider).achievementId;
}

String _$achievementDetailRefreshHash() =>
    r'134d135732a071708ea781969c41d9f759792c4f';

abstract class _$AchievementDetailRefresh
    extends BuildlessAutoDisposeNotifier<bool> {
  late final String achievementId;

  bool build(String achievementId);
}

/// See also [AchievementDetailRefresh].
@ProviderFor(AchievementDetailRefresh)
const achievementDetailRefreshProvider = AchievementDetailRefreshFamily();

/// See also [AchievementDetailRefresh].
class AchievementDetailRefreshFamily extends Family<bool> {
  /// See also [AchievementDetailRefresh].
  const AchievementDetailRefreshFamily();

  /// See also [AchievementDetailRefresh].
  AchievementDetailRefreshProvider call(String achievementId) {
    return AchievementDetailRefreshProvider(achievementId);
  }

  @override
  AchievementDetailRefreshProvider getProviderOverride(
    covariant AchievementDetailRefreshProvider provider,
  ) {
    return call(provider.achievementId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'achievementDetailRefreshProvider';
}

/// See also [AchievementDetailRefresh].
class AchievementDetailRefreshProvider
    extends AutoDisposeNotifierProviderImpl<AchievementDetailRefresh, bool> {
  /// See also [AchievementDetailRefresh].
  AchievementDetailRefreshProvider(String achievementId)
    : this._internal(
        () => AchievementDetailRefresh()..achievementId = achievementId,
        from: achievementDetailRefreshProvider,
        name: r'achievementDetailRefreshProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$achievementDetailRefreshHash,
        dependencies: AchievementDetailRefreshFamily._dependencies,
        allTransitiveDependencies:
            AchievementDetailRefreshFamily._allTransitiveDependencies,
        achievementId: achievementId,
      );

  AchievementDetailRefreshProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.achievementId,
  }) : super.internal();

  final String achievementId;

  @override
  bool runNotifierBuild(covariant AchievementDetailRefresh notifier) {
    return notifier.build(achievementId);
  }

  @override
  Override overrideWith(AchievementDetailRefresh Function() create) {
    return ProviderOverride(
      origin: this,
      override: AchievementDetailRefreshProvider._internal(
        () => create()..achievementId = achievementId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        achievementId: achievementId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AchievementDetailRefresh, bool>
  createElement() {
    return _AchievementDetailRefreshProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementDetailRefreshProvider &&
        other.achievementId == achievementId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, achievementId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AchievementDetailRefreshRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `achievementId` of this provider.
  String get achievementId;
}

class _AchievementDetailRefreshProviderElement
    extends AutoDisposeNotifierProviderElement<AchievementDetailRefresh, bool>
    with AchievementDetailRefreshRef {
  _AchievementDetailRefreshProviderElement(super.provider);

  @override
  String get achievementId =>
      (origin as AchievementDetailRefreshProvider).achievementId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
