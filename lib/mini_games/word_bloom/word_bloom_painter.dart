import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_engine.dart';

/// Night field, slots, drifting letters, trails, and bloom FX.
///
/// Glyphs are rasterized once to [ui.Image] (via [glyphImageCache]) so Impeller
/// never packs per-frame / per-rotation TextPainter atlas entries. Pulse and
/// pop use [Canvas.scale] only.
class WordBloomPainter extends CustomPainter {
  WordBloomPainter({
    required this.engine,
    required this.glyphStyle,
    required this.glyphImageCache,
  }) : super(repaint: engine);

  final WordBloomEngine engine;
  final TextStyle glyphStyle;

  /// Owned by the play screen [State]; maps cache key -> rasterized glyph.
  final Map<String, ui.Image> glyphImageCache;

  static const Color background = WordBloomConstants.background;

  double get _layoutScale =>
      engine.letterLayoutSize / WordBloomConstants.defaultLetterLayoutSize;

  double get _glyphFontSize => engine.letterLayoutSize;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    switch (engine.phase) {
      case WordBloomPhase.resting:
        _paintSlots(canvas, outlineOnly: false, filled: false);
        _paintRestingWord(canvas);
      case WordBloomPhase.scattered:
        _paintSlots(canvas, outlineOnly: true, filled: true);
        _paintTrails(canvas);
        _paintScatteredLetters(canvas);
      case WordBloomPhase.blooming:
        _paintSlots(canvas, outlineOnly: false, filled: true);
        _paintBloomWord(canvas);
      case WordBloomPhase.transitioning:
        final fade = (1 -
                engine.phaseAge / WordBloomConstants.transitionSeconds)
            .clamp(0.0, 1.0);
        canvas.saveLayer(
          Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 255, 255, fade),
        );
        _paintSlots(canvas, outlineOnly: false, filled: true);
        _paintBloomWord(canvas);
        canvas.restore();
    }

    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.1,
        colors: const [
          Color(0xFF121A28),
          WordBloomConstants.background,
          Color(0xFF06080E),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintSlots(
    Canvas canvas, {
    required bool outlineOnly,
    required bool filled,
  }) {
    final slotW = WordBloomConstants.slotOutlineWidth * _layoutScale;
    final slotH = WordBloomConstants.slotOutlineHeight * _layoutScale;
    final radius = 6.0 * _layoutScale;
    for (final letter in engine.letters) {
      final accent =
          WordBloomConstants.accentPalette[letter.accentIndex];
      final slot = letter.slotPosition;
      if (outlineOnly || !letter.collected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: slot, width: slotW, height: slotH),
            Radius.circular(radius),
          ),
          Paint()
            ..color = accent.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * _layoutScale,
        );
      }
      if (filled && letter.collected) {
        var scale = 1.0;
        if (letter.popProgress > 0 && letter.popProgress < 1) {
          final t = letter.popProgress;
          scale = 1 +
              (WordBloomConstants.collectPopScale - 1) *
                  math.sin(t * math.pi);
        }
        _drawGlyph(
          canvas,
          letter.char,
          slot,
          accent,
          scale: scale,
          rotation: 0,
        );
      }
    }
  }

  void _paintRestingWord(Canvas canvas) {
    final pulse = engine.breathPulse;
    for (final letter in engine.letters) {
      if (letter.char == ' ') continue;
      final accent =
          WordBloomConstants.accentPalette[letter.accentIndex];
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.35 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * _layoutScale);
      canvas.drawCircle(
        letter.slotPosition,
        18 * pulse * _layoutScale,
        glow,
      );
      _drawGlyph(
        canvas,
        letter.char,
        letter.slotPosition,
        accent,
        scale: pulse,
        rotation: 0,
      );
    }
  }

  void _paintTrails(Canvas canvas) {
    for (final entry in engine.letterTrails.entries) {
      final trail = entry.value;
      if (trail.length < 2) continue;
      final letter = engine.letters.firstWhere(
        (l) => l.slotIndex == entry.key,
        orElse: () => engine.letters.first,
      );
      final accent =
          WordBloomConstants.accentPalette[letter.accentIndex];
      for (var i = 1; i < trail.length; i++) {
        final t = i / trail.length;
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = accent.withValues(alpha: 0.15 + 0.35 * t)
            ..strokeWidth = 2.2 * t * _layoutScale
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _paintScatteredLetters(Canvas canvas) {
    for (final letter in engine.letters) {
      if (letter.collected || letter.isAutoLocked) continue;
      if (letter.collectProgress != null) {
        final accent = letter.isGold
            ? WordBloomConstants.goldAccent
            : WordBloomConstants.accentPalette[letter.accentIndex];
        _drawGlyph(
          canvas,
          letter.char,
          letter.position,
          accent,
          scale: 1,
          rotation: letter.rotation,
        );
        continue;
      }
      final accent = letter.isGold
          ? WordBloomConstants.goldAccent
          : WordBloomConstants.accentPalette[letter.accentIndex];
      if (letter.isGold) {
        canvas.drawCircle(
          letter.position,
          16 * _layoutScale,
          Paint()
            ..color = WordBloomConstants.goldAccent.withValues(alpha: 0.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * _layoutScale),
        );
      }
      _drawGlyph(
        canvas,
        letter.char,
        letter.position,
        accent,
        scale: 1,
        rotation: letter.rotation,
      );
    }
  }

  void _paintBloomWord(Canvas canvas) {
    canvas.save();
    final center = Offset(
      engine.playSize.width / 2,
      engine.playSize.height * 0.42,
    );
    canvas.translate(center.dx, center.dy);
    canvas.scale(engine.bloomScale);
    canvas.translate(-center.dx, -center.dy);
    for (final letter in engine.letters) {
      if (letter.char == ' ') continue;
      final accent =
          WordBloomConstants.accentPalette[letter.accentIndex];
      _drawGlyph(
        canvas,
        letter.char,
        letter.slotPosition,
        accent,
        scale: 1,
        rotation: 0,
      );
    }
    canvas.restore();
  }

  void _paintParticles(Canvas canvas) {
    final now = engine.elapsedSeconds;
    for (final p in engine.particles) {
      final t = (p.age(now) / p.life).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.position,
        p.radius * (1 - 0.4 * t),
        Paint()..color = p.color.withValues(alpha: 1 - t),
      );
    }
  }

  String _cacheKey(String char, Color color) {
    return '$char|${color.toARGB32()}|${_glyphFontSize.toStringAsFixed(1)}|'
        '${glyphStyle.fontFamily}|${glyphStyle.fontWeight}|'
        '${WordBloomConstants.glyphLineHeight}|'
        '${WordBloomConstants.glyphRasterPadFraction}';
  }

  ui.Image _imageFor(String char, Color color) {
    final key = _cacheKey(char, color);
    final cached = glyphImageCache[key];
    if (cached != null) return cached;

    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          inherit: false,
          color: color,
          fontSize: _glyphFontSize,
          fontFamily: glyphStyle.fontFamily,
          fontWeight: glyphStyle.fontWeight ?? FontWeight.w700,
          height: WordBloomConstants.glyphLineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout();

    // OpenDyslexic (and some weights) paint outside tight layout bounds; pad so
    // toImageSync does not clip the top ~1/6 of the glyph.
    final pad = _glyphFontSize * WordBloomConstants.glyphRasterPadFraction;
    final width = math.max(1, (painter.width + pad * 2).ceil());
    final height = math.max(1, (painter.height + pad * 2).ceil());
    final recorder = ui.PictureRecorder();
    final pictureCanvas = Canvas(recorder);
    painter.paint(pictureCanvas, Offset(pad, pad));
    painter.dispose();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    glyphImageCache[key] = image;
    return image;
  }

  void _drawGlyph(
    Canvas canvas,
    String char,
    Offset center,
    Color color, {
    required double scale,
    required double rotation,
  }) {
    if (char == ' ') return;
    final image = _imageFor(char, color);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WordBloomPainter oldDelegate) {
    return !identical(oldDelegate.engine, engine) ||
        oldDelegate.glyphStyle != glyphStyle ||
        oldDelegate._glyphFontSize != _glyphFontSize;
  }
}
