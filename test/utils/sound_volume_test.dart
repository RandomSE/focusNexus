import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/sound_volume.dart';

void main() {
  test('roundSoundVolumePercent clamps and rounds to whole percent', () {
    expect(roundSoundVolumePercent(55.0000001), 55);
    expect(roundSoundVolumePercent(99.6), 100);
    expect(roundSoundVolumePercent(-5), 0);
    expect(roundSoundVolumePercent(150), 100);
  });

  test('normalizeSoundVolume uses integer percent', () {
    expect(normalizeSoundVolume(55.7), closeTo(0.56, 0.001));
  });
}
