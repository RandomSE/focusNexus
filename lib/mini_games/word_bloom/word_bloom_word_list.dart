/// Affirmation word pools for Word Bloom.
abstract final class WordBloomWordList {
  /// Duration and early Endless pool (letter length measured without spaces).
  /// Single tokens only - spaces are supported by the engine as auto-locked
  /// gaps, but this pool stays single-word so scatter length bands stay honest.
  static const List<String> standard = <String>[
    'BRAVE',
    'VALID',
    'ENOUGH',
    'WORTHY',
    'CAPABLE',
    'PRESENT',
    'FOCUSED',
    'REAL',
    'SEEN',
    'WHOLE',
    'STRONG',
    'CREATIVE',
    'UNIQUE',
    'GIFTED',
    'BEGIN',
    'BUILD',
    'RISE',
    'MOVE',
    'START',
    'PUSH',
    'GROW',
    'REACH',
    'PERSIST',
    'CREATE',
    'FINISH',
    'COMMIT',
    'CALM',
    'CLEAR',
    'GROUNDED',
    'STEADY',
    'CENTERED',
    'STILL',
    'OPEN',
    'READY',
    'AWAKE',
    'ALIVE',
    'WIRED',
    'SPARK',
    'DIVERGE',
    'FLOW',
    'SURGE',
    'VIVID',
    'DEEP',
    'INTENSE',
    'HOPE',
    'KIND',
    'BOLD',
    'GENTLE',
    'ASCEND',
    'THRIVE',
    'INSPIRE',
    'BALANCE',
    // Permission / rest words for a calmer tone.
    'REST',
    'PAUSE',
    'SAFE',
    'HERE',
    'NOW',
    'EASE',
  ];

  /// Endless late pool (9-14 letters). UNFINISHED is endless-only.
  static const List<String> endless = <String>[
    'UNSTOPPABLE',
    'COURAGEOUS',
    'DETERMINED',
    'PERSISTING',
    'UNFINISHED',
    'PROGRESSING',
    'DISCOVERING',
    'FLOURISHING',
    'OVERCOMING',
    'BELONGING',
    'EXPANDING',
    'TRANSFORMING',
    'DIFFERENTLY',
    'PIONEERING',
    'TRAILBLAZER',
    'REMARKABLE',
    'EXTRAORDINARY',
    'UNBOUNDED',
    'RELENTLESS',
    'RESILIENT',
  ];

  /// Count of collectible letters (spaces excluded).
  static int letterCount(String word) {
    var n = 0;
    for (final code in word.codeUnits) {
      if (code != 0x20) n++;
    }
    return n;
  }

  /// Standard words whose letter count is in [[minLen], [maxLen]].
  static List<String> standardInLengthBand(int minLen, int maxLen) {
    return standard
        .where((w) {
          final n = letterCount(w);
          return n >= minLen && n <= maxLen;
        })
        .toList(growable: false);
  }

  /// Endless late words with letter count 9-14.
  static List<String> endlessLatePool() {
    return endless
        .where((w) {
          final n = letterCount(w);
          return n >= 9 && n <= 14;
        })
        .toList(growable: false);
  }
}
