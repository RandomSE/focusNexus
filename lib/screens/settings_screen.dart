import 'package:flutter/material.dart';
import 'package:focusNexus/utils/BaseState.dart';
import '../utils/notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseState<SettingsScreen> with WidgetsBindingObserver {
  final TextEditingController _affirmationTimeController = TextEditingController();
  late ThemeData _themeData;
  bool _themeLoaded = false;
  late String _rewardType;
  late String _notificationStyle;
  late String _notificationFrequency;
  late bool _notificationsAllowed;
  late String _dailyAffirmationsTime;

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
    final storedFrequency = await notificationFrequency;
    final storedStyle = await notificationStyle;
    final storedType = await rewardType;
    final notificationsAllowed = await GoalNotifier.checkNotificationsPermissionsGranted();
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
      });
    }
  }

  Future<void> setAndCheckDailyAffirmations(bool value) async {
    await setDailyAffirmations(value);

    if (value) { // enabled - schedule daily affirmations.
      final dailyAffirmationTime = await dailyAffirmationsTime;
      updateDailyAffirmations(dailyAffirmationTime);
    }
    else { // disabled - do not schedule daily affirmations.
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

  Future<void> updateNotificationFrequency(String oldFrequency, String newFrequency) async {
    await setNotificationFrequency(newFrequency);
    if (oldFrequency == 'No notifications' && newFrequency != 'No notifications') {
      await GoalNotifier.requestNotificationPermission();
    }
    if (oldFrequency != 'No notifications' && newFrequency == 'No notifications') {
      await GoalNotifier.cancelAllGoalNotifications();
    }
    if (mounted) {
      setState(() {
        _notificationFrequency = newFrequency;
      });
    }
  }

  ThemeData buildTimePickerTheme(Color primaryColor, Color secondaryColor, TextStyle textStyle) {
    return ThemeData(
      timePickerTheme: TimePickerThemeData(
        backgroundColor: secondaryColor,
        dialBackgroundColor: secondaryColor,
        dialHandColor: Colors.deepPurple,
        dialTextColor: primaryColor,
        entryModeIconColor: primaryColor,

        hourMinuteColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryColor : secondaryColor),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? secondaryColor : primaryColor),

        dayPeriodColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryColor : secondaryColor),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? secondaryColor : primaryColor),

        helpTextStyle: textStyle,
        hourMinuteTextStyle: textStyle,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);

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
            debugPrint("Dashboard re-opened and updated after exiting settings.");
          });
        }
      },

    child: Theme(
        data: _themeData,
        child: Scaffold(
          appBar: AppBar(title:  Text('Settings', style: TextStyle(backgroundColor: secondaryColor, color: primaryColor)), backgroundColor: secondaryColor, iconTheme: IconThemeData(color: primaryColor)),
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
                  child: Text(
                    'This is a live preview of your settings.',
                    style: textStyle,
                  ),
                ),
                const Divider(
                ),
                Container(
                  color: secondaryColor ,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Font Size:', style: textStyle),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (userFontSize > 10) {
                            setUserFontSize(userFontSize - 1);
                            setThemeData(userFontSize: userFontSize - 1);
                          }
                        },
                      ),
                      Text('${userFontSize.toInt()}', style: textStyle),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (userFontSize < 24) {
                            setUserFontSize(userFontSize + 1);
                            setThemeData(userFontSize: userFontSize + 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<String>(
                  style: textStyle,
                  value: userTheme,
                  items: ['light', 'dark']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: textStyle,
                  )))
                      .toList(),
                  onChanged: (val) => setUserTheme(val ?? 'light'),
                  decoration: InputDecoration(labelText: 'Theme', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),
                DropdownButtonFormField<String>(
                  style: textStyle,
                  value: _rewardType,
                  items: ['Avatar', 'Mini-games', 'Leaderboard']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: textStyle)))
                      .toList(),
                  onChanged: (val) => setRewardType(val ?? 'Avatar'),
                  decoration: InputDecoration(labelText: 'Reward Type', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),
                DropdownButtonFormField<String>(
                  style: textStyle,
                  value: _notificationFrequency,
                  items: ['Low', 'Medium', 'High', 'No notifications']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => updateNotificationFrequency(_notificationFrequency, val ?? 'Medium'),
                  decoration: InputDecoration(labelText: 'Notification Frequency', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),
                if (_notificationFrequency != 'No notifications') ...[
                DropdownButtonFormField<String>(
                  style: textStyle,
                  value: _notificationStyle,
                  items: ['Minimal', 'Vibrant', 'Animated']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: textStyle)))
                      .toList(),
                  onChanged: (val) => setNotificationStyle(val ?? 'Minimal'),
                  decoration: InputDecoration(labelText: 'Notification Style', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),

                SwitchListTile(title: Text('Daily Affirmations', style: textStyle), value: dailyAffirmations, onChanged: setAndCheckDailyAffirmations, tileColor: primaryColor),
                  if(dailyAffirmations) ... [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Affirmation Time:',
                                style: textStyle,
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: BorderSide(color: Colors.grey.shade400),
                                  ),
                                ),
                                onPressed: () async {
                                  final selected = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    initialEntryMode: TimePickerEntryMode.dial,
                                    builder: (context, child) => Theme(
                                      data: buildTimePickerTheme(primaryColor, secondaryColor, textStyle),
                                      child: child!,
                                    ),
                                  );

                                  if (selected != null) {
                                    final formatted = selected.hour.toString().padLeft(2, '0') +
                                        ':' +
                                        selected.minute.toString().padLeft(2, '0');
                                    updateDailyAffirmations(formatted);
                                  }
                                },
                                child: Text(
                                  _dailyAffirmationsTime.isNotEmpty
                                      ? 'Selected daily affirmations time: $_dailyAffirmationsTime click me to change'
                                      : 'Choose Time',
                                  style: textStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    )
                  ],
                SwitchListTile(title: Text('AI Encouragement', style: textStyle), value: aiEncouragement, onChanged: setAiEncouragement, tileColor: primaryColor),


                  if (!_notificationsAllowed) ... [
                    SwitchListTile(title: Text('You have notifications enabled in the app, but not on your phone. Would you like to enable them?', style: textStyle), value: false, onChanged: (val) {
                      (() async {
                        await GoalNotifier.requestNotificationPermission();
                      })();
                    }, tileColor: primaryColor),
                  ],
                ]

                else ...[
                  Text('Notifications are disabled. Settings related to them will not be shown until re-enabled.', style: textStyle),
                ], // End of additional settings added if notifications are enabled.

                SwitchListTile(title: Text('Remember Me', style: textStyle), value: rememberMe, onChanged: setRememberMe,  tileColor: primaryColor),
                SwitchListTile(title: Text('High Contrast Mode', style: textStyle), value: highContrastMode, onChanged: setHighContrastMode, tileColor: primaryColor),
                SwitchListTile(title: Text('Dyslexia-friendly Font', style: textStyle), value: useDyslexiaFont, onChanged: setUseDyslexiaFont, tileColor: primaryColor),
                SwitchListTile(title: Text('Pause Goals', style: textStyle), value: pauseGoals, onChanged: setPauseGoals, tileColor: primaryColor),
                const Divider(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                  onPressed: () async {
                    final firstConfirmation = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account?'),
                        content: const Text(
                          'Would you like to delete your account and reset all settings?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes, I am sure.'),
                          ),
                        ],
                      ),
                    );

                    if (firstConfirmation == true) {
                      final secondConfirmation = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text(
                            'Are you sure you would like to delete your account and reset all settings? This is permanent and cannot be reversed once done.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes, delete my account.'),
                            ),
                          ],
                        ),
                      );

                    if(secondConfirmation == true){
                    await clearPreferences();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, 'auth');
                    }
                  }},

                  child:  Text('Clear Preferences and Reset Assistant', style: textStyle),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                  onPressed: () async {
                    await setRememberMe(false);
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, 'auth');
                  },
                  child: Text('Log Out', style: textStyle),
                ),
              ],
            ),
          ),
        )
    ),
    );
  }
}
