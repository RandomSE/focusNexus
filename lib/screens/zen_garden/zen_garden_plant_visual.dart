import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';

import 'zen_garden_cartoon_style.dart';
import 'zen_garden_painters.dart';

/// Visual only; hit-testing and drag are handled by the sand [Listener].
class ZenGardenPlantVisual extends StatelessWidget {
  const ZenGardenPlantVisual({
    super.key,
    required this.item,
    required this.primary,
    required this.selected,
    required this.timerProgress,
    required this.reduceMotion,
  });

  final GardenItem item;
  final Color primary;
  final bool selected;
  final double? timerProgress;
  final bool reduceMotion;

  static const double _w = 96;
  static const double _h = 118;

  @override
  Widget build(BuildContext context) {
    final fill = ZenCartoonStyle.plantFill(
      primary,
      selected: selected,
      mutated: item.mutation == MutationKind.invertedColors,
    );
    final outline = ZenCartoonStyle.ink;

    return Semantics(
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: reduceMotion ? 1.0 : (selected ? 1.04 : 1.0),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        child: SizedBox(
          width: _w,
          height: _h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (selected && !reduceMotion)
                Positioned(
                  top: -6,
                  child: Icon(Icons.arrow_drop_up, size: 32, color: primary.withValues(alpha: 0.85)),
                ),
              CustomPaint(
                size: const Size(_w, _h),
                painter: PlantHaloPainter(
                  selected: selected,
                  primary: primary,
                  timerProgress: timerProgress,
                ),
              ),
              Positioned(
                bottom: 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(72, 14),
                      painter: PlaceableGroundShadowPainter(
                        center: const Offset(36, 10),
                        width: 54,
                        height: 12,
                      ),
                    ),
                    DecoratedBox(
                      decoration: item.mutation == MutationKind.invertedColors
                          ? const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4D00FFD1),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ],
                            )
                          : const BoxDecoration(),
                      child: CustomPaint(
                        size: const Size(72, 92),
                        painter: ZenPlantPainter(
                          stageIndex: item.stageIndex,
                          fill: fill,
                          outline: outline,
                          mutation: item.mutation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
