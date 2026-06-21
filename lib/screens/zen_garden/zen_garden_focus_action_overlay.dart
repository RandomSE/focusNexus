import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

import 'zen_garden_bottom_actions.dart';

/// When the selected item sits low on the sand, anchor the action panel at the top
/// so it does not cover the selection.
bool zenGardenActionPanelUsesTopAnchor(double normY) => normY > 0.58;

double zenGardenFullscreenTopInset(BuildContext context, {required bool chromeVisible}) {
  final topPadding = MediaQuery.paddingOf(context).top;
  return topPadding + (chromeVisible ? 8 : 56);
}

class ZenGardenFocusActionOverlay extends StatelessWidget {
  const ZenGardenFocusActionOverlay({
    super.key,
    required this.multiMode,
    required this.focusPlant,
    required this.focusDecor,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.garden,
    required this.growCost,
    required this.growCostDecor,
    required this.isFirstPlantFree,
    required this.chromeVisible,
    required this.gardenLayoutSize,
    required this.onGrow,
    required this.onGrowDecor,
    required this.onSkip,
    required this.onSkipDecor,
    required this.onRemoveMutation,
    required this.onRemoveDecorMutation,
    required this.onRestart,
    required this.onRestartDecor,
    required this.onRemovePlant,
    required this.onRemoveDecor,
  });

  final bool multiMode;
  final GardenItem? focusPlant;
  final DecorItem? focusDecor;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final GardenState garden;
  final int? growCost;
  final int? growCostDecor;
  final bool isFirstPlantFree;
  final bool chromeVisible;
  final Size gardenLayoutSize;
  final VoidCallback? onGrow;
  final VoidCallback? onGrowDecor;
  final VoidCallback? onSkip;
  final VoidCallback? onSkipDecor;
  final VoidCallback? onRemoveMutation;
  final VoidCallback? onRemoveDecorMutation;
  final VoidCallback? onRestart;
  final VoidCallback? onRestartDecor;
  final VoidCallback? onRemovePlant;
  final VoidCallback? onRemoveDecor;

  Widget _buildGardenOverlayShell({
    required BuildContext context,
    required bool anchorTop,
    required Widget child,
  }) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: anchorTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          anchorTop ? zenGardenFullscreenTopInset(context, chromeVisible: chromeVisible) : 10,
          12,
          anchorTop ? 10 : bottomPadding + 10,
        ),
        child: Material(
          elevation: 10,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          color: secondary.withValues(alpha: 0.97),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: gardenLayoutSize.height * 0.48,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (multiMode) return const SizedBox.shrink();

    if (focusPlant == null && focusDecor == null) {
      return const SizedBox.shrink();
    }

    final anchorY = focusPlant?.positionY ?? focusDecor!.positionY;
    return _buildGardenOverlayShell(
      context: context,
      anchorTop: zenGardenActionPanelUsesTopAnchor(anchorY),
      child: ZenGardenBottomActions(
        textStyle: textStyle,
        primary: primary,
        secondary: secondary,
        garden: garden,
        plant: focusPlant,
        decor: focusDecor,
        growCost: growCost,
        growCostDecor: growCostDecor,
        isFirstPlantFree: isFirstPlantFree,
        onGrow: focusPlant == null ? null : onGrow,
        onGrowDecor: focusDecor == null ? null : onGrowDecor,
        onSkip: focusPlant == null ? null : onSkip,
        onSkipDecor: focusDecor == null ? null : onSkipDecor,
        onRemoveMutation: focusPlant == null ? null : onRemoveMutation,
        onRemoveDecorMutation: focusDecor == null ? null : onRemoveDecorMutation,
        onRestart: focusPlant == null ? null : onRestart,
        onRestartDecor: focusDecor == null ? null : onRestartDecor,
        onRemovePlant: focusPlant == null ? null : onRemovePlant,
        onRemoveDecor: focusDecor == null ? null : onRemoveDecor,
      ),
    );
  }
}
