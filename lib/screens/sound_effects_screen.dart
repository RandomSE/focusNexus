import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/widgets/sound_channel_settings_tile.dart';

/// Full-screen per-SFX enable / volume / preview, plus Music entry + master.
class SoundEffectsScreen extends ConsumerStatefulWidget {
  const SoundEffectsScreen({super.key});

  @override
  ConsumerState<SoundEffectsScreen> createState() => _SoundEffectsScreenState();
}

class _SoundEffectsScreenState extends ConsumerState<SoundEffectsScreen> {
  Map<SoundChannel, SoundChannelSettings>? _settings;
  int _musicVolumePercent = 100;
  bool _loading = true;
  SoundService? _sounds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds ??= ref.read(soundServiceProvider);
  }

  @override
  void dispose() {
    _sounds?.stopMusic();
    super.dispose();
  }

  Future<void> _load() async {
    final sounds = ref.read(soundServiceProvider);
    final loaded = await sounds.loadChannelSettings();
    final musicVol = await sounds.getMusicVolume();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _musicVolumePercent = (musicVol * 100).round().clamp(0, 100);
      _loading = false;
    });
  }

  Future<void> _persist(Map<SoundChannel, SoundChannelSettings> next) async {
    setState(() => _settings = next);
    await ref.read(soundServiceProvider).saveChannelSettings(next);
  }

  Future<void> _setMusicVolume(int percent) async {
    setState(() => _musicVolumePercent = percent.clamp(0, 100));
    await ref.read(soundServiceProvider).setMusicVolumePercent(percent);
  }

  Future<void> _preview(SoundChannel channel) async {
    await ref.read(soundServiceProvider).previewChannel(channel);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        final primary = bundle.primaryColor;
        final secondary = bundle.secondaryColor;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondary,
            appBar: AppBar(
              title: Text(
                'Sound effects',
                style: TextStyle(color: primary),
              ),
              backgroundColor: secondary,
              iconTheme: ThemeStyles.iconThemeFor(primary),
            ),
            body: _loading || _settings == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            ref.pushRoute(context, AppRoute.music),
                        icon: const Icon(Icons.library_music_outlined),
                        label: const Text('Music'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonUtils.buildText(
                        'Music volume',
                        textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _musicVolumePercent.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '$_musicVolumePercent%',
                              onChanged: (value) =>
                                  _setMusicVolume(value.round()),
                            ),
                          ),
                          Text(
                            '$_musicVolumePercent%',
                            style: textStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      for (final group in SoundChannelGroup.values
                          .where((g) => g != SoundChannelGroup.music)) ...[
                        CommonUtils.buildText(
                          group.label,
                          textStyle.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        for (final channel
                            in SoundChannel.forGroup(group)) ...[
                          SoundChannelSettingsTile(
                            channel: channel,
                            settings: _settings![channel]!,
                            textStyle: textStyle,
                            primary: primary,
                            secondary: secondary,
                            onChanged: (nextSettings) {
                              final next = Map<SoundChannel,
                                  SoundChannelSettings>.from(_settings!);
                              next[channel] = nextSettings;
                              _persist(next);
                            },
                            onPreview: () => _preview(channel),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Divider(height: 28),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}
