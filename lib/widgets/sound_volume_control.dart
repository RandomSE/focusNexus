import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/utils/sound_volume.dart';

/// Integer percent volume (0–100) with slider and ±1 / ±5 step buttons.
class SoundVolumeControl extends ConsumerWidget {
  const SoundVolumeControl({
    super.key,
    required this.bundle,
  });

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider.notifier).service;
    final persisted = roundSoundVolumePercent(settings.soundVolume);
    final liveOverride = ref.watch(soundVolumeLiveProvider);
    final volume = liveOverride ?? persisted;

    final textStyle = bundle.textStyle;
    final primary = bundle.primaryColor;
    final secondary = bundle.secondaryColor;

    void setLive(int next) {
      ref.read(soundVolumeLiveProvider.notifier).set(next);
    }

    Future<void> persist(int next) => settings.setSoundVolume(next);

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
          onChanged: (val) => setLive(val.round()),
          onChangeEnd: (val) => persist(val.round()),
        ),
        Row(
          children: [
            Expanded(
              child: _StepButton(
              label: '−5%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume <= 0
                  ? null
                  : () {
                      final next = (volume - 5).clamp(0, 100);
                      setLive(next);
                      persist(next);
                    },
              ),
            ),
            Expanded(
              child: _StepButton(
              label: '−1%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume <= 0
                  ? null
                  : () {
                      final next = (volume - 1).clamp(0, 100);
                      setLive(next);
                      persist(next);
                    },
              ),
            ),
            Expanded(
              child: _StepButton(
              label: '+1%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume >= 100
                  ? null
                  : () {
                      final next = (volume + 1).clamp(0, 100);
                      setLive(next);
                      persist(next);
                    },
              ),
            ),
            Expanded(
              child: _StepButton(
              label: '+5%',
              textStyle: textStyle,
              primary: primary,
              secondary: secondary,
              onPressed: volume >= 100
                  ? null
                  : () {
                      final next = (volume + 5).clamp(0, 100);
                      setLive(next);
                      persist(next);
                    },
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: textStyle.copyWith(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
