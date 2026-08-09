import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/phrase_build_set_picks.dart';
import 'package:focusNexus/services/phrase_queue_positions.dart';

void main() {
  group('PhraseBuildSetPicks', () {
    test('append defaults each pick to end (1-based last)', () {
      var picks = <({String id, int position1Based})>[];

      picks = PhraseBuildSetPicks.append(picks: picks, id: 'a');
      expect(picks, [(id: 'a', position1Based: 1)]);
      expect(
        picks.last.position1Based,
        PhraseQueuePositions.maxInsertPosition(0),
      );

      picks = PhraseBuildSetPicks.append(picks: picks, id: 'a');
      expect(picks, [
        (id: 'a', position1Based: 1),
        (id: 'a', position1Based: 2),
      ]);

      picks = PhraseBuildSetPicks.append(picks: picks, id: 'b');
      expect(picks.map((p) => p.id).toList(), ['a', 'a', 'b']);
      expect(picks.last.position1Based, 3);
    });

    test('indexesOf returns every instance for a message id', () {
      final picks = [
        (id: 'a', position1Based: 1),
        (id: 'b', position1Based: 2),
        (id: 'a', position1Based: 3),
      ];
      expect(PhraseBuildSetPicks.indexesOf(picks, 'a'), [0, 2]);
      expect(PhraseBuildSetPicks.indexesOf(picks, 'b'), [1]);
      expect(PhraseBuildSetPicks.indexesOf(picks, 'z'), isEmpty);
    });

    test('removeAt drops one instance without touching others', () {
      final picks = [
        (id: 'a', position1Based: 1),
        (id: 'a', position1Based: 2),
        (id: 'b', position1Based: 3),
      ];
      expect(
        PhraseBuildSetPicks.removeAt(picks, 0),
        [
          (id: 'a', position1Based: 2),
          (id: 'b', position1Based: 3),
        ],
      );
      expect(PhraseBuildSetPicks.removeAt(picks, 99), picks);
    });

    test('setPosition updates only the targeted instance', () {
      final picks = [
        (id: 'a', position1Based: 1),
        (id: 'a', position1Based: 2),
      ];
      expect(
        PhraseBuildSetPicks.setPosition(picks, 1, 1),
        [
          (id: 'a', position1Based: 1),
          (id: 'a', position1Based: 1),
        ],
      );
      expect(PhraseBuildSetPicks.setPosition(picks, -1, 9), picks);
    });
  });
}
