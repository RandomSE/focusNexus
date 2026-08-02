import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_form_provider.g.dart';

class RegistrationFormState {
  const RegistrationFormState({
    this.frequency = 'Medium',
    this.notificationStyle = 'Vibrant',
    this.rewardTypes = const [],
  });

  final String? frequency;
  final String? notificationStyle;
  final List<String> rewardTypes;

  bool get requiresNotificationStyle =>
      frequency != null && frequency != 'No notifications';

  /// Frequency + at least one reward type. Style is optional (defaults Vibrant).
  bool get canContinue {
    final hasFrequency = frequency != null;
    final hasReward = rewardTypes.isNotEmpty;
    return hasFrequency && hasReward;
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
    if (missing.isEmpty) return '';
    if (missing.length == 1) {
      return '* Choose ${missing.single} to continue.';
    }
    return '* Choose ${missing[0]} and ${missing[1]} to continue.';
  }

  RegistrationFormState copyWith({
    String? frequency,
    String? notificationStyle,
    List<String>? rewardTypes,
    bool clearNotificationStyle = false,
    bool clearFrequency = false,
  }) {
    return RegistrationFormState(
      frequency: clearFrequency ? null : (frequency ?? this.frequency),
      notificationStyle: clearNotificationStyle
          ? null
          : (notificationStyle ?? this.notificationStyle),
      rewardTypes: rewardTypes ?? this.rewardTypes,
    );
  }
}

@riverpod
class RegistrationForm extends _$RegistrationForm {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFrequency(String? value) {
    final clearStyle = value == 'No notifications';
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
}
