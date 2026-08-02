import 'package:flutter/material.dart';
import 'package:focusNexus/services/sound_channel.dart';

/// Enable / volume / preview row for one [SoundChannel].
class SoundChannelSettingsTile extends StatelessWidget {
  const SoundChannelSettingsTile({
    super.key,
    required this.channel,
    required this.settings,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.onChanged,
    required this.onPreview,
  });

  final SoundChannel channel;
  final SoundChannelSettings settings;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final ValueChanged<SoundChannelSettings> onChanged;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(channel.label, style: textStyle),
              value: settings.enabled,
              activeThumbColor: primary,
              onChanged: (enabled) =>
                  onChanged(settings.copyWith(enabled: enabled)),
            ),
            if (settings.enabled)
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: settings.volumePercent.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${settings.volumePercent}%',
                      onChanged: (value) => onChanged(
                        settings.copyWith(volumePercent: value.round()),
                      ),
                    ),
                  ),
                  Text(
                    '${settings.volumePercent}%',
                    style: textStyle.copyWith(fontSize: 12),
                  ),
                  IconButton(
                    tooltip: 'Play ${channel.label}',
                    onPressed: onPreview,
                    icon: Icon(Icons.play_arrow, color: primary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
