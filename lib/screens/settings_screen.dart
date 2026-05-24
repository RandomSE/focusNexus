import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/settings/app_settings.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';
import '../utils/screen_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _settings = AppRepositories.instance.settings;
  bool _permissionsChecked = false;
  bool _notificationsAllowed = false;

  static const _userThemes = ['light', 'dark'];
  static const _notificationFrequencies = [
    'Low',
    'Medium',
    'High',
    'No notifications',
  ];
  static const _notificationStyles = ['Minimal', 'Vibrant', 'Animated'];
  static const _rewardTypes = [
    'Mini-games',
    'Progressive visuals',
    'Customization',
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
      if (mounted) setState(() => _notificationsAllowed = allowed);
    }
  }

  Future<void> _loadPermissions() async {
    final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
    if (mounted) {
      setState(() {
        _notificationsAllowed = allowed;
        _permissionsChecked = true;
      });
    }
  }

  Future<void> setAndCheckDailyAffirmations(bool value) async {
    await _settings.setDailyAffirmations(value);
    if (value) {
      await updateDailyAffirmations(_settings.dailyAffirmationsTime);
    } else {
      await GoalNotifier.cancelDailyAffirmationsNotification();
    }
  }

  Future<void> updateDailyAffirmations(String time) async {
    await _settings.setDailyAffirmationsTime(time);
    await GoalNotifier.startDailyAffirmations(time);
  }

  Future<void> updateNotificationFrequency(
    String oldFrequency,
    String newFrequency,
  ) async {
    await _settings.setNotificationFrequency(newFrequency);
    if (oldFrequency == 'No notifications' &&
        newFrequency != 'No notifications') {
      await GoalNotifier.requestNotificationPermission();
    }
    if (oldFrequency != 'No notifications' &&
        newFrequency == 'No notifications') {
      await GoalNotifier.cancelAllGoalNotifications();
    }
  }

  Future<void> setPauseGoalsScreen(bool value) async {
    await _settings.setPauseGoals(value);
    if (value) {
      await GoalNotifier.cancelAllGoalNotifications();
    }
  }

  ThemeData buildTimePickerTheme(
    Color primaryColor,
    Color secondaryColor,
    TextStyle textStyle,
  ) {
    return ThemeData(
      timePickerTheme: TimePickerThemeData(
        backgroundColor: secondaryColor,
        dialBackgroundColor: secondaryColor,
        dialHandColor: Colors.deepPurple,
        dialTextColor: primaryColor,
        entryModeIconColor: primaryColor,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : secondaryColor,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? secondaryColor
              : primaryColor,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : secondaryColor,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? secondaryColor
              : primaryColor,
        ),
        helpTextStyle: textStyle,
        hourMinuteTextStyle: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    return SettingsThemedBuilder(
      startupDelay: const Duration(milliseconds: 500),
      builder: (context, bundle) {
        final primaryColor = bundle.primaryColor;
        final secondaryColor = bundle.secondaryColor;
        final textStyle = bundle.textStyle;

        return PopScope<Object?>(
          canPop: true,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              Future.microtask(() {
                Navigator.of(context).pushReplacementNamed('dashboard');
              });
            }
          },
          child: Theme(
            data: bundle.themeData,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  'Settings',
                  style: TextStyle(
                    backgroundColor: secondaryColor,
                    color: primaryColor,
                  ),
                ),
                backgroundColor: secondaryColor,
                iconTheme: IconThemeData(color: primaryColor),
              ),
              backgroundColor: secondaryColor,
              body: Container(
                color: secondaryColor,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: secondaryColor,
                      child: CommonUtils.buildText(
                        'This is a live preview of your visual settings.',
                        textStyle,
                      ),
                    ),
                    const Divider(),
                    Container(
                      color: secondaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          CommonUtils.buildText(
                            'Font Size: ${_settings.userFontSize}',
                            textStyle,
                          ),
                          CommonUtils.buildIconButton(
                            '',
                            Icons.remove,
                            primaryColor,
                            () async {
                              if (_settings.userFontSize > 10) {
                                final next = _settings.userFontSize - 1;
                                await _settings.setUserFontSize(next);
                                await _settings.setThemeData(
                                  userFontSize: next,
                                );
                              }
                            },
                          ),
                          Text(
                            '${_settings.userFontSize.toInt()}',
                            style: textStyle,
                          ),
                          CommonUtils.buildIconButton(
                            '',
                            Icons.add,
                            primaryColor,
                            () async {
                              if (_settings.userFontSize < 24) {
                                final next = _settings.userFontSize + 1;
                                await _settings.setUserFontSize(next);
                                await _settings.setThemeData(
                                  userFontSize: next,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    CommonUtils.buildDropdownButtonFormField(
                      'Theme',
                      _settings.userTheme,
                      _userThemes,
                      textStyle,
                      secondaryColor,
                      (val) => _settings.setUserTheme(val ?? 'light'),
                    ),
                    CommonUtils.buildDropdownButtonFormField(
                      'Reward Type',
                      _settings.rewardType,
                      _rewardTypes,
                      textStyle,
                      secondaryColor,
                      (val) => _settings.setRewardType(val ?? 'Mini-games'),
                    ),
                    CommonUtils.buildDropdownButtonFormField(
                      'Notification Frequency',
                      _settings.notificationFrequency,
                      _notificationFrequencies,
                      textStyle,
                      secondaryColor,
                      (val) => updateNotificationFrequency(
                        _settings.notificationFrequency,
                        val ?? 'Medium',
                      ),
                    ),
                    if (_settings.notificationFrequency !=
                        'No notifications') ...[
                      CommonUtils.buildDropdownButtonFormField(
                        'Notification Style',
                        _settings.notificationStyle,
                        _notificationStyles,
                        textStyle,
                        secondaryColor,
                        (val) => _settings.setNotificationStyle(
                          val ?? 'Minimal',
                        ),
                      ),
                      CommonUtils.buildSwitchListTile(
                        'Daily Affirmations',
                        textStyle,
                        _settings.dailyAffirmations,
                        setAndCheckDailyAffirmations,
                        primaryColor,
                      ),
                      if (_settings.dailyAffirmations) ...[
                        Row(
                          children: [
                            Expanded(
                              child: CommonUtils.buildElevatedButton(
                                _settings.dailyAffirmationsTime.isNotEmpty
                                    ? 'Selected daily affirmations time: ${_settings.dailyAffirmationsTime} click me to change'
                                    : 'Choose Time',
                                primaryColor,
                                secondaryColor,
                                textStyle,
                                4,
                                0,
                                () async {
                                  final selected = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    initialEntryMode:
                                        TimePickerEntryMode.dial,
                                    builder: (context, child) => Theme(
                                      data: buildTimePickerTheme(
                                        primaryColor,
                                        secondaryColor,
                                        textStyle,
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (selected != null) {
                                    final formatted =
                                        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                                    await updateDailyAffirmations(formatted);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ],
                      CommonUtils.buildSwitchListTile(
                        'AI Encouragement',
                        textStyle,
                        _settings.aiEncouragement,
                        _settings.setAiEncouragement,
                        primaryColor,
                      ),
                      if (!_notificationsAllowed) ...[
                        CommonUtils.buildSwitchListTile(
                          'Would you like to enable notifications?',
                          textStyle,
                          _notificationsAllowed,
                          (val) async {
                            await GoalNotifier.requestNotificationPermission();
                            final allowed = await GoalNotifier
                                .checkNotificationsPermissionsGranted();
                            if (mounted) {
                              setState(() => _notificationsAllowed = allowed);
                            }
                          },
                          primaryColor,
                        ),
                      ],
                    ] else ...[
                      CommonUtils.buildText(
                        'Notifications are disabled. Settings related to them will not be shown unless re-enabled.',
                        textStyle,
                      ),
                    ],
                    CommonUtils.buildSwitchListTile(
                      'Remember Me',
                      textStyle,
                      _settings.rememberMe,
                      _settings.setRememberMe,
                      primaryColor,
                    ),
                    CommonUtils.buildSwitchListTile(
                      'High Contrast Mode',
                      textStyle,
                      _settings.highContrastMode,
                      _settings.setHighContrastMode,
                      primaryColor,
                    ),
                    CommonUtils.buildSwitchListTile(
                      'Dyslexia-friendly Font',
                      textStyle,
                      _settings.useDyslexiaFont,
                      _settings.setUseDyslexiaFont,
                      primaryColor,
                    ),
                    CommonUtils.buildSwitchListTile(
                      'Pause Goals',
                      textStyle,
                      _settings.pauseGoals,
                      setPauseGoalsScreen,
                      primaryColor,
                    ),
                    CommonUtils.buildSwitchListTile(
                      'Sound',
                      textStyle,
                      _settings.soundEnabled,
                      _settings.setSoundEnabled,
                      primaryColor,
                    ),
                    if (_settings.soundEnabled) ...[
                      Slider(
                        value: _settings.soundVolume,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: _settings.soundVolume.toString(),
                        onChanged: (val) =>
                            _settings.setSoundVolume(val.toDouble()),
                      ),
                    ],
                    const Divider(),
                    CommonUtils.buildElevatedButton(
                      'Clear preferences and delete account',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      () async {
                        final firstConfirmation =
                            await CommonUtils.showInteractableAlertDialog(
                          context,
                          'Delete Account?',
                          'Would you like to delete your account and reset all settings?',
                          textStyle,
                          secondaryColor,
                          actions: [
                            CommonUtils.buildElevatedButton(
                              'No',
                              primaryColor,
                              secondaryColor,
                              textStyle,
                              0,
                              0,
                              () => Navigator.pop(context, false),
                            ),
                            CommonUtils.buildElevatedButton(
                              'Yes',
                              primaryColor,
                              secondaryColor,
                              textStyle,
                              0,
                              0,
                              () => Navigator.pop(context, true),
                            ),
                          ],
                        );
                        if (firstConfirmation == true) {
                          final finalConfirmation =
                              await CommonUtils.showInteractableAlertDialog(
                            context,
                            'Delete Account?',
                            'Would you like to delete your account and reset all settings? This is permanent and cannot be reversed once done.',
                            textStyle,
                            secondaryColor,
                            actions: [
                              CommonUtils.buildElevatedButton(
                                'No',
                                primaryColor,
                                secondaryColor,
                                textStyle,
                                0,
                                0,
                                () => Navigator.pop(context, false),
                              ),
                              CommonUtils.buildElevatedButton(
                                'Yes, I would like to permanently delete my account.',
                                primaryColor,
                                secondaryColor,
                                textStyle,
                                0,
                                0,
                                () => Navigator.pop(context, true),
                              ),
                            ],
                          );
                          if (finalConfirmation == true) {
                            await _settings.clearAll();
                            if (!mounted) return;
                            Navigator.pushReplacementNamed(context, 'auth');
                          }
                        }
                      },
                    ),
                    CommonUtils.buildElevatedButton(
                      'Log Out',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      () async {
                        await _settings.setRememberMe(false);
                        await _settings.setLoggedIn(false);
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, 'auth');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
