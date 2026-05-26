import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';
import '../utils/screen_theme.dart';
import '../widgets/appearance_settings_section.dart';
import '../widgets/settings_themed_builder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _settings = AppRepositories.instance.settings;
  bool _notificationsAllowed = false;
  bool _isDeletingAccount = false;

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

  bool _permissionCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _refreshNotificationPermission() async {
    final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
    if (mounted) setState(() => _notificationsAllowed = allowed);
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
    await GoalNotifier.refreshSchedulesForFrequencyChange(
      oldFrequency: oldFrequency,
      newFrequency: newFrequency,
    );
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
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : secondaryColor,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? secondaryColor
                  : primaryColor,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : secondaryColor,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
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
    if (!_permissionCheckStarted) {
      _permissionCheckStarted = true;
      _refreshNotificationPermission();
    }

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final primaryColor = bundle.primaryColor;
        final secondaryColor = bundle.secondaryColor;
        final textStyle = bundle.textStyle;

        return PopScope<Object?>(
          canPop: !_isDeletingAccount,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (_isDeletingAccount) return;
            if (didPop) {
              Future.microtask(() {
                Navigator.of(context).pushReplacementNamed('dashboard');
              });
            }
          },
          child: Stack(
            children: [
              Theme(
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
                        AppearanceSettingsSection(bundle: bundle),
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
                            'No notifications')
                          CommonUtils.buildDropdownButtonFormField(
                            'Notification Style',
                            _settings.notificationStyle,
                            _notificationStyles,
                            textStyle,
                            secondaryColor,
                            (val) => _settings.setNotificationStyle(
                              val ?? 'Minimal',
                            ),
                          )
                        else
                          CommonUtils.buildText(
                            'Notifications are disabled. Settings related to them will not be shown unless re-enabled.',
                            textStyle,
                          ),
                        const Divider(),
                        CommonUtils.buildSwitchListTile(
                          'Dyslexia-friendly Font',
                          textStyle,
                          _settings.useDyslexiaFont,
                          _settings.setUseDyslexiaFont,
                          primaryColor,
                        ),
                        CommonUtils.buildSwitchListTile(
                          'High Contrast Mode',
                          textStyle,
                          _settings.highContrastMode,
                          _settings.setHighContrastMode,
                          primaryColor,
                        ),
                        if (_settings.notificationFrequency !=
                            'No notifications') ...[
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
                                        builder:
                                            (context, child) => Theme(
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
                                        await updateDailyAffirmations(
                                          formatted,
                                        );
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
                          if (!_notificationsAllowed)
                            CommonUtils.buildSwitchListTile(
                              'Would you like to enable notifications?',
                              textStyle,
                              _notificationsAllowed,
                              (val) async {
                                await GoalNotifier.requestNotificationPermission();
                                final allowed =
                                    await GoalNotifier.checkNotificationsPermissionsGranted();
                                if (mounted) {
                                  setState(
                                    () => _notificationsAllowed = allowed,
                                  );
                                }
                              },
                              primaryColor,
                            ),
                        ],
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
                            onChanged:
                                (val) =>
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
                          _isDeletingAccount
                              ? null
                              : () => _confirmAndDeleteAccount(
                                context,
                                primaryColor,
                                secondaryColor,
                                textStyle,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isDeletingAccount)
                ModalBarrier(
                  color: Colors.black.withValues(alpha: 0.45),
                  dismissible: false,
                ),
              if (_isDeletingAccount)
                Center(
                  child: Material(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deleting account…',
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeleteAccount(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
    TextStyle textStyle,
  ) async {
    final firstConfirmation = await CommonUtils.showInteractableAlertDialog(
      context,
      'Delete Account?',
      'Would you like to delete your account and reset all settings?',
      textStyle,
      secondaryColor,
      barrierDismissible: false,
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
    if (firstConfirmation != true || !mounted) return;

    final finalConfirmation = await CommonUtils.showInteractableAlertDialog(
      context,
      'Delete Account?',
      'Would you like to delete your account and reset all settings? This is permanent and cannot be reversed once done.',
      textStyle,
      secondaryColor,
      barrierDismissible: false,
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
    if (finalConfirmation != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await _settings.clearAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, 'auth', (_) => false);
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }
}
