import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/sound_volume.dart';

/// Integer percent volume (0–100) with slider and ±1 / ±5 step buttons.
class SoundVolumeControl extends StatefulWidget {
  const SoundVolumeControl({
    super.key,
    required this.bundle,
  });

  final ThemeBundle bundle;

  @override
  State<SoundVolumeControl> createState() => _SoundVolumeControlState();
}

class _SoundVolumeControlState extends State<SoundVolumeControl> {
  AppSettings get _settings => AppRepositories.instance.settings;
  late int _liveVolume;

  @override
  void initState() {
    super.initState();
    _liveVolume = roundSoundVolumePercent(_settings.soundVolume);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.bundle.textStyle;
    final primary = widget.bundle.primaryColor;
    final secondary = widget.bundle.secondaryColor;
    final volume = _liveVolume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Volume: $volume%', style: textStyle),
        Slider(
          value: volume.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$volume%',
          onChanged: (val) => setState(() => _liveVolume = val.round()),
          onChangeEnd: (val) => _settings.setSoundVolume(val.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StepButton(
              label: '−5%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume <= 0
                  ? null
                  : () {
                      final next = (volume - 5).clamp(0, 100);
                      setState(() => _liveVolume = next);
                      _settings.setSoundVolume(next);
                    },
            ),
            _StepButton(
              label: '−1%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume <= 0
                  ? null
                  : () {
                      final next = (volume - 1).clamp(0, 100);
                      setState(() => _liveVolume = next);
                      _settings.setSoundVolume(next);
                    },
            ),
            _StepButton(
              label: '+1%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume >= 100
                  ? null
                  : () {
                      final next = (volume + 1).clamp(0, 100);
                      setState(() => _liveVolume = next);
                      _settings.setSoundVolume(next);
                    },
            ),
            _StepButton(
              label: '+5%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume >= 100
                  ? null
                  : () {
                      final next = (volume + 5).clamp(0, 100);
                      setState(() => _liveVolume = next);
                      _settings.setSoundVolume(next);
                    },
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.onPressed,
  });

  final String label;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        backgroundColor: secondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label, style: textStyle.copyWith(fontSize: 12)),
    );
  }
}
