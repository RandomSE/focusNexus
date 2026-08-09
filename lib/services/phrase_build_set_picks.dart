import 'package:focusNexus/services/phrase_queue_positions.dart';

/// Build-set pick list helpers. Duplicate message ids are allowed (one entry
/// per queue instance). New picks default to the end of the building set.
abstract final class PhraseBuildSetPicks {
  PhraseBuildSetPicks._();

  /// Appends [id] at the default last 1-based position.
  static List<({String id, int position1Based})> append({
    required List<({String id, int position1Based})> picks,
    required String id,
  }) {
    final position = PhraseQueuePositions.maxInsertPosition(picks.length);
    return [...picks, (id: id, position1Based: position)];
  }

  /// Indexes of every pick whose message id is [id].
  static List<int> indexesOf(
    List<({String id, int position1Based})> picks,
    String id,
  ) {
    return [
      for (var i = 0; i < picks.length; i++)
        if (picks[i].id == id) i,
    ];
  }

  static List<({String id, int position1Based})> removeAt(
    List<({String id, int position1Based})> picks,
    int index,
  ) {
    if (index < 0 || index >= picks.length) return [...picks];
    final next = [...picks]..removeAt(index);
    return next;
  }

  static List<({String id, int position1Based})> setPosition(
    List<({String id, int position1Based})> picks,
    int index,
    int position1Based,
  ) {
    if (index < 0 || index >= picks.length) return [...picks];
    final next = [...picks];
    next[index] = (id: next[index].id, position1Based: position1Based);
    return next;
  }
}
