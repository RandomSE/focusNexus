import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

import '../utils/notifier.dart';
import 'dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseState<SettingsScreen> with WidgetsBindingObserver {
  bool _themeLoaded = false;
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  final _storage = const FlutterSecureStorage();
  late String _rewardType;
  late String _notificationStyle;
  late String _notificationFrequency;
  late bool _notificationsAllowed;

  @override
  void initState() {
    super.initState();
    _themeData = defaultThemeData; // Start with default
    _themeData = ThemeData.light();
    _initializeTheme(); // async theme setup from storage
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _initializeTheme() async {
    ThemeData loadedTheme;

    final String? storedTheme = await _storage.read(key: 'themeData');
    await Future.delayed(const Duration(seconds: 1));
    if (storedTheme != null) {
      loadedTheme = parseThemeData(storedTheme);
    } else {
      loadedTheme = await setAndGetThemeData(
        isDark: userTheme == 'dark',
        highContrastMode: highContrastMode,
        userFontSize: userFontSize,
        useDyslexiaFont: useDyslexiaFont,
      );
    }

    if (mounted) {
      setState(() {
        _themeData      = loadedTheme;
        _primaryColor   = loadedTheme.primaryColor;
        _secondaryColor = loadedTheme.scaffoldBackgroundColor;
        _textStyle      = loadedTheme.textTheme.bodyMedium!;
        _buttonStyle    = ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: _primaryColor,
        );
        _themeLoaded = true;
      });
    }
  }

  Future<void> _loadSettings() async {
    final storedFrequency = await _storage.read(key: 'notificationFrequency');
    final storedStyle = await _storage.read(key: 'notificationStyle');
    final storedType = await _storage.read(key: 'rewardType');
    final notificationsAllowed = await GoalNotifier.checkNotificationsPermissionsGranted();

    if (mounted) {
      setState(() {
        _rewardType = storedType ?? 'Avatar';
        _notificationStyle = storedStyle ?? 'Minimal';
        _notificationFrequency = storedFrequency ?? 'Medium';
        _notificationsAllowed = notificationsAllowed;
      });
    }


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

  @override
  Widget build(BuildContext context) {
    //final dashboardContext = ModalRoute.of(context)?.settings.arguments as BuildContext?;
    debugPrint('BuildContext - $context');
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
            //await Future.delayed(Duration(seconds: 1));
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

                SwitchListTile(title: Text('Daily Affirmations', style: textStyle), value: dailyAffirmations, onChanged: setDailyAffirmations, tileColor: primaryColor),
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
