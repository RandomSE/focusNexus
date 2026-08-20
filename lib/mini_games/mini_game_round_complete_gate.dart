/// Tracks in-flight round completion so dismiss/back waits for persistence.
class MiniGameRoundCompleteGate {
  Future<void>? _inFlight;

  /// Starts [onRoundComplete] once; returns the same future for later awaiters.
  Future<void> ensure(Future<void> Function() onRoundComplete) {
    return _inFlight ??= onRoundComplete();
  }
}
