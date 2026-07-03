import 'package:flutter/material.dart';

import 'cherry_blossom_tree_viewport.dart';
import 'cherry_blossom_tree_state.dart';

/// Slide transition between full stage scenes during prestige.
class CherryBlossomPrestigeTransition extends StatelessWidget {
  const CherryBlossomPrestigeTransition({
    super.key,
    required this.animation,
    required this.outgoing,
    required this.incoming,
    required this.size,
  });

  final Animation<double> animation;
  final CherryBlossomTreeState outgoing;
  final CherryBlossomTreeState incoming;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final slide = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return ClipRect(
      child: AnimatedBuilder(
        animation: slide,
        builder: (context, _) {
          final t = slide.value;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Transform.translate(
                offset: Offset(-size.width * t, 0),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CherryBlossomTreeViewport(
                    tree: outgoing,
                    size: size,
                    animateEffects: false,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(size.width * (1 - t), 0),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CherryBlossomTreeViewport(
                    tree: incoming,
                    size: size,
                    growPulseT: 1.0,
                    animateEffects: false,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
