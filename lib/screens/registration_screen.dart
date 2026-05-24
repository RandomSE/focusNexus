// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';
import '../widgets/appearance_settings_section.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _settings = AppRepositories.instance.settings;
  final _formKey = GlobalKey<FormState>();

  String? _notificationStyle;
  String? _frequency;
  String? _rewardType;

  final notificationFrequencies = [
    'Low',
    'Medium',
    'High',
    'No notifications',
  ];
  final notificationStyles = ['Vibrant', 'Minimal', 'Animated'];
  final rewardTypes = [
    'Mini-games',
    'Progressive visuals',
    'Customization',
  ];

  bool get _requiresNotificationStyle =>
      _frequency != null && _frequency != 'No notifications';

  bool get _canContinue {
    final hasFrequency = _frequency != null;
    final hasReward = _rewardType != null;
    final hasStyle = !_requiresNotificationStyle || _notificationStyle != null;
    return hasFrequency && hasReward && hasStyle;
  }

  Future<void> _saveAndContinue() async {
    await _settings.completeRegistration(
      notificationFrequency: _frequency!,
      notificationStyle: _notificationStyle ?? 'Minimal',
      rewardType: _rewardType!,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'onboard');
  }

  @override
  Widget build(BuildContext context) {
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
              iconTheme: IconThemeData(color: primaryColor),
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
                    _frequency,
                    notificationFrequencies,
                    labelStyle,
                    secondaryColor,
                    (value) {
                      setState(() {
                        _frequency = value;
                        if (value == 'No notifications') {
                          _notificationStyle = 'Minimal';
                        } else {
                          _notificationStyle = null;
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Select frequency' : null,
                  ),
                  if (_requiresNotificationStyle)
                    CommonUtils.buildDropdownButtonFormField(
                      'Notification Style',
                      _notificationStyle,
                      notificationStyles,
                      labelStyle,
                      secondaryColor,
                      (value) => setState(() => _notificationStyle = value),
                      validator: (value) =>
                          value == null ? 'Select notification style' : null,
                    ),
                  CommonUtils.buildDropdownButtonFormField(
                    'Reward type',
                    _rewardType,
                    rewardTypes,
                    labelStyle,
                    secondaryColor,
                    (value) => setState(() => _rewardType = value),
                    validator: (value) =>
                        value == null ? 'Select reward type' : null,
                  ),
                  const SizedBox(height: 24),
                  if (!_canContinue)
                    Text(
                      '* Complete required fields to continue.',
                      style: labelStyle.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  if (!_canContinue) const SizedBox(height: 8),
                  CommonUtils.buildElevatedButton(
                    'Continue',
                    primaryColor,
                    secondaryColor,
                    labelStyle,
                    12,
                    8,
                    _canContinue
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              await _saveAndContinue();
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Optional — appearance',
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
