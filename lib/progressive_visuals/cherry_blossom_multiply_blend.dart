import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Composites [child] over existing paint using [BlendMode.multiply] so white
/// pixels in the child reveal the background beneath.
///
/// Must NOT force its own compositing layer: an isolated layer has a transparent
/// destination, so multiply cannot see the painted sky and white PNG stays white.
class CherryBlossomMultiplyBlend extends SingleChildRenderObjectWidget {
  const CherryBlossomMultiplyBlend({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderCherryBlossomMultiplyBlend();

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCherryBlossomMultiplyBlend renderObject,
  ) {}
}

class RenderCherryBlossomMultiplyBlend extends RenderProxyBox {
  @override
  bool get alwaysNeedsCompositing => false;

  @override
  bool get isRepaintBoundary => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final bounds = offset & size;
    context.canvas.saveLayer(
      bounds,
      Paint()..blendMode = BlendMode.multiply,
    );
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}
