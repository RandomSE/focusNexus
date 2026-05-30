import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';

import 'zen_garden_decor_painters.dart';
import 'zen_garden_painters.dart';
import 'zen_placeable_layout.dart';

/// Decor placeable with optional looping animation (koi, lantern pulse).
class ZenDecorVisual extends StatefulWidget {
  const ZenDecorVisual({
    super.key,
    required this.item,
    required this.selected,
    required this.primary,
    required this.secondary,
    required this.reduceMotion,
    this.timerProgress,
  });

  final DecorItem item;
  final bool selected;
  final Color primary;
  final Color secondary;
  final bool reduceMotion;
  final double? timerProgress;

  static const double width = 96;
  static const double height = 90;

  @override
  State<ZenDecorVisual> createState() => _ZenDecorVisualState();
}

class _ZenDecorVisualState extends State<ZenDecorVisual>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _animSeconds = 0;

  bool get _koiPond => widget.item.kind == 'zen.koi_pond';

  bool get _needsAnimation {
    if (_koiPond) return true;
    return zenDecorNeedsAnimation(widget.item, reduceMotion: widget.reduceMotion);
  }

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ZenDecorVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.kind != widget.item.kind ||
        oldWidget.item.stageIndex != widget.item.stageIndex ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (_needsAnimation && _ticker == null) {
      _ticker = createTicker((elapsed) {
        final seconds = elapsed.inMicroseconds / 1000000.0;
        if (!mounted) return;
        setState(() => _animSeconds = seconds);
      })..start();
    } else if (!_needsAnimation && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _animSeconds = 0;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showLanternGlow =
        widget.item.kind == 'zen.stone_lantern' && widget.item.stageIndex >= 2;
    final glowSize = showLanternGlow
        ? ZenGardenDecorPainter.lanternSandGlowSize(widget.item.stageIndex)
        : Size.zero;
    final animSeconds = _needsAnimation ? _animSeconds : 0.0;

    Widget paintLayer(double seconds) {
      final canvas = zenDecorPaintCanvasSize(widget.item);
      final showShadow = zenDecorUsesGroundShadow(widget.item.kind);
      final topRadius = zenDecorTopClipRadius(widget.item.kind);
      final shadowCenter = Offset(canvas.width / 2, 10);
      final shadowW = widget.item.kind == 'zen.koi_pond'
          ? (zenKoiPondFitWidth(
                widget.item.stageIndex.clamp(0, 4),
                canvas.width,
                canvasHeight: canvas.height,
              ) *
              0.72)
              .clamp(62.0, 88.0)
          : 62.0;

      final layer = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          if (showShadow)
            CustomPaint(
              size: Size(canvas.width, 14),
              painter: PlaceableGroundShadowPainter(
                center: shadowCenter,
                width: shadowW,
                height: 12,
              ),
            ),
          CustomPaint(
            size: Size(canvas.width, canvas.height),
            painter: ZenDecorPainter(
              item: widget.item,
              primary: widget.primary,
              secondary: widget.secondary,
              animPhase: seconds,
            ),
          ),
        ],
      );

      if (topRadius > 0) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          clipBehavior: Clip.antiAlias,
          child: layer,
        );
      }
      return ClipRect(
        clipBehavior: Clip.hardEdge,
        child: layer,
      );
    }

    Widget glowLayer(double seconds) {
      if (!showLanternGlow) return const SizedBox.shrink();
      return CustomPaint(
        size: glowSize,
        painter: LanternSandGlowPainter(
          item: widget.item,
          animPhase: seconds,
        ),
      );
    }

    final body = Semantics(
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: widget.reduceMotion ? 1.0 : (widget.selected ? 1.05 : 1.0),
        duration: widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        child: SizedBox(
          width: ZenDecorVisual.width,
          height: ZenDecorVisual.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (showLanternGlow)
                Positioned(
                  bottom: 0,
                  left: (ZenDecorVisual.width - glowSize.width) / 2,
                  child: ClipRect(child: glowLayer(animSeconds)),
                ),
              if (widget.selected && !widget.reduceMotion)
                Positioned(
                  top: -4,
                  child: Icon(
                    Icons.arrow_drop_up,
                    size: 30,
                    color: widget.primary.withValues(alpha: 0.85),
                  ),
                ),
              CustomPaint(
                size: const Size(ZenDecorVisual.width, ZenDecorVisual.height),
                painter: PlantHaloPainter(
                  selected: widget.selected,
                  primary: widget.primary,
                  timerProgress: widget.timerProgress,
                ),
              ),
              Positioned(
                bottom: 2,
                child: paintLayer(animSeconds),
              ),
            ],
          ),
        ),
      ),
    );

    // Koi always swim; force tickers on even when platform reduce-motion is set.
    if (_koiPond) {
      return TickerMode(enabled: true, child: body);
    }
    return body;
  }
}
