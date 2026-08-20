import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/utils/affirmation_selector.dart';

PhrasePackData _pack({
  bool enabled = true,
  PhrasePlaybackMode mode = PhrasePlaybackMode.sequence,
  List<PhraseMessage>? messages,
  List<String>? queue,
  List<PhrasePreset>? presets,
}) {
  final msgs = messages ??
      const [
        PhraseMessage(
          id: 'a',
          text: 'Alpha',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.custom,
        ),
        PhraseMessage(
          id: 'b',
          text: 'Beta',
          createdAtMs: 2,
          updatedAtMs: 2,
          origin: PhraseOrigin.baseline,
        ),
        PhraseMessage(
          id: 'c',
          text: 'Gamma',
          createdAtMs: 3,
          updatedAtMs: 3,
          origin: PhraseOrigin.custom,
        ),
      ];
  return PhrasePackData(
    enabled: enabled,
    mode: mode,
    messages: msgs,
    queueIds: queue ?? msgs.map((m) => m.id).toList(),
    presets: presets ?? const [],
  );
}

void main() {
  group('PhrasePackRules.normalizeText', () {
    test('rejects empty and whitespace', () {
      expect(PhrasePackRules.normalizeText(''), isNull);
      expect(PhrasePackRules.normalizeText('   '), isNull);
    });

    test('trims and clamps to max length', () {
      expect(PhrasePackRules.normalizeText('  hi  '), 'hi');
      final long = 'x' * 200;
      final normalized = PhrasePackRules.normalizeText(long);
      expect(normalized, isNotNull);
      expect(normalized!.length, PhrasePackRules.maxTextLength);
    });
  });

  group('PhrasePackRules.seedBaselines', () {
    test('seeds dashboard motivator baselines only', () {
      final seeded = PhrasePackRules.seedBaselines(
        PhrasePackKind.dashboardMotivator,
        nowMs: 1,
      );
      expect(seeded.length, AdhdMotivatorPack.lines.length);
      expect(seeded.every((m) => m.origin == PhraseOrigin.baseline), isTrue);
      expect(seeded.first.id, 'bm_0');
      expect(seeded.first.text, AdhdMotivatorPack.lines.first);
    });

    test('seeds daily affirmation baselines only', () {
      final seeded = PhrasePackRules.seedBaselines(
        PhrasePackKind.dailyAffirmation,
        nowMs: 1,
      );
      expect(seeded.length, AffirmationSelector.cores.length);
      expect(seeded.every((m) => m.origin == PhraseOrigin.baseline), isTrue);
      expect(seeded.first.id, 'ba_0');
      expect(seeded.first.text, AffirmationSelector.cores.first);
    });
  });

  group('PhraseOrigin.parse', () {
    test('maps legacy baselineMotivator and baselineAffirmation to baseline', () {
      expect(
        PhraseOrigin.parse('baselineMotivator'),
        PhraseOrigin.baseline,
      );
      expect(
        PhraseOrigin.parse('baselineAffirmation'),
        PhraseOrigin.baseline,
      );
      expect(PhraseOrigin.parse('baseline'), PhraseOrigin.baseline);
      expect(PhraseOrigin.parse('custom'), PhraseOrigin.custom);
    });

    test('infers baseline from bm_/ba_ ids when origin missing', () {
      expect(
        PhraseOrigin.parse(null, id: 'bm_3'),
        PhraseOrigin.baseline,
      );
      expect(
        PhraseOrigin.parse(null, id: 'ba_1'),
        PhraseOrigin.baseline,
      );
      expect(PhraseOrigin.parse(null, id: 'm_1'), PhraseOrigin.custom);
    });
  });

  group('PhrasePackCodec', () {
    test('round-trips pack with duplicate queue ids and presets', () {
      final original = _pack(
        queue: ['a', 'b', 'a'],
        presets: const [
          PhrasePreset(id: 'p1', name: 'Focus', queueIds: ['a', 'c']),
        ],
      );
      final encoded = PhrasePackCodec.encode(original);
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      expect(map.containsKey('queue'), isTrue);
      expect(map.containsKey('playlist'), isFalse);
      expect(map.containsKey('contentFilter'), isFalse);

      final decoded = PhrasePackCodec.decode(encoded);
      expect(decoded.enabled, isTrue);
      expect(decoded.mode, PhrasePlaybackMode.sequence);
      expect(decoded.messages.map((m) => m.id), ['a', 'b', 'c']);
      expect(decoded.queueIds, ['a', 'b', 'a']);
      expect(decoded.messages[1].origin, PhraseOrigin.baseline);
      expect(decoded.presets, hasLength(1));
      expect(decoded.presets.single.name, 'Focus');
      expect(decoded.presets.single.queueIds, ['a', 'c']);
    });

    test('reads legacy playlist key as queue', () {
      final raw = jsonEncode({
        'enabled': true,
        'mode': 'sequence',
        'messages': [
          {
            'id': 'a',
            'text': 'Alpha',
            'createdAtMs': 1,
            'updatedAtMs': 1,
            'origin': 'custom',
          },
          {
            'id': 'b',
            'text': 'Beta',
            'createdAtMs': 2,
            'updatedAtMs': 2,
            'origin': 'baselineMotivator',
          },
        ],
        'playlist': ['b', 'a', 'b'],
      });
      final decoded = PhrasePackCodec.decode(raw);
      expect(decoded.queueIds, ['b', 'a', 'b']);
      expect(decoded.messages[1].origin, PhraseOrigin.baseline);
    });

    test('empty / corrupt raw returns empty pack', () {
      for (final raw in [null, '', '{']) {
        final pack = PhrasePackCodec.decode(raw);
        expect(pack.enabled, isFalse);
        expect(pack.messages, isEmpty);
        expect(pack.queueIds, isEmpty);
        expect(pack.presets, isEmpty);
      }
    });

    test('enabled with zero messages is forced off on decode', () {
      final encoded = PhrasePackCodec.encode(
        const PhrasePackData(
          enabled: true,
          mode: PhrasePlaybackMode.sequence,
          messages: [],
          queueIds: [],
          presets: [],
        ),
      );
      expect(PhrasePackCodec.decode(encoded).enabled, isFalse);
    });
  });

  group('PhrasePackSelector', () {
    test('disabled pack returns null custom core (baseline used)', () {
      final pack = _pack(enabled: false);
      final day = DateTime(2026, 8, 6);
      expect(PhrasePackSelector.customCoreForDate(pack, day), isNull);
      expect(
        PhrasePackSelector.dashboardLineForDate(pack, day),
        AdhdMotivatorPack.forDate(day),
      );
    });

    test('sequence mode is day-stable and respects A->B->A queue', () {
      final pack = _pack(queue: ['a', 'b', 'a']);
      final day = DateTime(2026, 8, 6);
      final index = PhrasePackSelector.sequenceIndexForDate(pack, day);
      final morning = PhrasePackSelector.customCoreForDate(pack, day);
      final evening = PhrasePackSelector.customCoreForDate(
        pack,
        DateTime(2026, 8, 6, 21),
      );
      expect(morning, evening);
      expect(morning, PhrasePackSelector.lineAtQueueIndex(pack, index));
      expect(PhrasePackSelector.lineAtPlaylistIndex(pack, 0), 'Alpha');
      expect(PhrasePackSelector.lineAtPlaylistIndex(pack, 1), 'Beta');
      expect(PhrasePackSelector.lineAtPlaylistIndex(pack, 2), 'Alpha');
    });

    test('queue includes baseline and custom without contentFilter', () {
      final pack = _pack(queue: ['a', 'b', 'c']);
      expect(pack.effectiveQueue, ['a', 'b', 'c']);
      expect(PhrasePackSelector.lineAtQueueIndex(pack, 1), 'Beta');
      expect(PhrasePackSelector.lineAtQueueIndex(pack, 2), 'Gamma');
    });

    test('random mode is day-stable', () {
      final pack = _pack(mode: PhrasePlaybackMode.random);
      final d1 = DateTime(2026, 1, 1);
      final a = PhrasePackSelector.customCoreForDate(pack, d1);
      final b = PhrasePackSelector.customCoreForDate(
        pack,
        DateTime(2026, 1, 1, 18),
      );
      expect(a, b);
      expect(['Alpha', 'Beta', 'Gamma'], contains(a));
    });

    test('default insert slot is what sequence playback picks after add', () {
      final pack = _pack(queue: ['a', 'b', 'c']);
      final now = DateTime(2026, 8, 16);
      final pos = PhrasePackSelector.defaultInsertPosition1Based(
        currentQueueLength: pack.effectiveQueue.length,
        mode: PhrasePlaybackMode.sequence,
        now: now,
      );
      final nextQueue = PhrasePackQueue.insertMessage(
        queue: pack.effectiveQueue,
        id: 'new',
        position1Based: pos,
      );
      final next = pack.copyWith(
        messages: [
          ...pack.messages,
          const PhraseMessage(
            id: 'new',
            text: 'Fresh',
            createdAtMs: 9,
            updatedAtMs: 9,
          ),
        ],
        queueIds: nextQueue,
      );
      expect(PhrasePackSelector.customCoreForDate(next, now), 'Fresh');
      expect(
        nextQueue[PhrasePackSelector.sequenceIndexForDate(next, now)],
        'new',
      );
    });

    test('default insert slot is what random playback picks after add', () {
      final pack = _pack(mode: PhrasePlaybackMode.random, queue: ['a', 'b']);
      final now = DateTime(2026, 3, 3);
      final pos = PhrasePackSelector.defaultInsertPosition1Based(
        currentQueueLength: pack.effectiveQueue.length,
        mode: PhrasePlaybackMode.random,
        now: now,
      );
      final nextQueue = PhrasePackQueue.insertMessage(
        queue: pack.effectiveQueue,
        id: 'new',
        position1Based: pos,
      );
      final next = pack.copyWith(
        messages: [
          ...pack.messages,
          const PhraseMessage(
            id: 'new',
            text: 'Fresh random',
            createdAtMs: 9,
            updatedAtMs: 9,
          ),
        ],
        queueIds: nextQueue,
      );
      expect(PhrasePackSelector.customCoreForDate(next, now), 'Fresh random');
    });

    test('default insert slot is 1 when the queue is empty', () {
      expect(
        PhrasePackSelector.defaultInsertPosition1Based(
          currentQueueLength: 0,
          mode: PhrasePlaybackMode.sequence,
          now: DateTime(2026, 8, 16),
        ),
        1,
      );
    });

    test('nextRandomMessageIndex prefers a different index', () {
      final next = PhrasePackSelector.nextRandomMessageIndex(
        messageCount: 3,
        currentIndex: 1,
        random: Random(0),
      );
      expect(next, isNot(1));
      expect(next, inInclusiveRange(0, 2));
    });
  });

  group('PhrasePackQueue.migrateLegacy', () {
    test('splits shared library by kind ids', () {
      final legacy = PhrasePackData(
        enabled: true,
        mode: PhrasePlaybackMode.sequence,
        messages: const [
          PhraseMessage(
            id: 'bm_0',
            text: 'Mot',
            createdAtMs: 1,
            updatedAtMs: 1,
            origin: PhraseOrigin.baseline,
          ),
          PhraseMessage(
            id: 'ba_0',
            text: 'Aff',
            createdAtMs: 1,
            updatedAtMs: 1,
            origin: PhraseOrigin.baseline,
          ),
          PhraseMessage(
            id: 'm_1',
            text: 'Custom',
            createdAtMs: 1,
            updatedAtMs: 1,
            origin: PhraseOrigin.custom,
          ),
        ],
        queueIds: const ['bm_0', 'ba_0', 'm_1'],
        presets: const [],
      );

      final motivators = PhrasePackQueue.migrateLegacy(
        legacy,
        PhrasePackKind.dashboardMotivator,
      );
      expect(motivators.messages.map((m) => m.id), ['bm_0', 'm_1']);
      expect(motivators.queueIds, ['bm_0', 'm_1']);

      final affirmations = PhrasePackQueue.migrateLegacy(
        legacy,
        PhrasePackKind.dailyAffirmation,
      );
      expect(affirmations.messages.map((m) => m.id), ['ba_0', 'm_1']);
      expect(affirmations.queueIds, ['ba_0', 'm_1']);
    });
  });
}
