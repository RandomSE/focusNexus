import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_engine.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_word_list.dart';

void main() {
  const playSize = Size(400, 700);

  WordBloomEngine engine({bool endless = false, int seed = 42}) {
    return WordBloomEngine(
      playSize: playSize,
      endless: endless,
      baseDifficulty: 1.0,
      random: math.Random(seed),
    );
  }

  group('WordBloomEngine duration', () {
    test('starts resting with zero score and unfinished', () {
      final e = engine();
      expect(e.score, 0);
      expect(e.isFinished, isFalse);
      expect(e.phase, WordBloomPhase.resting);
      expect(e.remainingSeconds, WordBloomConstants.durationSeconds);
      expect(e.currentWord, isNotEmpty);
      expect(e.letters, isNotEmpty);
    });

    test('finishes after exactly duration seconds', () {
      final e = engine();
      e.update(WordBloomConstants.durationSeconds.toDouble());
      expect(e.isFinished, isTrue);
      expect(e.remainingSeconds, 0);
    });

    test('tap resting word scatters letters', () {
      final e = engine(seed: 1);
      expect(e.tapAt(e.restingWordCenterForTest), isTrue);
      expect(e.phase, WordBloomPhase.scattered);
      expect(e.letters.any((l) => l.velocity != Offset.zero), isTrue);
    });

    test('shatter coasts letters into inner 80% playfield', () {
      final e = engine(seed: 5);
      e.forceWordForTest('CAPABLE');
      final center = Offset(playSize.width / 2, playSize.height * 0.42);
      e.shatterForTest();
      for (var i = 0; i < 180; i++) {
        e.update(1 / 60);
      }
      final bounds = WordBloomConstants.scatterBounds(playSize);
      final free = e.letters.where((l) => !l.collected && !l.isAutoLocked);
      expect(free, isNotEmpty);
      for (final letter in free) {
        expect(
          letter.position.dx,
          inInclusiveRange(bounds.left - 24, bounds.right + 24),
        );
        expect(
          letter.position.dy,
          inInclusiveRange(bounds.top - 24, bounds.bottom + 24),
        );
      }
      expect(
        free.any(
          (l) =>
              (l.position - center).distance >
              playSize.shortestSide * 0.15,
        ),
        isTrue,
      );
    });

    test('completing a word increments wordCollectedEventCount', () {
      final e = engine(seed: 3);
      e.forceWordForTest('REAL');
      e.shatterForTest();
      final before = e.wordCollectedEventCount;
      for (final letter in List<WordBloomLetter>.from(
        e.letters.where((l) => !l.collected),
      )) {
        expect(e.tapAt(letter.position), isTrue);
      }
      e.completeCollectsForTest();
      expect(e.wordCollectedEventCount, before + 1);
      expect(e.phase, WordBloomPhase.blooming);
      expect(e.wordsCompleted, 1);
    });

    test('SHOW UP auto-locks space slot', () {
      final e = engine(seed: 99);
      e.forceWordForTest('SHOW UP');
      expect(e.currentWord, 'SHOW UP');
      final spaces = e.letters.where((l) => l.char == ' ').toList();
      expect(spaces, hasLength(1));
      expect(spaces.single.isAutoLocked, isTrue);
      expect(spaces.single.collected, isTrue);
    });

    test('collecting word in order scores letter points bloom and streak', () {
      final e = engine(seed: 3);
      e.forceWordForTest('REAL');
      e.shatterForTest();
      expect(e.phase, WordBloomPhase.scattered);
      // Tap left-to-right by slot index for perfect order.
      final ordered = List<WordBloomLetter>.from(e.letters)
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      for (final letter in ordered.where((l) => !l.isAutoLocked)) {
        expect(e.tapAt(letter.position), isTrue);
      }
      e.completeCollectsForTest();
      // REAL: 4*2 letter + 5 bloom + 1 streak = 14
      expect(e.score, 14);
      expect(e.wordsCompleted, 1);
      expect(e.orderStreak, 1);
      expect(e.bestOrderStreak, 1);
      expect(e.wordInOrder, isTrue);
      expect(e.phase, WordBloomPhase.blooming);
      expect(e.wordCollectedEventCount, 1);
    });

    test('COMMIT-like word in order scores 12 + 5 + streak', () {
      final e = engine(seed: 3);
      e.forceWordForTest('COMMIT');
      e.shatterForTest();
      final ordered = List<WordBloomLetter>.from(e.letters)
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      for (final letter in ordered.where((l) => !l.isAutoLocked)) {
        expect(e.tapAt(letter.position), isTrue);
      }
      e.completeCollectsForTest();
      expect(e.score, 12 + 5 + 1);
      expect(e.wordsCompleted, 1);
      expect(e.orderStreak, 1);
    });

    test('duplicate letter taps match by character not slot (COMMIT 2nd M first)', () {
      final e = engine(seed: 3);
      e.forceWordForTest('COMMIT');
      e.shatterForTest();
      final bySlot = {
        for (final l in e.letters) l.slotIndex: l,
      };
      // C O M(1) M(2) I T — tap second M while first M is still expected.
      expect(e.tapAt(bySlot[0]!.position), isTrue); // C
      expect(e.tapAt(bySlot[1]!.position), isTrue); // O
      final secondM = bySlot[3]!;
      final firstMPos = bySlot[2]!.slotPosition;
      expect(e.tapAt(secondM.position), isTrue); // 2nd M, in-order
      expect(e.wordInOrder, isTrue);
      expect(secondM.slotIndex, 2); // rebound to next expected slot
      expect(secondM.slotPosition, firstMPos);
      expect(e.nextOrderSlot, 3);
      expect(e.score, 6);
      // Remaining M now owns the later slot.
      final remainingM = e.letters.firstWhere((l) => l.slotIndex == 3);
      expect(e.tapAt(remainingM.position), isTrue);
      expect(e.tapAt(e.letters.firstWhere((l) => l.slotIndex == 4).position), isTrue);
      expect(e.tapAt(e.letters.firstWhere((l) => l.slotIndex == 5).position), isTrue);
      e.completeCollectsForTest();
      expect(e.wordInOrder, isTrue);
      expect(e.orderStreak, 1);
      expect(e.score, 12 + 5 + 1);
    });

    test('CENTERED last E fills next E slot so N stays in order', () {
      final e = engine(seed: 3);
      e.forceWordForTest('CENTERED');
      e.shatterForTest();
      // C E N T E R E D
      // 0 1 2 3 4 5 6 7
      final bySlot = {
        for (final l in e.letters) l.slotIndex: l,
      };
      expect(e.tapAt(bySlot[0]!.position), isTrue); // C
      final lastE = bySlot[6]!;
      final slot1Pos = bySlot[1]!.slotPosition;
      expect(e.tapAt(lastE.position), isTrue); // last E while expecting first E
      expect(e.wordInOrder, isTrue);
      expect(lastE.slotIndex, 1);
      expect(lastE.slotPosition, slot1Pos);
      expect(e.nextOrderSlot, 2);
      final n = e.letters.firstWhere((l) => l.slotIndex == 2);
      expect(e.tapAt(n.position), isTrue);
      expect(e.wordInOrder, isTrue);
      expect(e.nextOrderSlot, 3);
      expect(e.score, 2 + 2 + 2);
    });

    test('CENTERED always picking later duplicate E keeps perfect streak', () {
      final e = engine(seed: 3);
      e.forceWordForTest('CENTERED');
      e.shatterForTest();

      Offset posForSlot(int slot) =>
          e.letters.firstWhere((l) => l.slotIndex == slot).position;

      WordBloomLetter latestOpenE() {
        WordBloomLetter? best;
        for (final l in e.letters) {
          if (l.char != 'E') continue;
          if (l.collected || l.collectProgress != null) continue;
          if (best == null || l.slotIndex > best.slotIndex) best = l;
        }
        return best!;
      }

      expect(e.tapAt(posForSlot(0)), isTrue); // C
      expect(e.tapAt(latestOpenE().position), isTrue); // E -> slot 1
      expect(e.tapAt(posForSlot(2)), isTrue); // N
      expect(e.tapAt(posForSlot(3)), isTrue); // T
      expect(e.tapAt(latestOpenE().position), isTrue); // E -> slot 4
      expect(e.tapAt(posForSlot(5)), isTrue); // R
      expect(e.tapAt(latestOpenE().position), isTrue); // E -> slot 6
      expect(e.tapAt(posForSlot(7)), isTrue); // D
      expect(e.wordInOrder, isTrue);
      e.completeCollectsForTest();
      expect(e.orderStreak, 1);
      expect(e.score, 8 * 2 + 5 + 1);
    });

    test('out-of-order collect breaks wordInOrder and resets streak on bloom', () {
      final e = engine(seed: 3);
      e.forceWordForTest('REAL');
      e.shatterForTest();
      final bySlot = {
        for (final l in e.letters) l.slotIndex: l,
      };
      // Tap last letter first (out of order).
      expect(e.tapAt(bySlot[3]!.position), isTrue);
      expect(e.score, 1);
      expect(e.wordInOrder, isFalse);
      // Finish remaining in any order.
      for (final letter in e.letters.where(
        (l) => !l.isAutoLocked && l.collectProgress == null && !l.collected,
      )) {
        expect(e.tapAt(letter.position), isTrue);
      }
      e.completeCollectsForTest();
      // 1 + 2+2+2 letter mix depending on nextOrder recovery, then +5, streak 0
      expect(e.wordsCompleted, 1);
      expect(e.orderStreak, 0);
      expect(e.bestOrderStreak, 0);
      expect(e.score, greaterThanOrEqualTo(1 + 3 + 5));
      expect(e.wordCollectedEventCount, 1);
    });

    test('broken order resets live streak to 0 but keeps bestOrderStreak', () {
      final e = engine(seed: 4);
      e.forceWordForTest('REAL');
      e.shatterForTest();
      for (var slot = 0; slot < 4; slot++) {
        final letter = e.letters.firstWhere((l) => l.slotIndex == slot);
        expect(e.tapAt(letter.position), isTrue);
      }
      expect(e.wordInOrder, isTrue);
      e.completeCollectsForTest();
      expect(e.orderStreak, 1);
      expect(e.bestOrderStreak, 1);

      e.forceWordForTest('BOLD');
      e.shatterForTest();
      final bySlot = {
        for (final l in e.letters) l.slotIndex: l,
      };
      expect(e.tapAt(bySlot[3]!.position), isTrue);
      expect(e.wordInOrder, isFalse);
      for (final letter in e.letters.where(
        (l) => !l.isAutoLocked && l.collectProgress == null && !l.collected,
      )) {
        expect(e.tapAt(letter.position), isTrue);
      }
      e.completeCollectsForTest();
      expect(e.orderStreak, 0);
      expect(e.bestOrderStreak, 1);
    });

    test('setLetterLayoutSize reseats slots without resetting score', () {
      final e = engine(seed: 3);
      e.forceWordForTest('REAL');
      e.shatterForTest();
      e.score = 7;
      e.wordsCompleted = 2;
      e.orderStreak = 1;
      final beforePhase = e.phase;
      final beforePositions =
          e.letters.map((l) => l.slotPosition).toList(growable: false);
      e.setLetterLayoutSize(20);
      expect(e.score, 7);
      expect(e.wordsCompleted, 2);
      expect(e.orderStreak, 1);
      expect(e.phase, beforePhase);
      expect(e.letterLayoutSize, 20);
      // Slot spacing should change with layout size.
      final after = e.letters.map((l) => l.slotPosition).toList();
      expect(after.length, beforePositions.length);
      expect(
        after.any((p) => !beforePositions.contains(p)),
        isTrue,
      );
    });

    test('setLetterLayoutSize clamps above maxLetterLayoutSize', () {
      final e = engine(seed: 3);
      e.setLetterLayoutSize(99);
      expect(e.letterLayoutSize, WordBloomConstants.maxLetterLayoutSize);
    });

    test('letterLayoutSizeForSettingsFont caps font size 24', () {
      expect(
        WordBloomConstants.letterLayoutSizeForSettingsFont(24),
        WordBloomConstants.maxLetterLayoutSize,
      );
      expect(
        WordBloomConstants.letterLayoutSizeForSettingsFont(14),
        closeTo(22.4, 0.001),
      );
    });
    test('duration length band ramps by ordinal', () {
      expect(WordBloomConstants.lengthBandForOrdinal(1), (4, 5));
      expect(WordBloomConstants.lengthBandForOrdinal(4), (6, 7));
      expect(WordBloomConstants.lengthBandForOrdinal(7), (7, 9));
      expect(WordBloomConstants.scatterMaxForOrdinal(2), 300);
      expect(WordBloomConstants.scatterMaxForOrdinal(5), 380);
      expect(WordBloomConstants.scatterMaxForOrdinal(8), 500);
    });

    test('first words use length band 4-5', () {
      final e = engine(seed: 7);
      final n = WordBloomWordList.letterCount(e.currentWord);
      expect(n, inInclusiveRange(4, 5));
    });

    test('no fail state during duration play', () {
      final e = engine(seed: 2);
      e.shatterForTest();
      e.update(1.0);
      expect(e.isFinished, isFalse);
      e.endRound();
      expect(e.isFinished, isTrue);
    });

    test('velocity decays with pow(0.88, dt*60)', () {
      final e = engine(seed: 5);
      e.shatterForTest();
      final letter = e.letters.firstWhere((l) => !l.collected);
      letter.velocity = const Offset(100, 0);
      e.update(1 / 60);
      expect(letter.velocity.dx, closeTo(100 * 0.88, 0.01));
    });

    test('edge bounce retains 0.70 of speed', () {
      final e = engine(seed: 5);
      e.shatterForTest();
      final letter = e.letters.firstWhere((l) => !l.collected);
      letter.position = const Offset(5, 100);
      letter.velocity = const Offset(-80, 0);
      e.update(1 / 60);
      expect(letter.velocity.dx, greaterThan(0));
      expect(letter.velocity.dx, closeTo(80 * 0.70 * 0.88, 1.0));
    });
  });

  group('WordBloomEngine endless', () {
    test('does not auto-finish at 90s', () {
      final e = engine(endless: true, seed: 11);
      e.update(90);
      expect(e.isFinished, isFalse);
      expect(e.elapsedSeconds, closeTo(90, 0.01));
    });

    test('after 90s uses endless late pool lengths 9-14', () {
      final e = engine(endless: true, seed: 13);
      e.update(90.1);
      e.forceNextWordFromPoolForTest();
      final n = WordBloomWordList.letterCount(e.currentWord);
      expect(n, inInclusiveRange(9, 14));
    });

    test('after 90s shatter lands letters across the playfield with faster coast', () {
      final e = engine(endless: true, seed: 17);
      e.update(91);
      e.forceWordForTest('UNFINISHED');
      final center = Offset(playSize.width / 2, playSize.height * 0.42);
      e.shatterForTest();
      final speeds = e.letters
          .where((l) => !l.collected)
          .map((l) => l.velocity.distance)
          .toList();
      expect(speeds, isNotEmpty);
      expect(speeds.any((s) => s > WordBloomConstants.scatterMinSpeed), isTrue);
      // Coast briefly before endless edge-drift dominates.
      for (var i = 0; i < 45; i++) {
        e.update(1 / 60);
      }
      final free = e.letters.where((l) => !l.collected);
      expect(
        free.any(
          (l) =>
              (l.position - center).distance >
              playSize.shortestSide * 0.15,
        ),
        isTrue,
      );
      for (final letter in free) {
        expect(letter.position.dx, inInclusiveRange(0, playSize.width));
        expect(letter.position.dy, inInclusiveRange(0, playSize.height));
      }
    });

    test('gold letter first tap emits bonus particles without gold score bonus', () {
      final e = engine(endless: true, seed: 19);
      e.update(91);
      e.forceWordForTest('UNBOUNDED');
      e.shatterForTest();
      e.markOneLetterGoldForTest();
      final gold = e.letters.firstWhere((l) => l.isGold);
      final scoreBefore = e.score;
      final particlesBefore = e.particles.length;
      expect(e.tapAt(gold.position), isTrue);
      e.completeCollectsForTest();
      // Letter collect still awards 1 or 2 points; gold FX adds no extra score.
      expect(e.score, anyOf(scoreBefore + 1, scoreBefore + 2));
      expect(
        e.particles.length,
        greaterThanOrEqualTo(
          particlesBefore + WordBloomConstants.goldBonusParticleCount,
        ),
      );
      expect(gold.collected, isTrue);
    });

    test('near-stop letters get edge drift after 90s', () {
      final e = engine(endless: true, seed: 23);
      e.update(91);
      e.shatterForTest();
      final letter = e.letters.firstWhere((l) => !l.collected);
      letter.position = Offset(playSize.width / 2, playSize.height / 2);
      letter.velocity = Offset.zero;
      final x0 = letter.position.dx;
      e.update(1.0);
      expect((letter.position.dx - x0).abs(), greaterThan(1));
    });

    test('endRound finishes endless', () {
      final e = engine(endless: true);
      e.endRound();
      expect(e.isFinished, isTrue);
    });

    test('collectEventCount increments on letter collect for SFX', () {
      final e = engine(seed: 29);
      e.forceWordForTest('HOPE');
      e.shatterForTest();
      final before = e.collectEventCount;
      final letter = e.letters.firstWhere((l) => !l.collected);
      e.tapAt(letter.position);
      expect(e.collectEventCount, before + 1);
    });
  });

  group('WordBloomWordList', () {
    test('SHOW UP letter count excludes space', () {
      expect(WordBloomWordList.letterCount('SHOW UP'), 6);
    });

    test('UNFINISHED is endless-only', () {
      expect(WordBloomWordList.standard.contains('UNFINISHED'), isFalse);
      expect(WordBloomWordList.endless.contains('UNFINISHED'), isTrue);
    });
  });
}
