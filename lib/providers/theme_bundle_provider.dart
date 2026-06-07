import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';

part 'theme_bundle_provider.g.dart';

/// [ThemeBundle] derived from the current settings snapshot.
@Riverpod(keepAlive: true)
ThemeBundle themeBundle(Ref ref) {
  final repos = ref.watch(appRepositoriesProvider);
  final snap = ref.watch(appSettingsProvider).snapshot;
  return repos.theme.bundleFromSnapshot(snap);
}
