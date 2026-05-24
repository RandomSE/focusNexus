/// Normalizes stored volume (0–100) to player volume (0.0–1.0).
double normalizeSoundVolume(double parsed) {
  return (parsed.clamp(0.0, 100.0)) / 100.0;
}
