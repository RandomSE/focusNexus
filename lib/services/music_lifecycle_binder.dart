import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';

/// Stops ambient + feature BGM when the app is backgrounded; resumes on return.
class MusicLifecycleBinder extends ConsumerStatefulWidget {
  const MusicLifecycleBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MusicLifecycleBinder> createState() =>
      _MusicLifecycleBinderState();
}

class _MusicLifecycleBinderState extends ConsumerState<MusicLifecycleBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sounds = ref.read(soundServiceProvider);
    final repo = ref.read(appRepositoriesProvider).ambientSoundscapes;
    final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
    // Only [paused] (home / app switch). Do not use [inactive]: it fires during
    // in-app transitions and was resurrecting ambient under feature BGM.
    if (state == AppLifecycleState.paused) {
      unawaited(sounds.pauseAllMusicForAppBackground());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(() async {
        await sounds.resumeAfterAppForeground();
        // If feature BGM did not resume, restore section ambient.
        if (!sounds.hasActiveFeatureMusic) {
          await coordinator.resume(repo: repo, sounds: sounds);
        }
      }());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
