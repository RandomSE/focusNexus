import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_painter.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('max-state painter paints 20 frames within performance budget', () {
    final tree = CherryBlossomTreeEngine.maxedState();
    const size = Size(800, 1000);
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < 20; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      CherryBlossomTreePainter(tree: tree).paint(canvas, size);
      recorder.endRecording();
    }

    stopwatch.stop();
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(5000),
      reason: 'observed ${stopwatch.elapsedMilliseconds}ms for 20 max-state paints',
    );
  });
}
