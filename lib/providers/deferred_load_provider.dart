import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/providers/deferred_load_params.dart';

part 'deferred_load_provider.g.dart';

/// Async load with optional minimum loading duration (skeleton stability).
@riverpod
Future<Object?> deferredScreenLoad(
  Ref ref,
  DeferredLoadParams params,
) async {
  final startedAt = DateTime.now();
  final data = await params.loader();
  final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
  final remainingMs = params.minLoadingMs - elapsedMs;
  if (remainingMs > 0) {
    await Future<void>.delayed(Duration(milliseconds: remainingMs));
  }
  return data;
}
