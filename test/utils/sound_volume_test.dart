import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/sound_volume.dart';

void main() {
  test('clamps below zero to 0.0', () {
    expect(normalizeSoundVolume(-10), 0.0);
  });

  test('clamps above 100 to 1.0', () {
    expect(normalizeSoundVolume(150), 1.0);
  });

  test('scales mid-range values to 0.0–1.0', () {
    expect(normalizeSoundVolume(50), 0.5);
    expect(normalizeSoundVolume(0), 0.0);
    expect(normalizeSoundVolume(100), 1.0);
  });
}
