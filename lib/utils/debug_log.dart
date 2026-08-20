import 'package:flutter/foundation.dart';

/// Debug-only console output; no-op in profile and release builds.
void debugLog(String? message) {
  emitDebugLog(message, enabled: kDebugMode, write: debugPrint);
}

/// Testable write gate for [debugLog].
///
/// Prefer [debugLog] in production code. Tests inject [enabled] and [write]
/// because `flutter test` always runs with [kDebugMode] true.
@visibleForTesting
void emitDebugLog(
  String? message, {
  required bool enabled,
  required void Function(String? message) write,
}) {
  if (enabled) {
    write(message);
  }
}
