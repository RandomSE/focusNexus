import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/ambient_section_chip.dart';
import 'package:focusNexus/widgets/section_title_actions.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Shop + picker for customization ambient soundscapes.
class BackgroundMusicScreen extends ConsumerStatefulWidget {
  const BackgroundMusicScreen({super.key});

  @override
  ConsumerState<BackgroundMusicScreen> createState() =>
      _BackgroundMusicScreenState();
}

class _BackgroundMusicScreenState extends ConsumerState<BackgroundMusicScreen> {
  AmbientSoundscapeRepository get _repo =>
      ref.read(appRepositoriesProvider).ambientSoundscapes;

  AmbientPlaybackCoordinator? _coordinator;
  SoundService? _sounds;
  AmbientSoundscapeRepository? _repoCached;
  Set<String> _owned = {};
  AmbientSelectionMode _mode = AmbientSelectionMode.global;
  String _globalTrackId = AmbientSoundscapeCatalog.noneTrackId;
  Map<String, String> _sectionTracks = {};
  Map<SoundChannel, SoundChannelSettings>? _channelSettings;
  int _musicVolumePercent = 100;
  bool _loading = true;
  AmbientAppSection _editSection = AmbientAppSection.dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds ??= ref.read(soundServiceProvider);
    _coordinator ??= ref.read(ambientPlaybackCoordinatorProvider);
    _repoCached ??= ref.read(appRepositoriesProvider).ambientSoundscapes;
  }

  @override
  void dispose() {
    final coordinator = _coordinator;
    final sounds = _sounds;
    final repo = _repoCached;
    if (coordinator != null && sounds != null && repo != null) {
      unawaited(coordinator.resume(repo: repo, sounds: sounds));
    }
    super.dispose();
  }

  Future<void> _load() async {
    final sounds = ref.read(soundServiceProvider);
    final owned = await _repo.readOwnedIds();
    final mode = await _repo.readSelectionMode();
    final globalId = await _repo.readGlobalTrackId();
    final sections = await _repo.readSectionTrackIds();
    final channels = await sounds.loadChannelSettings();
    final musicVol = await sounds.getMusicVolume();
    if (!mounted) return;
    setState(() {
      _owned = owned;
      _mode = mode;
      _globalTrackId = globalId;
      _sectionTracks = sections;
      _channelSettings = channels;
      _musicVolumePercent = (musicVol * 100).round().clamp(0, 100);
      _loading = false;
    });
  }

  Future<void> _activateSelection(AmbientAppSection section) async {
    final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
    final sounds = ref.read(soundServiceProvider);
    await coordinator.applyForSection(
      repo: _repo,
      sounds: sounds,
      section: section,
    );
  }

  Future<void> _setMusicVolume(int percent) async {
    setState(() => _musicVolumePercent = percent.clamp(0, 100));
    await ref.read(soundServiceProvider).setMusicVolumePercent(percent);
  }

  Future<void> _persistChannel(
    SoundChannel channel,
    SoundChannelSettings settings,
  ) async {
    final next = Map<SoundChannel, SoundChannelSettings>.from(
      _channelSettings ?? {},
    );
    next[channel] = settings;
    setState(() => _channelSettings = next);
    await ref.read(soundServiceProvider).saveChannelSettings(next);
  }

  Future<void> _preview(SoundChannel channel) async {
    await ref.read(soundServiceProvider).previewAmbient(channel);
  }

  Future<void> _unlock(AmbientCatalogEntry entry) async {
    final textStyle = ref.read(appRepositoriesProvider).settings.textStyle(
          fontSize: ref.read(appRepositoriesProvider).settings.userFontSize,
          color: Theme.of(context).colorScheme.primary,
          dyslexia: ref.read(appRepositoriesProvider).settings.useDyslexiaFont,
        );
    if (_owned.contains(entry.id)) return;
    final spent = await _repo.tryUnlock(entry.id);
    if (!mounted) return;
    if (spent != null) {
      ref.invalidate(pointsBalanceProvider);
      CommonUtils.showSnackBar(
        context,
        'Unlocked ${entry.label}!',
        textStyle,
        2000,
        12,
      );
      await _load();
    } else {
      CommonUtils.showSnackBar(
        context,
        'Not enough points! Need ${entry.pointCost}.',
        textStyle,
        2000,
        12,
      );
    }
  }

  Future<void> _selectTrack(String trackId) async {
    if (!AmbientSoundscapeCatalog.isSpecialSelection(trackId) &&
        !_owned.contains(trackId)) {
      return;
    }
    if (_mode == AmbientSelectionMode.global) {
      await _repo.applyTrackToAllSections(trackId);
      await _load();
      await _activateSelection(AmbientAppSection.dashboard);
      return;
    }
    await _repo.applyTrackToSection(section: _editSection, trackId: trackId);
    await _load();
    await _activateSelection(_editSection);
  }

  bool _isSelected(String trackId) {
    if (_mode == AmbientSelectionMode.global) {
      return _globalTrackId == trackId;
    }
    return (_sectionTracks[_editSection.storageValue] ??
            AmbientSoundscapeCatalog.noneTrackId) ==
        trackId;
  }

  Widget _sectionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required TextStyle textStyle,
    required Color primary,
    required Color secondary,
  }) {
    return AmbientSectionChip(
      label: label,
      selected: selected,
      onTap: onTap,
      textStyle: textStyle,
      primary: primary,
      secondary: secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(pointsBalanceProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        final primary = bundle.primaryColor;
        final secondary = bundle.secondaryColor;
        final pointsLabel = pointsAsync.when(
          data: (p) => 'Points: $p',
          loading: () => 'Points: …',
          error: (_, _) => 'Points: -',
        );

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondary,
            appBar: AppBar(
              title: Text('Background music', style: TextStyle(color: primary)),
              backgroundColor: secondary,
              iconTheme: ThemeStyles.iconThemeFor(primary),
            ),
            body: _loading || _channelSettings == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(pointsLabel, style: textStyle),
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
                      const SizedBox(height: 8),
                      CommonUtils.buildText(
                        'Apply to',
                        textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      CommonUtils.buildListTile(
                        title: 'All sections',
                        textStyle: textStyle,
                        trailing: Icon(
                          _mode == AmbientSelectionMode.global
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: primary,
                        ),
                        onTap: () async {
                          await _repo.writeSelectionMode(
                            AmbientSelectionMode.global,
                          );
                          await _load();
                          await _activateSelection(AmbientAppSection.dashboard);
                        },
                      ),
                      const SizedBox(height: 8),
                      CommonUtils.buildListTile(
                        title: 'Per section',
                        textStyle: textStyle,
                        trailing: Icon(
                          _mode == AmbientSelectionMode.perSection
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: primary,
                        ),
                        onTap: () async {
                          await _repo.writeSelectionMode(
                            AmbientSelectionMode.perSection,
                          );
                          await _load();
                          await _activateSelection(_editSection);
                        },
                      ),
                      if (_mode == AmbientSelectionMode.perSection) ...[
                        const SizedBox(height: 12),
                        CommonUtils.buildText(
                          'Section',
                          textStyle.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final section in AmbientAppSection.values)
                              _sectionChip(
                                label: section.label,
                                selected: _editSection == section,
                                textStyle: textStyle,
                                primary: primary,
                                secondary: secondary,
                                onTap: () async {
                                  setState(() => _editSection = section);
                                  await _activateSelection(section);
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      CommonUtils.buildText(
                        'Silence options',
                        textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_mode == AmbientSelectionMode.global) ...[
                            _sectionChip(
                              label: 'Silence',
                              selected: _isSelected(
                                AmbientSoundscapeCatalog.noneTrackId,
                              ),
                              textStyle: textStyle,
                              primary: primary,
                              secondary: secondary,
                              onTap: () => unawaited(
                                _selectTrack(
                                  AmbientSoundscapeCatalog.noneTrackId,
                                ),
                              ),
                            ),
                          ] else if (_editSection ==
                              AmbientAppSection.progressiveVisuals) ...[
                            _sectionChip(
                              label: 'Garden music only',
                              selected: _isSelected(
                                AmbientSoundscapeCatalog.noneTrackId,
                              ),
                              textStyle: textStyle,
                              primary: primary,
                              secondary: secondary,
                              onTap: () => unawaited(
                                _selectTrack(
                                  AmbientSoundscapeCatalog.noneTrackId,
                                ),
                              ),
                            ),
                            _sectionChip(
                              label: 'Silence all',
                              selected: _isSelected(
                                AmbientSoundscapeCatalog.muteAllTrackId,
                              ),
                              textStyle: textStyle,
                              primary: primary,
                              secondary: secondary,
                              onTap: () => unawaited(
                                _selectTrack(
                                  AmbientSoundscapeCatalog.muteAllTrackId,
                                ),
                              ),
                            ),
                          ] else
                            _sectionChip(
                              label: 'Silence',
                              selected: _isSelected(
                                AmbientSoundscapeCatalog.noneTrackId,
                              ),
                              textStyle: textStyle,
                              primary: primary,
                              secondary: secondary,
                              onTap: () => unawaited(
                                _selectTrack(
                                  AmbientSoundscapeCatalog.noneTrackId,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 28),
                      CommonUtils.buildText(
                        'Soundscapes',
                        textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      for (final entry
                          in AmbientSoundscapeCatalog.entries) ...[
                        _AmbientTrackTile(
                          entry: entry,
                          owned: _owned.contains(entry.id),
                          selected: _isSelected(entry.id),
                          channelSettings: _channelSettings![entry.channel]!,
                          textStyle: textStyle,
                          primary: primary,
                          secondary: secondary,
                          onUnlock: () => _unlock(entry),
                          onSelect: () => unawaited(_selectTrack(entry.id)),
                          onPreview: () => _preview(entry.channel),
                          onVolumeChanged: (settings) =>
                              _persistChannel(entry.channel, settings),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _AmbientTrackTile extends StatelessWidget {
  const _AmbientTrackTile({
    required this.entry,
    required this.owned,
    required this.selected,
    required this.channelSettings,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.onUnlock,
    required this.onSelect,
    required this.onPreview,
    required this.onVolumeChanged,
  });

  final AmbientCatalogEntry entry;
  final bool owned;
  final bool selected;
  final SoundChannelSettings channelSettings;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final VoidCallback onUnlock;
  final VoidCallback onSelect;
  final VoidCallback onPreview;
  final ValueChanged<SoundChannelSettings> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final priceLabel = entry.isFree ? 'Free' : '${entry.pointCost} pts';
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.12)
          : secondary.withValues(alpha: 0.0),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitleActions(
              title: entry.label,
              titleStyle: textStyle.copyWith(fontWeight: FontWeight.w600),
              actions: [
                Text(
                  owned ? (selected ? 'Selected' : priceLabel) : priceLabel,
                  style: textStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onPreview,
                  child: const Text('Preview'),
                ),
                if (!owned)
                  FilledButton(
                    onPressed: onUnlock,
                    child: Text(entry.isFree ? 'Unlock' : 'Buy'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: selected ? null : onSelect,
                    child: Text(selected ? 'In use' : 'Use'),
                  ),
              ],
            ),
            if (owned) ...[
              const SizedBox(height: 8),
              Text(
                'Track volume: ${channelSettings.volumePercent}%',
                style: textStyle.copyWith(fontSize: 12),
              ),
              Slider(
                value: channelSettings.volumePercent.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (value) {
                  onVolumeChanged(
                    channelSettings.copyWith(volumePercent: value.round()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
