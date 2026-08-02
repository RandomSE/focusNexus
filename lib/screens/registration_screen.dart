// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/registration_form_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';
import 'package:focusNexus/widgets/reward_types_multi_select.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/utils/theme_styles.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  static const notificationFrequencies = [
    'Low',
    'Medium',
    'High',
    'No notifications',
  ];
  static const notificationStyles = ['Vibrant', 'Minimal', 'Animated'];

  Future<void> _saveAndContinue() async {
    final form = ref.read(registrationFormProvider);
    if (form.rewardTypes.isEmpty) return;
    final settings = ref.read(appSettingsProvider.notifier).service;
    await settings.completeRegistration(
      notificationFrequency: form.frequency!,
      notificationStyle: form.notificationStyle ?? 'Vibrant',
      rewardTypes: form.rewardTypes,
    );
    if (!mounted) return;
    ref.resetToRoute(context, AppRoute.onboard);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(registrationFormProvider);
    final formNotifier = ref.read(registrationFormProvider.notifier);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final labelStyle = controlTextStyle(bundle.textStyle);
        final primaryColor = bundle.primaryColor;
        final secondaryColor = bundle.secondaryColor;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondaryColor,
            appBar: AppBar(
              title: Text('Set up FocusNexus', style: labelStyle),
              backgroundColor: secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor( primaryColor),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Choose how FocusNexus should notify and reward you.',
                    style: labelStyle.copyWith(fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 20),
                  CommonUtils.buildDropdownButtonFormField(
                    'Notification Frequency',
                    form.frequency,
                    notificationFrequencies,
                    labelStyle,
                    secondaryColor,
                    (value) => formNotifier.setFrequency(value),
                    validator: (value) =>
                        value == null ? 'Select frequency' : null,
                  ),
                  if (form.requiresNotificationStyle)
                    CommonUtils.buildDropdownButtonFormField(
                      'Notification Style',
                      form.notificationStyle,
                      notificationStyles,
                      labelStyle,
                      secondaryColor,
                      (value) => formNotifier.setNotificationStyle(value),
                    ),
                  RewardTypesMultiSelect(
                    selected: form.rewardTypes,
                    onChanged: formNotifier.setRewardTypes,
                    textStyle: labelStyle,
                    activeColor: primaryColor,
                    title: 'Reward types',
                    subtitle: 'Choose one or more. At least one is required.',
                  ),
                  const SizedBox(height: 24),
                  if (!form.canContinue)
                    Text(
                      form.missingRequirementsMessage,
                      style: labelStyle.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  if (!form.canContinue) const SizedBox(height: 8),
                  CommonUtils.buildElevatedButton(
                    'Continue',
                    primaryColor,
                    secondaryColor,
                    labelStyle,
                    12,
                    8,
                    form.canContinue
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              await _saveAndContinue();
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Optional - appearance',
                    style: labelStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can change these later in Settings.',
                    style: labelStyle.copyWith(fontWeight: FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  AppearanceSettingsSection(
                    bundle: bundle,
                    showBottomDivider: false,
                    showDyslexiaSwitch: true,
                    showHighContrastSwitch: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
