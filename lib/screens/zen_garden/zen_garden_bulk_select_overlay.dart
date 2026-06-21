import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';

class ZenGardenBulkSelectOverlay extends StatelessWidget {
  const ZenGardenBulkSelectOverlay({
    super.key,
    required this.selection,
    required this.bulkCount,
    required this.textStyle,
    required this.secondaryColor,
    required this.gardenLayoutSize,
    required this.onBulkSelectStyleChanged,
    required this.onTouch,
  });

  final SandboxSelectionState selection;
  final int bulkCount;
  final TextStyle textStyle;
  final Color secondaryColor;
  final Size gardenLayoutSize;
  final void Function(BulkSelectStyle style) onBulkSelectStyleChanged;
  final VoidCallback onTouch;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          MediaQuery.paddingOf(context).bottom + 10,
        ),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          color: secondaryColor.withValues(alpha: 0.97),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: gardenLayoutSize.height * 0.32,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<BulkSelectStyle>(
                    segments: const [
                      ButtonSegment(
                        value: BulkSelectStyle.tap,
                        label: Text('Tap'),
                        icon: Icon(Icons.touch_app_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: BulkSelectStyle.area,
                        label: Text('Area'),
                        icon: Icon(Icons.crop_free, size: 18),
                      ),
                    ],
                    selected: {selection.bulkSelectStyle},
                    onSelectionChanged: (selected) {
                      onBulkSelectStyleChanged(selected.first);
                      onTouch();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selection.bulkSelectStyle == BulkSelectStyle.area
                        ? (bulkCount == 0
                            ? 'Drag a box over items to select them. Tap empty sand to clear.'
                            : '$bulkCount selected. Drag to move the group. Tap empty sand to clear.')
                        : (bulkCount == 0
                            ? 'Tap plants or decorations to toggle selection.'
                            : '$bulkCount selected. Drag to move the group. Tap empty sand to clear.'),
                    style: textStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
