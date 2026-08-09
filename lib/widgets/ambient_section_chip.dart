import 'package:flutter/material.dart';

/// Contrast-safe section / silence chip for the ambient soundscape picker.
class AmbientSectionChip extends StatelessWidget {
  const AmbientSectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textStyle,
    required this.primary,
    required this.secondary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? secondary : primary;
    return FilterChip(
      label: Text(
        label,
        style: textStyle.copyWith(
          color: labelColor,
          fontSize: textStyle.fontSize,
        ),
        softWrap: true,
      ),
      labelStyle: textStyle.copyWith(color: labelColor),
      selected: selected,
      showCheckmark: false,
      selectedColor: primary,
      backgroundColor: secondary,
      checkmarkColor: secondary,
      side: BorderSide(color: primary),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onTap(),
    );
  }
}
