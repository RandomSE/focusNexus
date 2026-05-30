import 'package:flutter/material.dart';

/// Converts local canvas coordinates to normalized sandbox space (0–1).
Offset sandboxNormFromLocal(Offset local, Size size) {
  if (size.width <= 0 || size.height <= 0) return Offset.zero;
  return Offset(
    (local.dx / size.width).clamp(0.0, 1.0),
    (local.dy / size.height).clamp(0.0, 1.0),
  );
}

/// Whether the viewport is at default scale and position.
bool sandboxViewportIsDefault(Matrix4 matrix, {double epsilon = 0.001}) {
  final identity = Matrix4.identity().storage;
  for (var i = 0; i < 16; i++) {
    if ((matrix.storage[i] - identity[i]).abs() > epsilon) return false;
  }
  return true;
}

/// Interpolate between two viewport transforms.
Matrix4 lerpSandboxViewportMatrix(Matrix4 from, Matrix4 to, double t) {
  final out = List<double>.generate(
    16,
    (i) => from.storage[i] + (to.storage[i] - from.storage[i]) * t,
  );
  return Matrix4.fromList(out);
}

/// Snap the sandbox viewport to its default centered view.
void resetSandboxViewport(TransformationController controller) {
  controller.value = Matrix4.identity();
}

/// Pinch/pan zoom wrapper shared by progressive visual sandboxes.
class ProgressiveSandboxViewport extends StatelessWidget {
  const ProgressiveSandboxViewport({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    required this.transformationController,
    this.minScale = 1,
    this.maxScale = 4,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  final double width;
  final double height;
  final Widget child;
  final TransformationController transformationController;
  final double minScale;
  final double maxScale;
  final bool panEnabled;
  final bool scaleEnabled;
  final void Function(PointerDownEvent event, double nx, double ny)? onPointerDown;
  final void Function(PointerMoveEvent event, double nx, double ny)? onPointerMove;
  final void Function(PointerUpEvent event, double nx, double ny)? onPointerUp;
  final VoidCallback? onPointerCancel;

  Offset _normFromEvent(PointerEvent event, RenderBox box) {
    final local = box.globalToLocal(event.position);
    return sandboxNormFromLocal(local, Size(width, height));
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformationController,
      minScale: minScale,
      maxScale: maxScale,
      panEnabled: panEnabled,
      scaleEnabled: scaleEnabled,
      boundaryMargin: panEnabled ? const EdgeInsets.all(64) : EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: Builder(
          builder: (canvasContext) {
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: onPointerDown == null
                  ? null
                  : (e) {
                      final box =
                          canvasContext.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize) return;
                      final norm = _normFromEvent(e, box);
                      onPointerDown!(e, norm.dx, norm.dy);
                    },
              onPointerMove: onPointerMove == null
                  ? null
                  : (e) {
                      final box =
                          canvasContext.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize) return;
                      final norm = _normFromEvent(e, box);
                      onPointerMove!(e, norm.dx, norm.dy);
                    },
              onPointerUp: onPointerUp == null
                  ? null
                  : (e) {
                      final box =
                          canvasContext.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize) return;
                      final norm = _normFromEvent(e, box);
                      onPointerUp!(e, norm.dx, norm.dy);
                    },
              onPointerCancel: onPointerCancel == null
                  ? null
                  : (_) => onPointerCancel!(),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
