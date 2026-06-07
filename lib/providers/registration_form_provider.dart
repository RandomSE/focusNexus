import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_form_provider.g.dart';

class RegistrationFormState {
  const RegistrationFormState({
    this.frequency,
    this.notificationStyle,
    this.rewardType,
  });

  final String? frequency;
  final String? notificationStyle;
  final String? rewardType;

  bool get requiresNotificationStyle =>
      frequency != null && frequency != 'No notifications';

  bool get canContinue {
    final hasFrequency = frequency != null;
    final hasReward = rewardType != null;
    final hasStyle = !requiresNotificationStyle || notificationStyle != null;
    return hasFrequency && hasReward && hasStyle;
  }

  RegistrationFormState copyWith({
    String? frequency,
    String? notificationStyle,
    String? rewardType,
    bool clearNotificationStyle = false,
  }) {
    return RegistrationFormState(
      frequency: frequency ?? this.frequency,
      notificationStyle: clearNotificationStyle
          ? null
          : (notificationStyle ?? this.notificationStyle),
      rewardType: rewardType ?? this.rewardType,
    );
  }
}

@riverpod
class RegistrationForm extends _$RegistrationForm {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFrequency(String? value) {
    if (value == 'No notifications') {
      state = state.copyWith(
        frequency: value,
        notificationStyle: 'Minimal',
      );
    } else {
      state = state.copyWith(
        frequency: value,
        clearNotificationStyle: true,
      );
    }
  }

  void setNotificationStyle(String? value) {
    state = state.copyWith(notificationStyle: value);
  }

  void setRewardType(String? value) {
    state = state.copyWith(rewardType: value);
  }
}
