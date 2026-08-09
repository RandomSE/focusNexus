import 'package:flutter/material.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/widgets/section_title_actions.dart';

/// Named palette choices; Preview sits under the section title (not in a Row).
class ConsistencyPalettePicker extends StatelessWidget {
  const ConsistencyPalettePicker({
    super.key,
    required this.selected,
    required this.textStyle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onSelected,
    required this.previewEnabled,
    required this.onPreviewToggled,
  });

  final ConsistencyPaletteId selected;
  final TextStyle textStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final ValueChanged<ConsistencyPaletteId> onSelected;
  final bool previewEnabled;
  final VoidCallback onPreviewToggled;

  @override
  Widget build(BuildContext context) {
    final labelStyle = textStyle.copyWith(
      fontSize: (textStyle.fontSize ?? 14).clamp(12.0, 16.0),
      height: 1.2,
    );
    final previewLabelColor = previewEnabled
        ? ConsistencyHeatmapColors.dayNumberColor(primaryColor)
        : (labelStyle.color ?? primaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitleActions(
          title: 'Colour palette',
          titleStyle: labelStyle.copyWith(fontWeight: FontWeight.w700),
          actions: [
            FilterChip(
              label: Text(
                'Preview',
                style: labelStyle.copyWith(
                  fontSize: (labelStyle.fontSize ?? 14).clamp(11.0, 13.0),
                  color: previewLabelColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: previewEnabled,
              onSelected: (_) => onPreviewToggled(),
              selectedColor: primaryColor,
              backgroundColor: secondaryColor,
              checkmarkColor: previewLabelColor,
              side: BorderSide(
                color: previewEnabled
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.55),
                width: previewEnabled ? 1.5 : 1,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in ConsistencyPaletteId.values)
              _PaletteChip(
                label: id.displayName,
                isSelected: selected == id,
                labelStyle: labelStyle,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                onTap: () => onSelected(id),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.label,
    required this.isSelected,
    required this.labelStyle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final TextStyle labelStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedLabelColor =
        ConsistencyHeatmapColors.dayNumberColor(primaryColor);
    final unselectedLabelColor = labelStyle.color ?? primaryColor;
    final chipLabelStyle = labelStyle.copyWith(
      fontSize: (labelStyle.fontSize ?? 14).clamp(11.0, 14.0),
      color: isSelected ? selectedLabelColor : unselectedLabelColor,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
    );

    return ChoiceChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: chipLabelStyle,
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: secondaryColor,
      side: BorderSide(color: primaryColor.withValues(alpha: 0.45)),
      labelStyle: chipLabelStyle,
      onSelected: (_) => onTap(),
    );
  }
}
