/// Pure ARGB inversion for mutation previews (alpha preserved).
int invertArgb32(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return (a << 24) | ((255 - r) << 16) | ((255 - g) << 8) | (255 - b);
}
