import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Documents Bug A: natural round end must not fire-and-forget achievement
/// persistence (mid-exit awaits; full-round often does not).
///
/// See `.kodaelus/bugs/mini-game-achievements-and-patient-one-dossier.md`.
void main() {
  const playScreens = [
    'lib/screens/firefly_jar_play_screen.dart',
    'lib/screens/rain_catcher_play_screen.dart',
    'lib/screens/meteor_catch_play_screen.dart',
    'lib/screens/word_bloom_play_screen.dart',
    'lib/screens/stone_balance_play_screen.dart',
    'lib/screens/breath_pacer_play_screen.dart',
  ];

  test(
    'natural finish does not call unawaited _onRoundComplete()',
    () {
      final unawaitedNaturalFinish = RegExp(
        r'if\s*\(\s*!wasFinished\s*&&\s*engine\.isFinished\s*\)\s*\{\s*'
        r'_onRoundComplete\(\)\s*;',
        multiLine: true,
      );

      for (final path in playScreens) {
        final source = File(path).readAsStringSync();
        expect(
          unawaitedNaturalFinish.hasMatch(source),
          isFalse,
          reason:
              '$path: natural finish must await or otherwise gate dismiss on '
              '_onRoundComplete so achievement progress is not lost when the '
              'end overlay is dismissed quickly',
        );
      }
    },
  );
}
