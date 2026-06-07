import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/models/user_prefs_snapshot.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/settings/app_settings.dart' as settings;

part 'app_settings_provider.g.dart';

/// Riverpod-facing settings state (snapshot + load flag).
class AppSettingsViewState {
  const AppSettingsViewState({
    required this.snapshot,
    required this.isLoaded,
  });

  final UserPrefsSnapshot snapshot;
  final bool isLoaded;

  static const initial = AppSettingsViewState(
    snapshot: UserPrefsSnapshot(),
    isLoaded: false,
  );
}

/// Rebuilds when [settings.AppSettings] mutates its snapshot.
@Riverpod(keepAlive: true)
class AppSettingsView extends _$AppSettingsView {
  late settings.AppSettings _settings;

  @override
  AppSettingsViewState build() {
    ref.watch(appServicesWiredProvider);
    _settings = ref.watch(appRepositoriesProvider).settings;
    _settings.onSnapshotChanged = _syncFromService;
    ref.onDispose(() {
      if (_settings.onSnapshotChanged == _syncFromService) {
        _settings.onSnapshotChanged = null;
      }
    });
    return AppSettingsViewState(
      snapshot: _settings.snapshot,
      isLoaded: _settings.isLoaded,
    );
  }

  void _syncFromService() {
    state = AppSettingsViewState(
      snapshot: _settings.snapshot,
      isLoaded: _settings.isLoaded,
    );
  }

  settings.AppSettings get service => _settings;

  Future<void> load() async {
    await _settings.load();
    _syncFromService();
  }

  Future<void> reload() => load();
}

/// Live settings service (mutations + persistence).
@Riverpod(keepAlive: true)
settings.AppSettings appSettingsService(Ref ref) {
  ref.watch(appServicesWiredProvider);
  return ref.watch(appRepositoriesProvider).settings;
}

/// Stable alias used across the app (generated: [appSettingsViewProvider]).
final appSettingsProvider = appSettingsViewProvider;
