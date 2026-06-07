import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
part 'app_repositories_provider.g.dart';

/// Shared repositories graph; one instance per [ProviderScope].
@Riverpod(keepAlive: true)
AppRepositories appRepositories(Ref ref) {
  final storage = ref.watch(keyValueStorageProvider);
  final repos = AppRepositories(storage);
  ref.onDispose(AppRepositories.resetForTesting);
  return repos;
}
