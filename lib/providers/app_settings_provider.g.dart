// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSettingsServiceHash() =>
    r'99503c9e6f9e4602e896a010f3f3c64991a5d87a';

/// Live settings service (mutations + persistence).
///
/// Copied from [appSettingsService].
@ProviderFor(appSettingsService)
final appSettingsServiceProvider = Provider<settings.AppSettings>.internal(
  appSettingsService,
  name: r'appSettingsServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appSettingsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppSettingsServiceRef = ProviderRef<settings.AppSettings>;
String _$appSettingsViewHash() => r'2b19eab6fbd4c3bdd2b66170cc0334a9e1578906';

/// Rebuilds when [settings.AppSettings] mutates its snapshot.
///
/// Copied from [AppSettingsView].
@ProviderFor(AppSettingsView)
final appSettingsViewProvider =
    NotifierProvider<AppSettingsView, AppSettingsViewState>.internal(
      AppSettingsView.new,
      name: r'appSettingsViewProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$appSettingsViewHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppSettingsView = Notifier<AppSettingsViewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
