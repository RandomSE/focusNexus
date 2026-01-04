import 'package:flutter/material.dart';
import 'package:focusNexus/utils/BaseState.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseState<SettingsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _affirmationTimeController =
      TextEditingController();
  late ThemeData _themeData;
  bool _themeLoaded = false;
  late String _rewardType;
  late String _notificationStyle;
  late String _notificationFrequency;
  late bool _notificationsAllowed;
  late String _dailyAffirmationsTime;
  List<String> userThemes = ['light', 'dark'];
  List<String> notificationFrequencies = [
    'Low',
    'Medium',
    'High',
    'No notifications',
  ];
  List<String> notificationStyles = ['Minimal', 'Vibrant', 'Animated'];
  final rewardTypes = ['Mini-games', 'Progressive visuals', 'Customization'];
  late bool _soundEnabled;
  late double _soundVolume;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _affirmationTimeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // App has returned from background — recheck permissions
      final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
      setState(() {
        _notificationsAllowed = allowed;
      });
    }
  }

  Future<void> _loadSettings() async {
    final storedSoundEnabled = await getBoolFromStorage('soundEnabled');
    final storedSoundVolume = await getStringFromStorage('soundVolume');
    final storedFrequency = await notificationFrequency;
    final storedStyle = await notificationStyle;
    final storedType = await rewardType;
    final notificationsAllowed =
        await GoalNotifier.checkNotificationsPermissionsGranted();
    final themeBundle = await initializeScreenTheme();
    final storedTime = await dailyAffirmationsTime;

    if (mounted) {
      setState(() {
        _rewardType = storedType;
        _notificationStyle = storedStyle;
        _notificationFrequency = storedFrequency;
        _notificationsAllowed = notificationsAllowed;
        _themeData = themeBundle.themeData;
        _themeLoaded = true;
        _dailyAffirmationsTime = storedTime;
        _soundEnabled = storedSoundEnabled;
        _soundVolume = double.parse(storedSoundVolume);
      });
    }
  }

  Future<void> setAndCheckDailyAffirmations(bool value) async {
    await setDailyAffirmations(value);

    if (value) {
      // enabled - schedule daily affirmations.
      final dailyAffirmationTime = await dailyAffirmationsTime;
      updateDailyAffirmations(dailyAffirmationTime);
    } else {
      // disabled - do not schedule daily affirmations.
      await GoalNotifier.cancelDailyAffirmationsNotification();
    }
  }

  Future<void> updateDailyAffirmations(String time) async {
    await setStringValue('dailyAffirmationsTime', time);
    await GoalNotifier.startDailyAffirmations(time);
    setState(() {
      _dailyAffirmationsTime = time;
    });
  }

  Future<void> updateNotificationFrequency(
    String oldFrequency,
    String newFrequency,
  ) async {
    await setNotificationFrequency(newFrequency);
    if (oldFrequency == 'No notifications' &&
        newFrequency != 'No notifications') {
      await GoalNotifier.requestNotificationPermission();
    }
    if (oldFrequency != 'No notifications' &&
        newFrequency == 'No notifications') {
      await GoalNotifier.cancelAllGoalNotifications();
    }
    if (mounted) {
      setState(() {
        _notificationFrequency = newFrequency;
      });
    }
  }

  Future<void> setPauseGoalsScreen(bool value) async {
    setPauseGoals(value);

    if (value == true) {
      await GoalNotifier.cancelAllGoalNotifications(); // pause - no need for notifications reminding them of deadlines.
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

  Future<void>setSoundVolumeLocal(double double) async {
    await setSoundVolume(double);
    setState(() => _soundVolume = double);
    debugPrint('Sound volume: $_soundVolume');
  }

  Future<void>setSoundEnabledLocal(bool enabled) async {
    await setSoundEnabled(enabled);
    setState(() => _soundEnabled = enabled);
    debugPrint('Sound enabled: $enabled');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(
      userFontSize,
      primaryColor,
      useDyslexiaFont,
    );

    if (!_themeLoaded) {
      // show placeholder while theme loads
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope<Object?>(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          Future.microtask(() async {
            Navigator.of(context).pushReplacementNamed('dashboard');
          });
        }
      },

      child: Theme(
        data: _themeData,
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
                        'Font Size: $userFontSize',
                        textStyle,
                      ),
                      CommonUtils.buildIconButton(
                        '',
                        Icons.remove,
                        primaryColor,
                        () {
                          if (userFontSize > 10) {
                            setUserFontSize(userFontSize - 1);
                            setThemeData(userFontSize: userFontSize - 1);
                          }
                        },
                      ),

                      Text('${userFontSize.toInt()}', style: textStyle),
                      CommonUtils.buildIconButton(
                        '',
                        Icons.add,
                        primaryColor,
                        () {
                          if (userFontSize < 24) {
                            setUserFontSize(userFontSize + 1);
                            setThemeData(userFontSize: userFontSize + 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Theme',
                  userTheme,
                  userThemes,
                  textStyle,
                  secondaryColor,
                  (val) => setUserTheme(val ?? 'light'),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Reward Type',
                  _rewardType,
                  rewardTypes,
                  textStyle,
                  secondaryColor,
                  (val) => setRewardType(val ?? 'Mini-games'),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Notification Frequency',
                  _notificationFrequency,
                  notificationFrequencies,
                  textStyle,
                  secondaryColor,
                  (val) => updateNotificationFrequency(
                    _notificationFrequency,
                    val ?? 'Medium',
                  ),
                ),
                if (_notificationFrequency != 'No notifications') ...[
                  CommonUtils.buildDropdownButtonFormField(
                    'Notification Style',
                    _notificationStyle,
                    notificationStyles,
                    textStyle,
                    secondaryColor,
                    (val) => (val) => setNotificationStyle(val ?? 'Minimal'),
                  ),
                  CommonUtils.buildSwitchListTile(
                    'Daily Affirmations',
                    textStyle,
                    dailyAffirmations,
                    setAndCheckDailyAffirmations,
                    primaryColor,
                  ),

                  if (dailyAffirmations) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              CommonUtils.buildElevatedButton(
                                _dailyAffirmationsTime.isNotEmpty
                                    ? 'Selected daily affirmations time: $_dailyAffirmationsTime click me to change'
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
                                    initialEntryMode: TimePickerEntryMode.dial,
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
                                    updateDailyAffirmations(formatted);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                  CommonUtils.buildSwitchListTile(
                    'AI Encouragement',
                    textStyle,
                    aiEncouragement,
                    setAiEncouragement,
                    primaryColor,
                  ),

                  if (!_notificationsAllowed) ...[
                    CommonUtils.buildSwitchListTile(
                      'Would you like to enable notifications?',
                      textStyle,
                      _notificationsAllowed,
                      (val) {
                        (() async {
                          await GoalNotifier.requestNotificationPermission();
                        })();
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

                // End of additional settings added if notifications are enabled.
                CommonUtils.buildSwitchListTile(
                  'Remember Me',
                  textStyle,
                  rememberMe,
                  setRememberMe,
                  primaryColor,
                ),
                CommonUtils.buildSwitchListTile(
                  'High Contrast Mode',
                  textStyle,
                  highContrastMode,
                  setHighContrastMode,
                  primaryColor,
                ),
                CommonUtils.buildSwitchListTile(
                  'Dyslexia-friendly Font',
                  textStyle,
                  useDyslexiaFont,
                  setUseDyslexiaFont,
                  primaryColor,
                ),
                CommonUtils.buildSwitchListTile(
                  'Pause Goals',
                  textStyle,
                  pauseGoals,
                  setPauseGoalsScreen,
                  primaryColor,
                ),
                CommonUtils.buildSwitchListTile (
                  'Sound',
                  textStyle,
                  _soundEnabled,
                  setSoundEnabledLocal,
                  primaryColor,
                ),

                if (_soundEnabled) ... [
                  Slider(
                      value: _soundVolume,
                      min: 0, max: 100, divisions: 100,
                      label: _soundVolume.toString(),
                      onChanged: (val) => setSoundVolumeLocal(val.toDouble()))
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
                        await clearPreferences();
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
                    await setRememberMe(false);
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
  }


}
