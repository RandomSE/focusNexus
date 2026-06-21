import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/ai_chat_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/notifier.dart';

part 'app_services_provider.g.dart';

/// Achievement facade with injected storage and points.
@Riverpod(keepAlive: true)
AchievementService achievementService(Ref ref) {
  final repos = ref.watch(appRepositoriesProvider);
  return AchievementService(
    storage: repos.storage,
    repository: repos.achievements,
    pointsRepository: repos.points,
    soundService: ref.watch(soundServiceProvider),
  );
}

/// Sound playback with injected storage.
@Riverpod(keepAlive: true)
SoundService soundService(Ref ref) {
  return SoundService(ref.watch(appRepositoriesProvider).storage);
}

/// AI chat client (override in tests with a fake implementation).
@Riverpod(keepAlive: true)
AiChatService aiChatService(Ref ref) => const GroqAiChatService();

/// Binds [GoalNotifier] to scoped storage (replaces static storage assignment).
@Riverpod(keepAlive: true)
void goalNotifierWiring(Ref ref) {
  GoalNotifier.bindStorage(ref.watch(appRepositoriesProvider).storage);
}

/// Binds [AchievementTrackingVariables] to scoped storage.
@Riverpod(keepAlive: true)
void achievementTrackingWiring(Ref ref) {
  AchievementTrackingVariables.bindStorage(ref.watch(appRepositoriesProvider).storage);
}

/// Ensures injected app services are constructed for this [ProviderScope].
@Riverpod(keepAlive: true)
void appServicesWired(Ref ref) {
  ref.watch(achievementServiceProvider);
  ref.watch(soundServiceProvider);
  ref.watch(goalNotifierWiringProvider);
  ref.watch(achievementTrackingWiringProvider);
}
