import 'package:flutter/painting.dart';

/// Pure ARGB inversion for mutation previews (alpha preserved).
int invertArgb32(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return (a << 24) | ((255 - r) << 16) | ((255 - g) << 8) | (255 - b);
}

/// RGB invert matrix for [ColorFiltered] (alpha channel unchanged).
///
/// Matches [invertArgb32] for Image / CustomPaint subtrees (tree + petals).
const ColorFilter rgbInvertColorFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);
