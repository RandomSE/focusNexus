import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_word_list.dart';

enum WordBloomPhase { resting, scattered, blooming, transitioning }

/// One glyph in the current word (spaces may be auto-locked).
class WordBloomLetter {
  WordBloomLetter({
    required this.char,
    required this.slotIndex,
    required this.slotPosition,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.angularVelocity,
    required this.accentIndex,
    this.isGold = false,
    this.isAutoLocked = false,
    this.collected = false,
  });

  final String char;
  int slotIndex;
  Offset slotPosition;
  Offset position;
  Offset velocity;
  double rotation;
  double angularVelocity;
  final int accentIndex;
  bool isGold;
  final bool isAutoLocked;
  bool collected;

  /// 0..1 while arcing into the slot; null when not collecting.
  double? collectProgress;
  Offset? collectFrom;
  bool goldBonusEmitted = false;

  /// Slot pop after landing.
  double popProgress = 0;
}

/// Soft particle for collect / bloom / gold FX.
class WordBloomParticle {
  WordBloomParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.bornAt,
    this.life = 0.55,
    this.radius = 3,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double bornAt;
  final double life;
  final double radius;

  double age(double now) => now - bornAt;
  bool isDone(double now) => age(now) >= life;
}

/// Pure playfield simulation for Word Bloom.
class WordBloomEngine extends ChangeNotifier {
  WordBloomEngine({
    required this.playSize,
    required this.endless,
    this.baseDifficulty = WordBloomConstants.baseDifficulty,
    this.letterLayoutSize = WordBloomConstants.defaultLetterLayoutSize,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    _pickAndSeatWord();
    _syncHudBaseline();
  }

  Size playSize;
  final bool endless;
  final double baseDifficulty;
  final math.Random _random;

  /// Glyph layout size used for slot spacing and hit radii (synced from UI font).
  double letterLayoutSize;

  final List<WordBloomLetter> letters = <WordBloomLetter>[];
  final List<WordBloomParticle> particles = <WordBloomParticle>[];
  final List<String> _recentWords = <String>[];

  WordBloomPhase phase = WordBloomPhase.resting;
  String currentWord = '';
  int wordOrdinal = 1;

  /// Points earned this round (letter taps + bloom bonuses + order streaks).
  int score = 0;

  /// Words fully bloomed this round (achievement / word-count tracking).
  int wordsCompleted = 0;

  /// Consecutive perfect-order words; resets on an out-of-order word.
  int orderStreak = 0;

  /// Peak [orderStreak] this round.
  int bestOrderStreak = 0;

  /// Whether the current word is still being collected in left-to-right order.
  bool wordInOrder = true;

  /// Next non-space slot index expected for perfect-order bonus.
  int nextOrderSlot = 0;

  bool isFinished = false;
  double elapsedSeconds = 0;
  double phaseAge = 0;
  double bloomScale = 1;
  int collectEventCount = 0;

  /// Monotonic count of completed words (for word-collected SFX polling).
  int wordCollectedEventCount = 0;
  Color wordAccent = WordBloomConstants.accentPalette.first;

  /// Increments when HUD-visible fields change (score, streak, timer, phase, finished).
  final ValueNotifier<int> hudRevision = ValueNotifier<int>(0);

  int _hudScore = 0;
  int _hudStreak = 0;
  int _hudTimerKey = -1;
  bool _hudFinished = false;
  WordBloomPhase? _hudPhase;

  @override
  void dispose() {
    hudRevision.dispose();
    super.dispose();
  }

  int get _timerHudKey =>
      endless ? elapsedSeconds.floor() : remainingSeconds;

  void _syncHudBaseline() {
    _hudScore = score;
    _hudStreak = orderStreak;
    _hudTimerKey = _timerHudKey;
    _hudFinished = isFinished;
    _hudPhase = phase;
  }

  void _notifyFrame() {
    notifyListeners();
    if (score != _hudScore ||
        orderStreak != _hudStreak ||
        _timerHudKey != _hudTimerKey ||
        isFinished != _hudFinished ||
        phase != _hudPhase) {
      _syncHudBaseline();
      hudRevision.value++;
    }
  }

  double get letterHitRadius {
    final scale =
        letterLayoutSize / WordBloomConstants.defaultLetterLayoutSize;
    return WordBloomConstants.letterHitRadius * (0.85 + 0.15 * scale);
  }

  double get wordHitPadding {
    final scale =
        letterLayoutSize / WordBloomConstants.defaultLetterLayoutSize;
    return WordBloomConstants.wordHitPadding * scale;
  }

  /// Trail samples for scattered letters (painter).
  final Map<int, List<Offset>> letterTrails = <int, List<Offset>>{};

  int get remainingSeconds {
    if (endless) return 0;
    final left = WordBloomConstants.durationSeconds - elapsedSeconds;
    return left <= 0 ? 0 : left.ceil();
  }

  bool get isLateEndless => endless && elapsedSeconds >= 90;

  double get breathPulse {
    return 0.92 + 0.08 * math.sin(elapsedSeconds * 2.2);
  }

  void update(double dt) {
    if (dt <= 0) return;
    if (isFinished) {
      elapsedSeconds += dt;
      _ageParticles(dt);
      _notifyFrame();
      return;
    }

    final step = dt > 0.1 ? 0.1 : dt;
    var remaining = dt;
    while (remaining > 0 && !isFinished) {
      final slice = remaining > step ? step : remaining;
      remaining -= slice;
      _tick(slice);
    }
    _notifyFrame();
  }

  void _tick(double dt) {
    elapsedSeconds += dt;
    phaseAge += dt;
    _ageParticles(dt);

    if (!endless && elapsedSeconds >= WordBloomConstants.durationSeconds) {
      isFinished = true;
      elapsedSeconds = WordBloomConstants.durationSeconds.toDouble();
      return;
    }

    switch (phase) {
      case WordBloomPhase.resting:
        break;
      case WordBloomPhase.scattered:
        _integrateScattered(dt);
        if (_allCollectibleCollected()) {
          _beginBloom();
        }
      case WordBloomPhase.blooming:
        _tickBloom();
      case WordBloomPhase.transitioning:
        if (phaseAge >= WordBloomConstants.transitionSeconds) {
          wordOrdinal += 1;
          _pickAndSeatWord();
          phase = WordBloomPhase.resting;
          phaseAge = 0;
          bloomScale = 1;
        }
    }
  }

  /// Returns true when the tap interacted with the playfield.
  bool tapAt(Offset point) {
    if (isFinished) return false;
    final bool handled;
    switch (phase) {
      case WordBloomPhase.resting:
        if (_hitRestingWord(point)) {
          _shatter();
          handled = true;
        } else {
          handled = false;
        }
      case WordBloomPhase.scattered:
        handled = _tryCollectLetter(point);
      case WordBloomPhase.blooming:
      case WordBloomPhase.transitioning:
        handled = false;
    }
    if (handled) _notifyFrame();
    return handled;
  }

  void endRound() {
    isFinished = true;
    _notifyFrame();
  }

  /// Syncs glyph layout size from UI settings without resetting round state.
  /// Clamped so large Accessibility fonts cannot overflow Impeller atlases.
  void setLetterLayoutSize(double size) {
    final next = size
        .clamp(18.0, WordBloomConstants.maxLetterLayoutSize)
        .toDouble();
    if ((letterLayoutSize - next).abs() < 0.01) return;
    letterLayoutSize = next;
    reseatCurrentWordSlots();
    _notifyFrame();
  }

  /// Recomputes slot positions for [currentWord]; keeps phase/score/letters state.
  void reseatCurrentWordSlots() {
    if (letters.isEmpty || currentWord.isEmpty) return;
    final center = Offset(playSize.width / 2, playSize.height * 0.42);
    final slotSpacing = _slotSpacing(currentWord);
    final totalWidth = slotSpacing * (currentWord.length - 1);
    final startX = center.dx - totalWidth / 2;
    final syncPosition =
        phase == WordBloomPhase.resting || phase == WordBloomPhase.blooming;

    for (final letter in letters) {
      final slot = Offset(
        startX + letter.slotIndex * slotSpacing,
        center.dy,
      );
      letter.slotPosition = slot;
      if (syncPosition) {
        letter.position = slot;
      }
    }
  }

  // --- Test hooks ---

  @visibleForTesting
  void forceWordForTest(String word) {
    currentWord = word;
    _seatWord(word);
    phase = WordBloomPhase.resting;
    phaseAge = 0;
    bloomScale = 1;
  }

  @visibleForTesting
  void shatterForTest() => _shatter();

  @visibleForTesting
  void markOneLetterGoldForTest() {
    final candidates = letters.where((l) => !l.isAutoLocked).toList();
    if (candidates.isEmpty) return;
    for (final l in letters) {
      l.isGold = false;
    }
    candidates.first.isGold = true;
  }

  @visibleForTesting
  void forceNextWordFromPoolForTest() {
    wordOrdinal = math.max(wordOrdinal, 10);
    _pickAndSeatWord();
    phase = WordBloomPhase.resting;
    phaseAge = 0;
  }

  @visibleForTesting
  Offset get restingWordCenterForTest {
    if (letters.isEmpty) {
      return Offset(playSize.width / 2, playSize.height * 0.42);
    }
    var sx = 0.0;
    var sy = 0.0;
    for (final l in letters) {
      sx += l.slotPosition.dx;
      sy += l.slotPosition.dy;
    }
    return Offset(sx / letters.length, sy / letters.length);
  }

  /// Completes in-flight collect arcs immediately (tests).
  @visibleForTesting
  void completeCollectsForTest() {
    for (final letter in letters) {
      if (letter.collectProgress != null) {
        letter.collectProgress = null;
        letter.collected = true;
        letter.position = letter.slotPosition;
        letter.rotation = 0;
        letter.popProgress = 0.001;
      }
    }
    if (phase == WordBloomPhase.scattered && _allCollectibleCollected()) {
      _beginBloom();
    }
  }

  // --- Internals ---

  void _pickAndSeatWord() {
    final word = _chooseWord();
    currentWord = word;
    _seatWord(word);
  }

  String _chooseWord() {
    List<String> pool;
    if (isLateEndless) {
      pool = WordBloomWordList.endlessLatePool().toList();
    } else {
      final band = WordBloomConstants.lengthBandForOrdinal(wordOrdinal);
      pool = WordBloomWordList.standardInLengthBand(band.$1, band.$2).toList();
      if (pool.isEmpty) {
        pool = WordBloomWordList.standard
            .where((w) => WordBloomWordList.letterCount(w) >= 4)
            .toList();
      }
    }
    pool.removeWhere(_recentWords.contains);
    if (pool.isEmpty) {
      pool = isLateEndless
          ? WordBloomWordList.endlessLatePool().toList()
          : WordBloomWordList.standardInLengthBand(
              WordBloomConstants.lengthBandForOrdinal(wordOrdinal).$1,
              WordBloomConstants.lengthBandForOrdinal(wordOrdinal).$2,
            ).toList();
      if (pool.isEmpty) {
        pool = WordBloomWordList.standard
            .where((w) => WordBloomWordList.letterCount(w) >= 4)
            .toList();
      }
      // Soft no-repeat: still exclude the immediately previous word.
      if (_recentWords.isNotEmpty) {
        final last = _recentWords.last;
        final withoutLast = pool.where((w) => w != last).toList();
        if (withoutLast.isNotEmpty) pool = withoutLast;
      }
    }
    final word = pool[_random.nextInt(pool.length)];
    _recentWords.add(word);
    if (_recentWords.length > 8) {
      _recentWords.removeAt(0);
    }
    return word;
  }

  void _seatWord(String word) {
    letters.clear();
    letterTrails.clear();
    final accent =
        WordBloomConstants.accentPalette[wordOrdinal %
            WordBloomConstants.accentPalette.length];
    wordAccent = accent;
    wordInOrder = true;
    final center = Offset(playSize.width / 2, playSize.height * 0.42);
    final slotSpacing = _slotSpacing(word);
    final totalWidth = slotSpacing * (word.length - 1);
    final startX = center.dx - totalWidth / 2;

    for (var i = 0; i < word.length; i++) {
      final ch = word[i];
      final slot = Offset(startX + i * slotSpacing, center.dy);
      final isSpace = ch == ' ';
      letters.add(
        WordBloomLetter(
          char: ch,
          slotIndex: i,
          slotPosition: slot,
          position: slot,
          velocity: Offset.zero,
          rotation: 0,
          angularVelocity: 0,
          accentIndex:
              (wordOrdinal + i) % WordBloomConstants.accentPalette.length,
          isAutoLocked: isSpace,
          collected: isSpace,
        ),
      );
    }
    nextOrderSlot = _earliestMissingOrderSlot();
  }

  double _slotSpacing(String word) {
    final base = playSize.width / (word.length + 2);
    final scale =
        letterLayoutSize / WordBloomConstants.defaultLetterLayoutSize;
    final min = 28.0 * scale;
    final max = 48.0 * scale;
    return base.clamp(min, max);
  }

  bool _hitRestingWord(Offset point) {
    if (letters.isEmpty) return false;
    var minX = letters.first.slotPosition.dx;
    var maxX = minX;
    var minY = letters.first.slotPosition.dy;
    var maxY = minY;
    for (final l in letters) {
      minX = math.min(minX, l.slotPosition.dx);
      maxX = math.max(maxX, l.slotPosition.dx);
      minY = math.min(minY, l.slotPosition.dy);
      maxY = math.max(maxY, l.slotPosition.dy);
    }
    final pad = wordHitPadding;
    final rect = Rect.fromLTRB(
      minX - pad,
      minY - pad,
      maxX + pad,
      maxY + pad,
    );
    return rect.contains(point);
  }

  void _shatter() {
    phase = WordBloomPhase.scattered;
    phaseAge = 0;
    wordInOrder = true;
    nextOrderSlot = _earliestMissingOrderSlot();
    final bounds = WordBloomConstants.scatterBounds(playSize);
    final shortAxis = math.min(playSize.width, playSize.height);
    final minTravel = shortAxis * WordBloomConstants.scatterMinTravelFraction;
    final minSep = shortAxis * WordBloomConstants.scatterTargetSeparationFraction;
    final placed = <Offset>[];

    for (final letter in letters) {
      if (letter.isAutoLocked) continue;
      letter.collected = false;
      letter.collectProgress = null;
      letter.popProgress = 0;
      letter.goldBonusEmitted = false;
      letter.isGold = false;
      letter.position = letter.slotPosition;

      final target = _pickScatterTarget(
        bounds: bounds,
        from: letter.slotPosition,
        placed: placed,
        minTravel: minTravel,
        minSeparation: minSep,
      );
      placed.add(target);

      final delta = target - letter.slotPosition;
      final distance = delta.distance;
      final dir = distance < 1e-6
          ? Offset(
              math.cos(_random.nextDouble() * math.pi * 2),
              math.sin(_random.nextDouble() * math.pi * 2),
            )
          : Offset(delta.dx / distance, delta.dy / distance);
      final travel = math.max(distance, minTravel);
      var speed = WordBloomConstants.coastSpeedForDistance(travel);
      if (isLateEndless) {
        speed *= WordBloomConstants.endlessScatterMultiplier;
      }
      letter.velocity = Offset(dir.dx * speed, dir.dy * speed);
      letter.angularVelocity =
          WordBloomConstants.angularSpeedMin +
          _random.nextDouble() *
              (WordBloomConstants.angularSpeedMax -
                  WordBloomConstants.angularSpeedMin);
      if (_random.nextBool()) letter.angularVelocity *= -1;
    }

    if (isLateEndless) {
      final candidates = letters.where((l) => !l.isAutoLocked).toList();
      for (final l in candidates) {
        l.isGold = false;
      }
      if (candidates.isNotEmpty) {
        candidates[_random.nextInt(candidates.length)].isGold = true;
      }
    }
  }

  Offset _pickScatterTarget({
    required Rect bounds,
    required Offset from,
    required List<Offset> placed,
    required double minTravel,
    required double minSeparation,
  }) {
    Offset best = Offset(
      bounds.left + _random.nextDouble() * bounds.width,
      bounds.top + _random.nextDouble() * bounds.height,
    );
    var bestScore = -1.0;
    for (var attempt = 0; attempt < 24; attempt++) {
      final candidate = Offset(
        bounds.left + _random.nextDouble() * bounds.width,
        bounds.top + _random.nextDouble() * bounds.height,
      );
      final travel = (candidate - from).distance;
      if (travel < minTravel) continue;
      var nearest = double.infinity;
      for (final other in placed) {
        nearest = math.min(nearest, (candidate - other).distance);
      }
      if (placed.isNotEmpty && nearest < minSeparation) continue;
      final score = travel + (nearest.isFinite ? nearest * 0.35 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    // Guarantee min travel even if random picks clustered near center.
    if ((best - from).distance < minTravel) {
      final angle = _random.nextDouble() * math.pi * 2;
      var pushed = from + Offset(math.cos(angle), math.sin(angle)) * minTravel;
      pushed = Offset(
        pushed.dx.clamp(bounds.left, bounds.right),
        pushed.dy.clamp(bounds.top, bounds.bottom),
      );
      return pushed;
    }
    return best;
  }

  bool _tryCollectLetter(Offset point) {
    WordBloomLetter? hit;
    var bestDist = letterHitRadius;
    for (final letter in letters) {
      if (letter.collected || letter.isAutoLocked) continue;
      if (letter.collectProgress != null) continue;
      final d = (letter.position - point).distance;
      if (d <= bestDist) {
        bestDist = d;
        hit = letter;
      }
    }
    if (hit == null) return false;
    _startCollect(hit);
    return true;
  }

  void _startCollect(WordBloomLetter letter) {
    collectEventCount += 1;

    // Same character as the next needed slot is always in-order (E is E).
    // Rebind the tapped glyph onto that slot so it arcs into the correct outline
    // and advances nextOrderSlot past it (otherwise CENTERED's last E leaves
    // slot 1 open and the following N falsely breaks the streak).
    final expectedChar = _charAtOrderSlot(nextOrderSlot);
    final inOrder = expectedChar != null && letter.char == expectedChar;
    if (inOrder) {
      _rebindLetterToSlot(letter, nextOrderSlot);
      score += 2;
    } else {
      score += 1;
      wordInOrder = false;
    }

    letter.collectFrom = letter.position;
    letter.collectProgress = 0;
    letter.velocity = Offset.zero;
    nextOrderSlot = _earliestMissingOrderSlot();

    if (letter.isGold && !letter.goldBonusEmitted) {
      letter.goldBonusEmitted = true;
      _emitBurst(
        letter.position,
        WordBloomConstants.goldAccent,
        WordBloomConstants.goldBonusParticleCount,
      );
    } else {
      _emitBurst(
        letter.position,
        WordBloomConstants.accentPalette[letter.accentIndex],
        WordBloomConstants.collectParticleCount,
      );
    }
  }

  /// Moves [letter] onto [targetSlot], swapping with the prior occupant.
  void _rebindLetterToSlot(WordBloomLetter letter, int targetSlot) {
    if (letter.slotIndex == targetSlot) return;
    WordBloomLetter? occupant;
    for (final other in letters) {
      if (other.slotIndex == targetSlot) {
        occupant = other;
        break;
      }
    }
    if (occupant == null || identical(occupant, letter)) return;

    final fromSlot = letter.slotIndex;
    final fromPos = letter.slotPosition;
    final fromTrail = letterTrails.remove(fromSlot);
    final toTrail = letterTrails.remove(targetSlot);

    letter.slotIndex = targetSlot;
    letter.slotPosition = occupant.slotPosition;
    occupant.slotIndex = fromSlot;
    occupant.slotPosition = fromPos;

    if (fromTrail != null) {
      letterTrails[targetSlot] = fromTrail;
    }
    if (toTrail != null) {
      letterTrails[fromSlot] = toTrail;
    }
  }

  String? _charAtOrderSlot(int slotIndex) {
    for (final letter in letters) {
      if (letter.slotIndex == slotIndex) return letter.char;
    }
    return null;
  }

  /// Earliest non-space slot not yet collected or collecting.
  int _earliestMissingOrderSlot() => _firstMissingOrderSlot(after: -1);

  /// Lowest non-space slot after [after] that is not collected or collecting.
  int _firstMissingOrderSlot({required int after}) {
    int? best;
    for (final letter in letters) {
      if (letter.slotIndex <= after) continue;
      if (letter.isAutoLocked || letter.char == ' ') continue;
      if (letter.collected || letter.collectProgress != null) continue;
      if (best == null || letter.slotIndex < best) {
        best = letter.slotIndex;
      }
    }
    return best ?? (letters.isEmpty ? 0 : letters.length);
  }

  void _integrateScattered(double dt) {
    final decay = math.pow(
      WordBloomConstants.velocityDecayPerFrame,
      dt * 60,
    ).toDouble();
    final margin = 18.0;

    for (final letter in letters) {
      if (letter.collected || letter.isAutoLocked) continue;

      final progress = letter.collectProgress;
      if (progress != null) {
        final next = progress + dt / WordBloomConstants.collectArcSeconds;
        if (next >= 1) {
          letter.collectProgress = null;
          letter.collected = true;
          letter.position = letter.slotPosition;
          letter.rotation = 0;
          letter.popProgress = 0.001;
          letterTrails.remove(letter.slotIndex);
        } else {
          letter.collectProgress = next;
          final from = letter.collectFrom ?? letter.position;
          final t = next;
          final lift = WordBloomConstants.collectArcLiftPx * 4 * t * (1 - t);
          letter.position = Offset(
            from.dx + (letter.slotPosition.dx - from.dx) * t,
            from.dy + (letter.slotPosition.dy - from.dy) * t - lift,
          );
        }
        continue;
      }

      if (letter.popProgress > 0 && letter.popProgress < 1) {
        letter.popProgress =
            (letter.popProgress + dt / WordBloomConstants.collectPopSeconds)
                .clamp(0.0, 1.0);
      }

      letter.velocity *= decay;
      letter.position += letter.velocity * dt;
      letter.rotation += letter.angularVelocity * dt;

      // Bounce
      if (letter.position.dx < margin) {
        letter.position = Offset(margin, letter.position.dy);
        letter.velocity = Offset(
          letter.velocity.dx.abs() * WordBloomConstants.edgeBounceRetain,
          letter.velocity.dy * WordBloomConstants.edgeBounceRetain,
        );
      } else if (letter.position.dx > playSize.width - margin) {
        letter.position = Offset(playSize.width - margin, letter.position.dy);
        letter.velocity = Offset(
          -letter.velocity.dx.abs() * WordBloomConstants.edgeBounceRetain,
          letter.velocity.dy * WordBloomConstants.edgeBounceRetain,
        );
      }
      if (letter.position.dy < margin) {
        letter.position = Offset(letter.position.dx, margin);
        letter.velocity = Offset(
          letter.velocity.dx * WordBloomConstants.edgeBounceRetain,
          letter.velocity.dy.abs() * WordBloomConstants.edgeBounceRetain,
        );
      } else if (letter.position.dy > playSize.height - margin) {
        letter.position = Offset(letter.position.dx, playSize.height - margin);
        letter.velocity = Offset(
          letter.velocity.dx * WordBloomConstants.edgeBounceRetain,
          -letter.velocity.dy.abs() * WordBloomConstants.edgeBounceRetain,
        );
      }

      final speed = letter.velocity.distance;
      if (speed < WordBloomConstants.nearStopSpeed) {
        if (isLateEndless) {
          _applyEdgeDrift(letter, dt);
        } else {
          letter.position += Offset(
            (_random.nextDouble() - 0.5) * 2 * WordBloomConstants.durationRandomWalkPx,
            (_random.nextDouble() - 0.5) * 2 * WordBloomConstants.durationRandomWalkPx,
          );
        }
      }

      final trail = letterTrails.putIfAbsent(letter.slotIndex, () => <Offset>[]);
      trail.add(letter.position);
      if (trail.length > 10) trail.removeAt(0);
    }

    // Advance pop on already collected letters.
    for (final letter in letters) {
      if (!letter.collected || letter.isAutoLocked) continue;
      if (letter.popProgress > 0 && letter.popProgress < 1) {
        letter.popProgress =
            (letter.popProgress + dt / WordBloomConstants.collectPopSeconds)
                .clamp(0.0, 1.0);
      } else if (letter.popProgress == 0 && letter.collected) {
        // freshly auto-locked: leave at 0
      }
    }
  }

  void _applyEdgeDrift(WordBloomLetter letter, double dt) {
    final cx = playSize.width / 2;
    final cy = playSize.height / 2;
    final dxEdge = letter.position.dx < cx
        ? -WordBloomConstants.endlessEdgeDriftPxPerSec
        : WordBloomConstants.endlessEdgeDriftPxPerSec;
    final dyEdge = letter.position.dy < cy
        ? -WordBloomConstants.endlessEdgeDriftPxPerSec
        : WordBloomConstants.endlessEdgeDriftPxPerSec;
    // Drift toward nearer edge axis.
    final toLeft = letter.position.dx;
    final toRight = playSize.width - letter.position.dx;
    final toTop = letter.position.dy;
    final toBottom = playSize.height - letter.position.dy;
    final minH = math.min(toLeft, toRight);
    final minV = math.min(toTop, toBottom);
    if (minH <= minV) {
      letter.position = Offset(
        letter.position.dx + dxEdge * dt,
        letter.position.dy,
      );
    } else {
      letter.position = Offset(
        letter.position.dx,
        letter.position.dy + dyEdge * dt,
      );
    }
  }

  bool _allCollectibleCollected() {
    return letters.every((l) => l.collected || l.isAutoLocked);
  }

  void _beginBloom() {
    wordsCompleted += 1;
    score += 5;
    if (wordInOrder) {
      orderStreak += 1;
      if (orderStreak > bestOrderStreak) {
        bestOrderStreak = orderStreak;
      }
      score += orderStreak;
    } else {
      orderStreak = 0;
    }
    wordCollectedEventCount += 1;
    phase = WordBloomPhase.blooming;
    phaseAge = 0;
    bloomScale = 1;
    _emitBurst(
      Offset(playSize.width / 2, playSize.height * 0.42),
      wordAccent,
      WordBloomConstants.completeParticleCount,
    );
  }

  void _tickBloom() {
    final scaleT =
        (phaseAge / WordBloomConstants.bloomScaleSeconds).clamp(0.0, 1.0);
    if (phaseAge <= WordBloomConstants.bloomScaleSeconds) {
      bloomScale =
          1 + (WordBloomConstants.bloomScalePeak - 1) * math.sin(scaleT * math.pi);
    } else {
      bloomScale = 1;
    }
    final holdEnd =
        WordBloomConstants.bloomScaleSeconds + WordBloomConstants.bloomHoldSeconds;
    if (phaseAge >= holdEnd) {
      phase = WordBloomPhase.transitioning;
      phaseAge = 0;
    }
  }

  void _emitBurst(Offset origin, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 40 + _random.nextDouble() * 120;
      particles.add(
        WordBloomParticle(
          position: origin,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: color,
          bornAt: elapsedSeconds,
          radius: 2 + _random.nextDouble() * 3,
        ),
      );
    }
  }

  void _ageParticles(double dt) {
    for (final p in particles) {
      p.position += p.velocity * dt;
      p.velocity *= math.pow(0.92, dt * 60).toDouble();
    }
    particles.removeWhere((p) => p.isDone(elapsedSeconds));
  }
}
