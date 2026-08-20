import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/registration_form_provider.dart';

void main() {
  test('defaults Medium frequency and Vibrant style', () {
    const form = RegistrationFormState();
    expect(form.frequency, 'Medium');
    expect(form.notificationStyle, 'Vibrant');
    expect(form.rewardTypes, isEmpty);
    expect(form.eulaAccepted, isFalse);
    expect(form.ageConfirmed, isFalse);
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose at least one reward type, EULA acceptance, and confirmation that you are 13 or older to continue.',
    );
  });

  test('style alone does not block continue when EULA and age accepted', () {
    const form = RegistrationFormState(
      frequency: 'Medium',
      notificationStyle: null,
      rewardTypes: ['Mini-games'],
      eulaAccepted: true,
      ageConfirmed: true,
    );
    expect(form.canContinue, isTrue);
    expect(form.missingRequirementsMessage, isEmpty);
  });

  test('rewards without EULA cannot continue', () {
    const form = RegistrationFormState(
      frequency: 'Medium',
      rewardTypes: ['Mini-games'],
      eulaAccepted: false,
      ageConfirmed: true,
    );
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose EULA acceptance to continue.',
    );
  });

  test('EULA without age confirmation cannot continue', () {
    const form = RegistrationFormState(
      frequency: 'Medium',
      rewardTypes: ['Mini-games'],
      eulaAccepted: true,
      ageConfirmed: false,
    );
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose confirmation that you are 13 or older to continue.',
    );
  });

  test('missing message updates when frequency cleared', () {
    const form = RegistrationFormState(
      frequency: null,
      rewardTypes: ['Mini-games'],
      eulaAccepted: true,
      ageConfirmed: true,
    );
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose a notification frequency to continue.',
    );
  });

  test('missing message lists all four gaps', () {
    const form = RegistrationFormState(
      frequency: null,
      rewardTypes: [],
      eulaAccepted: false,
      ageConfirmed: false,
    );
    expect(
      form.missingRequirementsMessage,
      '* Choose a notification frequency, at least one reward type, EULA acceptance, and confirmation that you are 13 or older to continue.',
    );
  });

  test('continueBlockedFeedbackMessage strips leading asterisk for snackbars', () {
    const form = RegistrationFormState(
      frequency: 'Medium',
      rewardTypes: [],
      eulaAccepted: false,
      ageConfirmed: false,
    );
    expect(
      form.continueBlockedFeedbackMessage,
      'Choose at least one reward type, EULA acceptance, and confirmation that you are 13 or older to continue.',
    );
    expect(form.continueBlockedFeedbackMessage, isNot(startsWith('*')));
  });
}
