import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'achievement_ready_toast_provider.g.dart';

/// Ephemeral toast when an achievement becomes completable (100%).
class AchievementReadyToast {
  const AchievementReadyToast({
    required this.title,
    required this.durationMs,
  });

  final String title;
  final int durationMs;
}

@Riverpod(keepAlive: true)
class AchievementReadyToastQueue extends _$AchievementReadyToastQueue {
  final _random = Random();

  @override
  List<AchievementReadyToast> build() => const [];

  void enqueueTitles(Iterable<String> titles) {
    final next = [
      ...state,
      ...titles.map(
        (title) => AchievementReadyToast(
          title: title,
          durationMs: 2000 + _random.nextInt(1001),
        ),
      ),
    ];
    state = next;
  }

  void consumeHead() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }
}
