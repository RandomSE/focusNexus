import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseState<SettingsScreen> {
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

  @override
  void initState() {
    super.initState();
    _themeData = defaultThemeData; // Start with default
    _themeData = ThemeData.light();
    _initializeTheme(); // async theme setup from storage
    _loadSettings();
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
    if (mounted) {
      setState(() {
        _rewardType = storedType ?? 'Avatar';
        _notificationStyle = storedStyle ?? 'Minimal';
        _notificationFrequency = storedFrequency ?? 'Medium';
      });
    }
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

    return Theme(
        data: _themeData,
        child: Scaffold(
          appBar: AppBar(title:  Text('Settings', style: TextStyle(backgroundColor: secondaryColor, color: primaryColor)), backgroundColor: secondaryColor, iconTheme: IconThemeData(color: primaryColor)),
          backgroundColor: secondaryColor,
          body: Container(
            color: secondaryColor,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                    'Live Preview: please note, any visual changes will require re-launching application to apply to the dashboard.',
                    style: textStyle
                ),
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
                  items: ['Avatar', 'Mini-game', 'Leaderboard']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: textStyle)))
                      .toList(),
                  onChanged: (val) => setRewardType(val ?? 'Avatar'),
                  decoration: InputDecoration(labelText: 'Reward Type', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),
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
                DropdownButtonFormField<String>(
                  style: textStyle,
                  value: _notificationFrequency,
                  items: ['Low', 'Medium', 'High', 'No notifications']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setNotificationFrequency(val ?? 'Medium'),
                  decoration: InputDecoration(labelText: 'Notification Frequency', labelStyle: textStyle),
                  dropdownColor: secondaryColor,
                ),
                SwitchListTile(title:  Text('Remember Me', style: textStyle), value: rememberMe, onChanged: setRememberMe,  tileColor: primaryColor),
                SwitchListTile(title:  Text('High Contrast Mode', style: textStyle), value: highContrastMode, onChanged: setHighContrastMode, tileColor: primaryColor),
                SwitchListTile(title:  Text('Dyslexia-friendly Font', style: textStyle), value: useDyslexiaFont, onChanged: setUseDyslexiaFont, tileColor: primaryColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Light Mode Intensity:',
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (backgroundBrightness > 0.0) {
                          setBackgroundBrightness((backgroundBrightness - 0.07).clamp(0.0, 0.7));
                        }
                      },
                    ),
                    Text('${((backgroundBrightness / 0.7) * 100).round() ~/ 10 * 10}%', style: textStyle),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (backgroundBrightness < 0.7) {
                          setBackgroundBrightness((backgroundBrightness + 0.07).clamp(0.0, 0.7));
                        }
                      },
                    ),
                  ],
                ),
                SwitchListTile(title: Text('Daily Affirmations', style: textStyle), value: dailyAffirmations, onChanged: setDailyAffirmations, tileColor: primaryColor),
                SwitchListTile(title: Text('AI Encouragement', style: textStyle), value: aiEncouragement, onChanged: setAiEncouragement, tileColor: primaryColor),
                SwitchListTile(title: Text('Pause Goals', style: textStyle), value: pauseGoals, onChanged: setPauseGoals, tileColor: primaryColor),
                const Divider(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                  onPressed: () async {
                    await clearPreferences();
                    setState(() {});
                  },
                  child:  Text('Clear Preferences and Reset Assistant', style: textStyle),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                  onPressed: () async {
                    await setRememberMe(false);
                    await setLoggedIn(false);
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, 'auth');
                  },
                  child: Text('Log Out', style: textStyle),
                ),
              ],
            ),
          ),
        )
    );
  }
}
