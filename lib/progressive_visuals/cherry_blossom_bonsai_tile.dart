import 'package:flutter/material.dart';

import 'cherry_blossom_bonsai_ref.dart';
import 'cherry_blossom_stage_catalog.dart';

/// Bonsai cell — tree art maximized; stages 6–7 cover the full slot.
class CherryBlossomBonsaiTile extends StatelessWidget {
  const CherryBlossomBonsaiTile({
    super.key,
    required this.bonsaiKey,
    this.onTap,
    this.selected = false,
    this.empty = false,
    this.countLabel,
  });

  final String? bonsaiKey;
  final VoidCallback? onTap;
  final bool selected;
  final bool empty;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final ref = CherryBlossomBonsaiRef.parse(bonsaiKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final stage = ref?.stageIndex ?? 0;
        final fillsSlot =
            ref != null && CherryBlossomStageCatalog.bonsaiFillsSlot(stage);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: empty
                    ? const Color(0xFFE4EDE4).withValues(alpha: 0.55)
                    : CherryBlossomStageCatalog.scaffoldColorFor(stage)
                        .withValues(alpha: fillsSlot ? 1.0 : 0.35),
                border: Border.all(
                  color: selected ? Colors.amber : const Color(0xFFB8C8B8),
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: empty || ref == null
                    ? null
                    : fillsSlot
                        ? _buildFullSlotTree(ref)
                        : _buildGroundedTree(
                            ref,
                            width: w,
                            height: h,
                          ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullSlotTree(CherryBlossomBonsaiRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          ref.assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        if (countLabel != null) _countBadge(),
      ],
    );
  }

  Widget _buildGroundedTree(
    CherryBlossomBonsaiRef ref, {
    required double width,
    required double height,
  }) {
    final treeH =
        height * CherryBlossomStageCatalog.bonsaiTreeHeightFraction(ref.stageIndex);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: treeH,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              ref.assetPath,
              fit: BoxFit.fitHeight,
              width: width,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (countLabel != null) _countBadge(),
      ],
    );
  }

  Widget _countBadge() {
    return Positioned(
      right: 3,
      bottom: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            countLabel!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
