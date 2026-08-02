import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/registration_form_provider.dart';

void main() {
  test('defaults Medium frequency and Vibrant style', () {
    const form = RegistrationFormState();
    expect(form.frequency, 'Medium');
    expect(form.notificationStyle, 'Vibrant');
    expect(form.rewardTypes, isEmpty);
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose at least one reward type to continue.',
    );
  });

  test('style alone does not block continue', () {
    const form = RegistrationFormState(
      frequency: 'Medium',
      notificationStyle: null,
      rewardTypes: ['Mini-games'],
    );
    expect(form.canContinue, isTrue);
    expect(form.missingRequirementsMessage, isEmpty);
  });

  test('missing message updates when frequency cleared', () {
    const form = RegistrationFormState(
      frequency: null,
      rewardTypes: ['Mini-games'],
    );
    expect(form.canContinue, isFalse);
    expect(
      form.missingRequirementsMessage,
      '* Choose a notification frequency to continue.',
    );
  });

  test('missing message lists both gaps', () {
    const form = RegistrationFormState(
      frequency: null,
      rewardTypes: [],
    );
    expect(
      form.missingRequirementsMessage,
      '* Choose a notification frequency and at least one reward type to continue.',
    );
  });
}
