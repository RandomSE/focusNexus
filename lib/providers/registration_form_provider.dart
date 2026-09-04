import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_form_provider.g.dart';

class RegistrationFormState {
  const RegistrationFormState({
    this.frequency = NotificationPreferenceOptions.defaultFrequency,
    this.notificationStyle = NotificationPreferenceOptions.defaultStyle,
    this.rewardTypes = const [],
    this.eulaAccepted = false,
    this.ageConfirmed = false,
    this.username = '',
  });

  final String? frequency;
  final String? notificationStyle;
  final List<String> rewardTypes;
  final bool eulaAccepted;
  final bool ageConfirmed;
  final String username;

  bool get requiresNotificationStyle =>
      frequency != null &&
      !NotificationPreferenceOptions.isDisabled(frequency);

  /// Frequency + at least one reward type + EULA + 13+ affirmation.
  bool get canContinue {
    final hasFrequency = frequency != null;
    final hasReward = rewardTypes.isNotEmpty;
    return hasFrequency && hasReward && eulaAccepted && ageConfirmed;
  }

  /// Dynamic blocker copy for missing required fields only.
  String get missingRequirementsMessage {
    final missing = <String>[];
    if (frequency == null) {
      missing.add('a notification frequency');
    }
    if (rewardTypes.isEmpty) {
      missing.add('at least one reward type');
    }
    if (!eulaAccepted) {
      missing.add('EULA acceptance');
    }
    if (!ageConfirmed) {
      missing.add('confirmation that you are 13 or older');
    }
    if (missing.isEmpty) return '';
    if (missing.length == 1) {
      return '* Choose ${missing.single} to continue.';
    }
    if (missing.length == 2) {
      return '* Choose ${missing[0]} and ${missing[1]} to continue.';
    }
    final head = missing.sublist(0, missing.length - 1).join(', ');
    return '* Choose $head, and ${missing.last} to continue.';
  }

  /// User-facing copy when Continue is pressed but [canContinue] is false.
  String get continueBlockedFeedbackMessage =>
      missingRequirementsMessage.replaceFirst(RegExp(r'^\* '), '');

  RegistrationFormState copyWith({
    String? frequency,
    String? notificationStyle,
    List<String>? rewardTypes,
    bool? eulaAccepted,
    bool? ageConfirmed,
    String? username,
    bool clearNotificationStyle = false,
    bool clearFrequency = false,
    bool clearUsername = false,
  }) {
    return RegistrationFormState(
      frequency: clearFrequency ? null : (frequency ?? this.frequency),
      notificationStyle: clearNotificationStyle
          ? null
          : (notificationStyle ?? this.notificationStyle),
      rewardTypes: rewardTypes ?? this.rewardTypes,
      eulaAccepted: eulaAccepted ?? this.eulaAccepted,
      ageConfirmed: ageConfirmed ?? this.ageConfirmed,
      username: clearUsername ? '' : (username ?? this.username),
    );
  }
}

@riverpod
class RegistrationForm extends _$RegistrationForm {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFrequency(String? value) {
    final clearStyle = NotificationPreferenceOptions.isDisabled(value);
    state = state.copyWith(
      frequency: value,
      clearFrequency: value == null,
      clearNotificationStyle: clearStyle,
    );
  }

  void setNotificationStyle(String? value) {
    state = state.copyWith(notificationStyle: value);
  }

  void setRewardTypes(List<String> values) {
    state = state.copyWith(rewardTypes: values);
  }

  void setEulaAccepted(bool value) {
    state = state.copyWith(eulaAccepted: value);
  }

  void setAgeConfirmed(bool value) {
    state = state.copyWith(ageConfirmed: value);
  }

  void setUsername(String value) {
    state = state.copyWith(username: value);
  }
}
