import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:focusNexus/assistant/assistant_message_codec.dart';

part 'screen_ui_providers.g.dart';

@riverpod
class DashboardPointsGeneration extends _$DashboardPointsGeneration {
  @override
  int build() => 0;

  void bump() => state++;
}

@riverpod
class SettingsNotificationsAllowed extends _$SettingsNotificationsAllowed {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

@riverpod
class SettingsDeletingAccount extends _$SettingsDeletingAccount {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

@riverpod
class OnboardingPageIndex extends _$OnboardingPageIndex {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

@riverpod
class AiChatMessages extends _$AiChatMessages {
  @override
  List<Map<String, String>> build() => [];

  void replace(List<Map<String, String>> messages) =>
      state = sanitizeAssistantMessages(messages);

  void append(Map<String, String> message) =>
      state = [...state, sanitizeAssistantMessage(message)];
}

/// Session flag: user accepted the AI chat legal notice for this app run.
@riverpod
class AiChatDisclaimerAccepted extends _$AiChatDisclaimerAccepted {
  @override
  bool build() => false;

  void accept() => state = true;
}

@riverpod
class SoundVolumeLive extends _$SoundVolumeLive {
  @override
  int? build() => null;

  void set(int? value) => state = value;
}

@riverpod
class AchievementDetailDisabled extends _$AchievementDetailDisabled {
  @override
  bool build(String achievementId) => false;

  void disable() => state = true;
}

@riverpod
class AchievementDetailRefresh extends _$AchievementDetailRefresh {
  @override
  bool build(String achievementId) => false;

  void markRefresh() => state = true;
}
