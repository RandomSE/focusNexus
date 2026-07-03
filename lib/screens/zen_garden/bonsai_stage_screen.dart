import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/utils/theme_styles.dart';

/// Horizontal row of bonsai slots for one cherry blossom stage.
class BonsaiStageScreen extends ConsumerWidget {
  const BonsaiStageScreen({
    super.key,
    required this.stageIndex,
    this.prestigePath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
  });

  final int stageIndex;
  final CherryBlossomPrestigePath? prestigePath;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(zenGardenSessionProvider).garden.cherryBlossomTree;
    final filled = tree.bonsaiCountForStage(stageIndex);
    final slots = CherryBlossomStageCatalog.levelsPerStage;
    final asset = CherryBlossomStageCatalog.assetPathFor(
      stageIndex: stageIndex,
      prestigePath: prestigePath,
    );
    final title = CherryBlossomStageCatalog.displayNameFor(
      stageIndex: stageIndex,
      prestigePath: prestigePath,
    );

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: primaryColor)),
        backgroundColor: secondaryColor,
        iconTheme: ThemeStyles.iconThemeFor(primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$filled / $slots trees collected',
              style: textStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < slots; i++)
                      _BonsaiSlot(
                        filled: i < filled,
                        assetPath: asset,
                        index: i + 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonsaiSlot extends StatelessWidget {
  const _BonsaiSlot({
    required this.filled,
    required this.assetPath,
    required this.index,
  });

  final bool filled;
  final String assetPath;
  final int index;

  static const double slotSize = 72;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: slotSize,
            height: slotSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(8),
              color: filled ? const Color(0xFFE8F0E8) : const Color(0xFFF0F0F0),
            ),
            alignment: Alignment.bottomCenter,
            child: filled
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  )
                : Icon(Icons.circle_outlined, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text('$index', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
