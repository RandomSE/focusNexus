import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_engine.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_painter.dart';

/// Stresses the dyslexia + large-font glyph path that previously exhausted
/// Impeller's text atlas (Could not create valid atlas / Frame bounds...).
void main() {
  test('OpenDyslexic fontSize 24 paint stress keeps fixed image glyph cache', () {
    final engine = WordBloomEngine(
      playSize: const Size(400, 800),
      endless: false,
      random: null,
    );
    addTearDown(engine.dispose);

    engine.setLetterLayoutSize(
      WordBloomConstants.letterLayoutSizeForSettingsFont(24),
    );
    expect(engine.letterLayoutSize, WordBloomConstants.maxLetterLayoutSize);

    engine.forceWordForTest('CENTERED');
    engine.shatterForTest();

    final cache = <String, ui.Image>{};
    addTearDown(() {
      for (final image in cache.values) {
        image.dispose();
      }
      cache.clear();
    });

    final glyphStyle = TextStyle(
      inherit: false,
      fontFamily: 'OpenDyslexic',
      fontWeight: FontWeight.w700,
      fontSize: engine.letterLayoutSize,
      height: 1.0,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 800);

    for (var i = 0; i < 240; i++) {
      engine.update(1 / 60);
      final painter = WordBloomPainter(
        engine: engine,
        glyphStyle: glyphStyle,
        glyphImageCache: cache,
      );
      painter.paint(canvas, size);
    }

    // Cache should stay bounded to unique (char,color) pairs, not per-frame sizes.
    expect(cache.length, lessThanOrEqualTo(32));
    expect(cache.isNotEmpty, isTrue);

    // Padded raster must clear OpenDyslexic ascenders (height:1.0 clipped ~top 1/6).
    final sample = cache.values.first;
    final minHeight = (engine.letterLayoutSize *
            WordBloomConstants.glyphLineHeight *
            0.9)
        .ceil();
    expect(sample.height, greaterThanOrEqualTo(minHeight));
  });
}
