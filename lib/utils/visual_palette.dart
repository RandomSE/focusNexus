import 'package:flutter/material.dart';

/// Built-in text/background colours (theme, contrast, and dark/light defaults).
const List<Color> kFreeDefaultColors = [
  Colors.black87,
  Color(0xFFF2EFE6),
  Colors.white70,
  Colors.black,
  Color(0xFF004F52),
  Colors.cyan,
];

String labelForColor(Color color) {
  switch (color.toARGB32()) {
    case 0xDE000000: // black87
      return 'Dark text';
    case 0xFFF2EFE6:
      return 'Cream background';
    case 0xB3FFFFFF: // white70
      return 'Light text';
    case 0xFF000000:
      return 'Black';
    case 0xFF004F52:
      return 'Teal text';
    case 0xFF00FFFF: // cyan
      return 'Cyan text';
    default:
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }
}
