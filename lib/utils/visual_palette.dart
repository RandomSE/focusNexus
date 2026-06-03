import 'package:flutter/material.dart';

/// Built-in text/background colours (theme, contrast, and dark/light defaults).
const List<Color> kFreeDefaultColors = [
  Color(0xFF1D2730),
  Color(0xFFF3F6F4),
  Color(0xFFE5ECF4),
  Color(0xFF141A22),
  Color(0xFF5B6FF6),
  Color(0xFF8FA1FF),
];

String labelForColor(Color color) {
  switch (color.toARGB32()) {
    case 0xFF1D2730:
      return 'Slate text';
    case 0xFFF3F6F4:
      return 'Soft sage background';
    case 0xFFE5ECF4:
      return 'Misty light text';
    case 0xFF141A22:
      return 'Ink background';
    case 0xFF5B6FF6:
      return 'Focus blue accent';
    case 0xFF8FA1FF:
      return 'Calm indigo accent';
    default:
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }
}
