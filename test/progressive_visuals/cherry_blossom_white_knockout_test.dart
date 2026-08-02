import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_viewport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// True when RGB is near paper-white (PNG knockout failed).
  bool isPaperWhite(int r, int g, int b) =>
      r >= 245 && g >= 245 && b >= 245;

  Future<ByteData> captureViewport(
    WidgetTester tester, {
    required int stageIndex,
    int growthStepsInStage = 12,
  }) async {
    const size = Size(400, 600);
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: stageIndex,
          growthStepsInStage: growthStepsInStage,
        )
        .normalized();

    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF00FF00),
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('cherry_capture'),
              child: SizedBox.fromSize(
                size: size,
                child: CherryBlossomTreeViewport(
                  tree: tree,
                  size: size,
                  animateEffects: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Give Image.asset a couple frames to decode.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('cherry_capture')),
    );

    // toImage must run outside the test zone or it hangs.
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1.0),
    );
    expect(image, isNotNull);
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(bytes, isNotNull);
    return bytes!;
  }

  void expectNotPaperWhite(
    ByteData bytes, {
    required int x,
    required int y,
    required int width,
    required String label,
  }) {
    final i = (y * width + x) * 4;
    final r = bytes.getUint8(i);
    final g = bytes.getUint8(i + 1);
    final b = bytes.getUint8(i + 2);
    expect(
      isPaperWhite(r, g, b),
      isFalse,
      reason: '$label at ($x,$y) is paper-white rgb($r,$g,$b); '
          'white knockout failed',
    );
  }

  void expectNotNearBlack(
    ByteData bytes, {
    required int x,
    required int y,
    required int width,
    required String label,
  }) {
    final i = (y * width + x) * 4;
    final r = bytes.getUint8(i);
    final g = bytes.getUint8(i + 1);
    final b = bytes.getUint8(i + 2);
    // Pure (0,0,0) means knockout/background failed. Night skies can be dark
    // but still carry chroma (indigo/plum), so require some channel energy.
    expect(
      r + g + b,
      greaterThan(40),
      reason: '$label at ($x,$y) is near-black rgb($r,$g,$b); '
          'sky underlay / background failed',
    );
  }

  for (var stage = 0; stage <= 5; stage++) {
    testWidgets(
      'stage $stage tree sky area is not paper-white after knockout',
      (tester) async {
        const width = 400;
        const height = 600;
        final bytes = await captureViewport(tester, stageIndex: stage);

        final maxH = CherryBlossomStageCatalog.maxTreeHeightFraction(stage);
        final treeTop = (height * (1.0 - maxH)).floor();
        final sampleY = (treeTop + 24).clamp(0, height - 1);
        expectNotPaperWhite(
          bytes,
          x: 20,
          y: sampleY,
          width: width,
          label: 'stage $stage left',
        );
        expectNotPaperWhite(
          bytes,
          x: width ~/ 2,
          y: sampleY,
          width: width,
          label: 'stage $stage center',
        );
        expectNotPaperWhite(
          bytes,
          x: width - 20,
          y: sampleY,
          width: width,
          label: 'stage $stage right',
        );
      },
    );
  }

  for (var stage = 3; stage <= 5; stage++) {
    testWidgets(
      'stage $stage sky is not a black field beside the tree',
      (tester) async {
        const width = 400;
        const height = 600;
        final bytes = await captureViewport(tester, stageIndex: stage);

        final maxH = CherryBlossomStageCatalog.maxTreeHeightFraction(stage);
        final treeTop = (height * (1.0 - maxH)).floor();
        final sampleY = (treeTop + 20).clamp(0, height - 1);
        // Side samples: PNG white knocked out over painted sky (not pure black).
        expectNotNearBlack(
          bytes,
          x: 16,
          y: sampleY,
          width: width,
          label: 'stage $stage left sky',
        );
        expectNotNearBlack(
          bytes,
          x: width - 16,
          y: sampleY,
          width: width,
          label: 'stage $stage right sky',
        );
      },
    );
  }

  testWidgets(
    'Golden Afternoon canopy stays pink-dominant (not sky see-through)',
    (tester) async {
      const width = 400;
      const height = 600;
      final bytes = await captureViewport(
        tester,
        stageIndex: 3,
        growthStepsInStage: 12,
      );

      // Scan a mid canopy band for authored pink (layout scales with fitHeight).
      var pinkHits = 0;
      var samples = 0;
      for (var y = (height * 0.40).floor(); y < (height * 0.58).floor(); y += 6) {
        for (var x = (width * 0.35).floor(); x < (width * 0.65).floor(); x += 6) {
          final i = (y * width + x) * 4;
          final r = bytes.getUint8(i);
          final g = bytes.getUint8(i + 1);
          final b = bytes.getUint8(i + 2);
          // Skip clear sky / ground underlay samples.
          if (r + g + b < 120) continue;
          if (b > r + 10 && g > r) continue;
          samples++;
          if (r > b + 15 && r > g) {
            pinkHits++;
          }
        }
      }
      expect(samples, greaterThan(20), reason: 'expected canopy samples');
      expect(
        pinkHits / samples,
        greaterThan(0.55),
        reason: 'canopy should be mostly pink-dominant, got '
            '$pinkHits/$samples',
      );
    },
  );

  testWidgets(
    'Golden Afternoon has no white paper plate at image corners',
    (tester) async {
      const width = 400;
      const height = 600;
      final bytes = await captureViewport(
        tester,
        stageIndex: 3,
        growthStepsInStage: 12,
      );

      // Far corners of the tree layer region must show sky, not asbestos white.
      for (final (x, y, label) in [
        (12, 80, 'top-left'),
        (width - 12, 80, 'top-right'),
        (12, height - 40, 'bottom-left'),
        (width - 12, height - 40, 'bottom-right'),
      ]) {
        final i = (y * width + x) * 4;
        final r = bytes.getUint8(i);
        final g = bytes.getUint8(i + 1);
        final b = bytes.getUint8(i + 2);
        expect(
          isPaperWhite(r, g, b),
          isFalse,
          reason: '$label plate at ($x,$y) rgb($r,$g,$b)',
        );
        expect(
          r + g + b,
          greaterThan(40),
          reason: '$label near-black at ($x,$y) rgb($r,$g,$b)',
        );
      }
    },
  );
}
