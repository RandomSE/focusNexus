import 'package:flutter/foundation.dart';

/// Debug-only console output; no-op in profile and release builds.
void debugLog(String? message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
