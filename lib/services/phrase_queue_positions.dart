/// 1-based queue position helpers for motivator / affirmation playlists.
abstract final class PhraseQueuePositions {
  PhraseQueuePositions._();

  /// Valid insert range when adding: `1 .. queueLength + 1` (last = append).
  static int maxInsertPosition(int queueLength) => queueLength + 1;

  /// Valid move range when relocating an existing slot: `1 .. queueLength`
  /// after temporary removal (same as insert into remaining list).
  static int maxMovePosition(int queueLengthAfterRemove) =>
      queueLengthAfterRemove + 1;

  static int clampInsert(int position1Based, int queueLength) {
    final max = maxInsertPosition(queueLength);
    if (position1Based < 1) return 1;
    if (position1Based > max) return max;
    return position1Based;
  }

  /// Inserts [id] at 1-based [position], shifting later items forward.
  static List<String> insertAt({
    required List<String> queue,
    required String id,
    required int position1Based,
  }) {
    final next = [...queue];
    final pos = clampInsert(position1Based, next.length);
    next.insert(pos - 1, id);
    return next;
  }

  /// Removes [fromIndex], then inserts that id at 1-based [position]
  /// (makes space by shifting items at/after the target forward).
  static List<String> moveIndexToPosition({
    required List<String> queue,
    required int fromIndex,
    required int position1Based,
  }) {
    if (fromIndex < 0 || fromIndex >= queue.length) return [...queue];
    final next = [...queue];
    final id = next.removeAt(fromIndex);
    final pos = clampInsert(position1Based, next.length);
    next.insert(pos - 1, id);
    return next;
  }

  static String hintForSize(int maxInclusive) =>
      'enter number from 1-$maxInclusive';
}
