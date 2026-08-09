import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/phrase_queue_positions.dart';

void main() {
  group('PhraseQueuePositions', () {
    test('insertAt appends when position is last', () {
      expect(
        PhraseQueuePositions.insertAt(
          queue: ['a', 'b'],
          id: 'c',
          position1Based: 3,
        ),
        ['a', 'b', 'c'],
      );
    });

    test('insertAt shifts later items forward', () {
      expect(
        PhraseQueuePositions.insertAt(
          queue: ['a', 'b', 'c'],
          id: 'x',
          position1Based: 2,
        ),
        ['a', 'x', 'b', 'c'],
      );
    });

    test('moveIndexToPosition removes then inserts with shift', () {
      expect(
        PhraseQueuePositions.moveIndexToPosition(
          queue: ['a', 'b', 'c', 'd'],
          fromIndex: 2,
          position1Based: 1,
        ),
        ['c', 'a', 'b', 'd'],
      );
    });

    test('clamp and hint track size', () {
      expect(PhraseQueuePositions.maxInsertPosition(0), 1);
      expect(PhraseQueuePositions.maxInsertPosition(4), 5);
      expect(PhraseQueuePositions.clampInsert(99, 2), 3);
      expect(PhraseQueuePositions.hintForSize(5), 'enter number from 1-5');
    });
  });
}
