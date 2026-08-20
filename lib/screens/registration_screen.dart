// lib/screens/registration_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/registration_form_provider.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart'
    show AppearanceSettingsSection, controlTextStyle;
import 'package:focusNexus/widgets/legal_links_section.dart';
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
  bool _busy = false;

  Future<void> _saveAndContinue() async {
    if (_busy) return;
    final form = ref.read(registrationFormProvider);
    if (!form.canContinue) return;
    setState(() => _busy = true);
    try {
      final settings = ref.read(appSettingsProvider.notifier).service;
      await settings.completeRegistration(
        notificationFrequency: form.frequency!,
        notificationStyle: form.notificationStyle ??
            NotificationPreferenceOptions.defaultStyle,
        rewardTypes: form.rewardTypes,
        acceptEula: true,
      );
      if (!mounted) return;
      ref.resetToRoute(context, AppRoute.onboard);
    } catch (_) {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        'Could not complete setup. Please try again.',
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        4000,
        16,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _onContinuePressed(TextStyle labelStyle) {
    if (_busy) return;
    final form = ref.read(registrationFormProvider);
    if (!form.canContinue) {
      CommonUtils.showSnackBar(
        context,
        form.continueBlockedFeedbackMessage,
        labelStyle.copyWith(fontWeight: FontWeight.normal),
        4000,
        16,
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      unawaited(_saveAndContinue());
    }
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
        final linkStyle = labelStyle.copyWith(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          color: primaryColor,
        );
        final canTapContinue = form.canContinue && !_busy;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondaryColor,
            appBar: AppBar(
              title: Text('Set up FocusNexus', style: labelStyle),
              backgroundColor: secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(primaryColor),
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
                    NotificationPreferenceOptions.frequencies,
                    labelStyle,
                    secondaryColor,
                    (value) {
                      if (_busy) return;
                      formNotifier.setFrequency(value);
                    },
                    validator: (value) =>
                        value == null ? 'Select frequency' : null,
                  ),
                  if (form.requiresNotificationStyle)
                    CommonUtils.buildDropdownButtonFormField(
                      'Notification Style',
                      form.notificationStyle,
                      NotificationPreferenceOptions.styles,
                      labelStyle,
                      secondaryColor,
                      (value) {
                        if (_busy) return;
                        formNotifier.setNotificationStyle(value);
                      },
                    ),
                  RewardTypesMultiSelect(
                    selected: form.rewardTypes,
                    onChanged: (values) {
                      if (_busy) return;
                      formNotifier.setRewardTypes(values);
                    },
                    textStyle: labelStyle,
                    activeColor: primaryColor,
                    title: 'Reward types',
                    subtitle: 'Choose one or more. At least one is required.',
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: form.eulaAccepted,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I have read and agree to the End User License '
                          'Agreement, Privacy Policy, and Intellectual Property notice:',
                          style: labelStyle.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LegalLinksSection.textLinks(
                          linkStyle: linkStyle,
                          includeEula: true,
                        ),
                      ],
                    ),
                    onChanged: _busy
                        ? null
                        : (value) =>
                            formNotifier.setEulaAccepted(value ?? false),
                  ),
                  CheckboxListTile(
                    value: form.ageConfirmed,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I confirm I am 13 or older',
                      style: labelStyle.copyWith(fontWeight: FontWeight.normal),
                    ),
                    onChanged: _busy
                        ? null
                        : (value) =>
                            formNotifier.setAgeConfirmed(value ?? false),
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
                  Opacity(
                    opacity: canTapContinue ? 1.0 : 0.55,
                    child: CommonUtils.buildElevatedButton(
                      'Continue',
                      primaryColor,
                      secondaryColor,
                      labelStyle,
                      12,
                      8,
                      canTapContinue
                          ? () => _onContinuePressed(labelStyle)
                          : null,
                    ),
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
