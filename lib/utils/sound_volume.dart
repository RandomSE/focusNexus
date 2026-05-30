/// Rounds stored volume to a whole percent (0–100).
int roundSoundVolumePercent(double parsed) {
  return parsed.round().clamp(0, 100);
}

/// Normalizes stored volume (0–100) to player volume (0.0–1.0).
double normalizeSoundVolume(double parsed) {
  return roundSoundVolumePercent(parsed) / 100.0;
}
