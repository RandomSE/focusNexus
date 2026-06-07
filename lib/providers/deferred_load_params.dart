/// Family key for [deferredScreenLoadProvider]; [loader] is not part of equality.
class DeferredLoadParams {
  const DeferredLoadParams({
    required this.token,
    required this.loader,
    this.minLoadingMs = 0,
  });

  final String token;
  final int minLoadingMs;
  final Future<Object?> Function() loader;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeferredLoadParams &&
            token == other.token &&
            minLoadingMs == other.minLoadingMs;
  }

  @override
  int get hashCode => Object.hash(token, minLoadingMs);
}
