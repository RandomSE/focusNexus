import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/music_unlock.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/widgets/sound_channel_settings_tile.dart';

/// Per-track music enable / volume / preview (unlock-gated sections).
class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  Map<SoundChannel, SoundChannelSettings>? _settings;
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
    final loaded = await ref.read(soundServiceProvider).loadChannelSettings();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  Future<void> _persist(Map<SoundChannel, SoundChannelSettings> next) async {
    setState(() => _settings = next);
    await ref.read(soundServiceProvider).saveChannelSettings(next);
  }

  Future<void> _preview(SoundChannel channel) async {
    final sounds = ref.read(soundServiceProvider);
    if (channel == SoundChannel.breathBackground) {
      await sounds.previewBreathBackground(
        onCompleted: () async {
          final achievements = ref.read(achievementServiceProvider);
          if (!achievements.isInitialized) {
            await achievements.initialize();
          }
          await achievements.recordBreathBackgroundFullListen();
        },
      );
      return;
    }
    await sounds.previewMusic(channel);
  }

  @override
  Widget build(BuildContext context) {
    final rewardTypes = ref.watch(appSettingsProvider).snapshot.rewardTypes;
    final progressiveVisualsEnabled =
        rewardTypes.contains(RewardKind.progressiveVisuals.storageValue);
    final miniGamesEnabled =
        rewardTypes.contains(RewardKind.miniGames.storageValue);
    final garden = ref.watch(zenGardenSessionProvider).garden;

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        final primary = bundle.primaryColor;
        final secondary = bundle.secondaryColor;

        final sectionWidgets = <Widget>[];
        if (!_loading && _settings != null) {
          for (final section in SoundMusicSection.values) {
            final channels =
                SoundChannel.musicForSection(section).where((channel) {
              return isMusicChannelUnlocked(
                channel: channel,
                garden: garden,
                progressiveVisualsEnabled: progressiveVisualsEnabled,
                miniGamesEnabled: miniGamesEnabled,
              );
            }).toList(growable: false);
            if (channels.isEmpty) continue;
            if (sectionWidgets.isNotEmpty) {
              sectionWidgets.add(const Divider(height: 28));
            }
            sectionWidgets.add(
              CommonUtils.buildText(
                section.label,
                textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            );
            sectionWidgets.add(const SizedBox(height: 8));
            for (final channel in channels) {
              sectionWidgets.add(
                SoundChannelSettingsTile(
                  channel: channel,
                  settings: _settings![channel]!,
                  textStyle: textStyle,
                  primary: primary,
                  secondary: secondary,
                  onChanged: (nextSettings) {
                    final next =
                        Map<SoundChannel, SoundChannelSettings>.from(_settings!);
                    next[channel] = nextSettings;
                    _persist(next);
                  },
                  onPreview: () => _preview(channel),
                ),
              );
              sectionWidgets.add(const SizedBox(height: 8));
            }
          }
        }

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondary,
            appBar: AppBar(
              title: Text('Music', style: TextStyle(color: primary)),
              backgroundColor: secondary,
              iconTheme: ThemeStyles.iconThemeFor(primary),
            ),
            body: _loading || _settings == null
                ? const Center(child: CircularProgressIndicator())
                : sectionWidgets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No music unlocked yet. Enable Mini-games or '
                            'Progressive visuals, then unlock Cherry blossom '
                            'tracks by growing the tree.',
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: sectionWidgets,
                      ),
          ),
        );
      },
    );
  }
}
