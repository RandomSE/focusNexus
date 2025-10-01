import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ThemeBundle.dart';
import '../utils/common_utils.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  final _storage = const FlutterSecureStorage();

  // Common user preferences with defaults
  double _userFontSize = 14.0;
  String _userTheme = 'light';
  String _rewardType = 'Avatar';
  String _notificationStyle = 'Minimal';
  String _notificationFrequency = 'Low';
  bool _rememberMe = false;
  bool _highContrastMode = false;
  bool _useDyslexiaFont = false;
  bool _aiEncouragement = false;
  bool _dailyAffirmations = false;
  bool _skipToday = false;
  bool _pauseGoals = false;
  bool _loggedIn = false;
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  bool _themeLoaded = false;
  bool _notificationsEnabled = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _checkNotificationsEnabled();
    initializeTheme(); // <- unified async theme init
    //applyThemeToState(this);
  }

  Future<void> initializeTheme() async {
    final String? storedTheme = await _storage.read(key: 'themeData');
    if (storedTheme != null) {
      final ThemeData parsedTheme = parseThemeData(storedTheme);
      if (mounted) {
        setState(() => _themeData = parsedTheme);
      }
    } else {
      // fallback to default but still uses proper user settings if available
      await setThemeData(
        isDark: userTheme == 'dark',
        highContrastMode: highContrastMode,
        userFontSize: userFontSize,
        useDyslexiaFont: useDyslexiaFont,
      );
    }
  }

  Future<ThemeBundle> initializeScreenTheme() async {
    await CommonUtils.waitForMilliseconds(500); // Takes about 80ms to load on a 2021 device, extra loading time for older devices.

    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);
    final ButtonStyle buttonStyle = getButtonStyle(primaryColor, secondaryColor);

    ThemeData loadedTheme;
    final String? storedTheme = await _storage.read(key: 'themeData');
    if (storedTheme != null) {
      loadedTheme = parseThemeData(storedTheme);
      debugPrint('Loaded stored theme.');
    } else {
      debugPrint('Stored theme unable to be loaded.');
      loadedTheme = await setAndGetThemeData(
        isDark: isDark,
        highContrastMode: contrastMode,
        userFontSize: userFontSize,
        useDyslexiaFont: useDyslexiaFont,
      );
    }

    return ThemeBundle(
      themeData: loadedTheme,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      textStyle: textStyle,
      buttonStyle: buttonStyle,
    );
  }

  Future<String> readFromStorage(String key) async { // Simple method instead of doing a .read for every variable
    final String? value = await _storage.read(key: key);
    return value ?? '';
    // TODO: Do a check to confirm this key hasn't recently been read, if it has it can easily just be cached.
  }


  Future<void> loadStoredTheme() async {
    final String? storedTheme = await _storage.read(key: 'themeData');

    if (storedTheme != null) {
      final ThemeData parsedTheme = parseThemeData(storedTheme);
      if (mounted) { // Ensure widget is still active before updating state
        setState(() {
          _themeData = parsedTheme;
        });
      }
    }
  }

  Future<void> _loadUserPreferences() async { // TODO: Refactor to remove the need for this.
    final theme = await readFromStorage('theme') ?? 'light';
    final fontSize = double.tryParse(await readFromStorage('fontSize') ?? '') ?? 14.0;
    final useDyslexiaFont = (await readFromStorage('dyslexiaFont')) == 'true';
    final highContrastMode = (await readFromStorage('highContrast')) == 'true';
    final dailyAffirmations = (await readFromStorage('dailyAffirmations')) == 'true';
    final aiEncouragement = (await readFromStorage('aiEncouragement')) == 'true';
    final rememberMe = (await readFromStorage('rememberMe')) == 'true';
    final notificationFrequency = (await readFromStorage('notificationFrequency')) ?? 'Low';
    final notificationStyle = (await readFromStorage('notificationStyle')) ?? 'Minimal';

    if (!mounted) return;
    setState(() {
      _userTheme = theme;
      _userFontSize = fontSize;
      _highContrastMode = highContrastMode;
      _useDyslexiaFont = useDyslexiaFont;
      _dailyAffirmations = dailyAffirmations;
      _aiEncouragement = aiEncouragement;
      _rememberMe = rememberMe;
      _notificationFrequency = notificationFrequency;
      _notificationStyle = notificationStyle;
    });
  }

  // Getters
  double get userFontSize => _userFontSize;
  String get userTheme => _userTheme;
  bool get rememberMe => _rememberMe;
  bool get highContrastMode => _highContrastMode;
  bool get useDyslexiaFont => _useDyslexiaFont;
  bool get aiEncouragement => _aiEncouragement;
  bool get dailyAffirmations => _dailyAffirmations;
  bool get skipToday => _skipToday;
  bool get pauseGoals => _pauseGoals;
  bool get loggedIn => _loggedIn;
  bool get onboardingCompleted => _onboardingCompleted;
  ThemeData get themeData => _themeData;

  // TODO: Change most of these to explicitly check from storage.
  /*
  Future<String> get variable async {
    String extractedString = await readFromStorage('variable');
    if (extractedString == '') {
      return 'Something';
    }
    else {
      _variable = extractedString;
      return _variable;
    }
  }


   */

  Future<String> get rewardType async {
    String extractedString = await readFromStorage('rewardType');
    if (extractedString == '') {
      return 'Avatar';
    }
    else {
      _rewardType = extractedString;
      return _rewardType;
    }
  }

  Future<String> get notificationFrequency async {
    String extractedString = await readFromStorage('notificationFrequency');
    if (extractedString == '') {
      return 'No notifications';
    }
    else {
      _notificationFrequency = extractedString;
      return _notificationFrequency;
    }
  }

  Future<String> get notificationStyle async {
    String extractedString = await readFromStorage('notificationStyle');
    if (extractedString == '') {
      return 'Minimal';
    }
    else {
      _notificationStyle = extractedString;
      return _notificationStyle;
    }
  }

  Color getPrimaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) return Colors.cyan;
    if (isDark) return Colors.white;
    return Colors.black87;
  }

  Color getSecondaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) return Colors.black;
    if (isDark) return Colors.black;
    return const Color(0xFFF5F5F5);
  }

  Future<String> getNotificationStyle() async { // TODO: update references
    await _checkNotificationStyle();
    return _notificationStyle;
  }

  Future<String> getNotificationFrequency() async { // TODO: update references
    await _checkNotificationsEnabled();
    return _notificationFrequency;
  }

  TextStyle getTextStyle(double fontSize, Color primaryColor, bool useDyslexiaFont) {
    return TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null
    );

  }

  ButtonStyle getButtonStyle(Color primaryColor, Color secondaryColor) {
    debugPrint('secondaryColor: $secondaryColor');
    return ElevatedButton.styleFrom(
      backgroundColor: secondaryColor, // secondaryColor
    );
  }

  // Setters
  Future<void> setUserFontSize(double value) async {
    setState(() => _userFontSize = value);
    await _storage.write(key: 'fontSize', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setUserTheme(String value) async {
    setState(() => _userTheme = value);
    await _storage.write(key: 'theme', value: value);
    onThemeUpdated();
  }

  Future<void> setRewardType(String value) async {
    setState(() => _rewardType = value);
    await _storage.write(key: 'rewardType', value: value);
    onThemeUpdated();
  }

  Future<void> setNotificationStyle(String value) async {
    setState(() => _notificationStyle = value);
    await _storage.write(key: 'notificationStyle', value: value);
    onThemeUpdated();
  }

  Future<void> setNotificationFrequency(String value) async {
    setState(() => _notificationFrequency = value);
    await _storage.write(key: 'notificationFrequency', value: value);
    onThemeUpdated();
  }

  Future<void> setRememberMe(bool value) async {
    debugPrint('Remember me changed. Set to: $value');
    setState(() => _rememberMe = value);
    await _storage.write(key: 'rememberMe', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setLoggedIn(bool value) async {
    setState(() => _loggedIn = value);
    await _storage.write(key: 'loggedIn', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setHighContrastMode(bool value) async {
    setState(() => _highContrastMode = value);
    await _storage.write(key: 'highContrast', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setUseDyslexiaFont(bool value) async {
    setState(() => _useDyslexiaFont = value);
    await _storage.write(key: 'dyslexiaFont', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setAiEncouragement(bool value) async {
    setState(() => _aiEncouragement = value);
    await _storage.write(key: 'aiEncouragement', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setDailyAffirmations(bool value) async {
    setState(() => _dailyAffirmations = value);
    await _storage.write(key: 'dailyAffirmations', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setSkipToday(bool value) async {
    setState(() => _skipToday = value);
    await _storage.write(key: 'skipToday', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setPauseGoals(bool value) async {
    setState(() => _pauseGoals = value);
    await _storage.write(key: 'pauseGoals', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setOnboardingComplete(bool value) async {
    setState(() => _onboardingCompleted = value);
    await _storage.write(key: 'onboardingCompleted', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setThemeData({
    ThemeData? themeData,
    bool? isDark,
    bool? highContrastMode,
    Color? primaryColor,
    Color? secondaryColor,
    double? userFontSize,
    bool? useDyslexiaFont,
  }) async {
    try {
      setState(() {
        // Determine primary and secondary colors
        final bool darkMode = isDark ?? false;
        final bool contrastMode = highContrastMode ?? false;

        primaryColor =
        contrastMode ? Colors.cyan : (darkMode ? Colors.white : Colors.black);
        secondaryColor =
        contrastMode ? Colors.black : (darkMode ? Colors.black : Colors.white);

        _themeData = themeData ??
            ThemeData(
              brightness: darkMode ? Brightness.dark : Brightness.light,
              primaryColor: primaryColor,
              scaffoldBackgroundColor: secondaryColor,
              textTheme: ThemeData
                  .light()
                  .textTheme
                  .apply(
                fontSizeFactor: (userFontSize ?? 14.0) / 14.0,
                fontFamily: useDyslexiaFont ?? false ? 'OpenDyslexic' : null,
                bodyColor: primaryColor,
                displayColor: primaryColor,
              ),
            );
      });

      await _storage.write(key: 'themeData', value: jsonEncode({
        'isDark': isDark,
        'primaryColor': primaryColor!.value,
        'secondaryColor': secondaryColor!.value,
        'userFontSize': userFontSize ?? 14.0,
        'useDyslexiaFont': useDyslexiaFont ?? false,
      }));
      onThemeUpdated();
    } catch (e) {
      final isFontSizeError = e.toString().contains('fontSize != null');

      if (isFontSizeError) {
        debugPrint('Font size scaling failed, ignoring: $e'); // This happens when you change the font size due to flutter's... eccentricities. Doesn't prevent font size from being changed, so it will be ignored here.
      } else {
        debugPrint('Theme application failed: $e');
        // Apply a safe fallback theme
        _themeData = ThemeData.light();
      }
    }
  }

  Future<ThemeData> setAndGetThemeData({
    ThemeData? themeData,
    bool? isDark,
    bool? highContrastMode,
    Color? primaryColor,
    Color? secondaryColor,
    double? userFontSize,
    bool? useDyslexiaFont,
  }) async {
    late ThemeData newTheme;

    // Compute fallback theme values
    final bool darkMode = isDark ?? false;
    final bool contrastMode = highContrastMode ?? false;
    final double fontSize = userFontSize ?? 14.0;
    final bool dyslexiaFont = useDyslexiaFont ?? false;

    final Color resolvedPrimaryColor =
        primaryColor ?? (contrastMode ? Colors.cyan : (darkMode ? Colors.white : Colors.black));

    final Color resolvedSecondaryColor = contrastMode
        ? Colors.black
        : (secondaryColor ?? (darkMode ? Colors.black : Colors.white));

    // Build theme either from parameter or calculated values
    newTheme = themeData ??
        ThemeData(
          brightness: darkMode ? Brightness.dark : Brightness.light,
          primaryColor: resolvedPrimaryColor,
          scaffoldBackgroundColor: resolvedSecondaryColor,
          textTheme: ThemeData.light().textTheme.apply(
            fontSizeFactor: fontSize / 14.0,
            fontFamily: dyslexiaFont ? 'OpenDyslexic' : null,
            bodyColor: resolvedPrimaryColor,
            displayColor: resolvedPrimaryColor,
          ),
        );

    // Apply theme to state
    if (mounted) {
      setState(() {
        _themeData = newTheme;
      });
    }

    // Persist theme settings
    await _storage.write(key: 'themeData', value: jsonEncode({
      'isDark': darkMode,
      'primaryColor': resolvedPrimaryColor.value,
      'secondaryColor': resolvedSecondaryColor.value,
      'userFontSize': fontSize,
      'useDyslexiaFont': dyslexiaFont,
    }));

    return newTheme;
  }



  Future<void> clearPreferences() async {
    await _storage.deleteAll();

    setState(() {
      _userFontSize = 14.0;
      _userTheme = 'light';
      _rewardType = 'Avatar';
      _notificationStyle = 'Minimal';
      _notificationFrequency = 'Medium';
      _rememberMe = false;
      _highContrastMode = false;
      _useDyslexiaFont = false;
      _aiEncouragement = false;
      _dailyAffirmations = false;
      _skipToday = false;
      _pauseGoals = false;
      _loggedIn = false;
      _onboardingCompleted = false;
    });

    await setUserFontSize(14.0);
    await setUserTheme('light');
    await setRewardType('Avatar');
    await setNotificationStyle('Minimal');
    await setNotificationFrequency('Medium');
    await setRememberMe(false);
    await setHighContrastMode(false);
    await setUseDyslexiaFont(false);
    await setAiEncouragement(false);
    await setDailyAffirmations(false);
    await setSkipToday(false);
    await setPauseGoals(false);
    await setLoggedIn(false);
    await setOnboardingComplete(false);
  }

  final ThemeData defaultThemeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.white,
    textTheme: ThemeData.light().textTheme.apply(
      fontSizeFactor: 1.0,
      fontFamily: null,
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
  );

  ThemeData parseThemeData(String storedTheme) {
    final Map<String, dynamic> themeMap = jsonDecode(storedTheme);

    final bool isDark = themeMap['isDark'] ?? false;
    final int primaryColorValue = themeMap['primaryColor'] ?? 0xFF000000;
    final int secondaryColorValue = themeMap['secondaryColor'] ?? 0xFFFFFFFF;
    final double fontSize = (themeMap['userFontSize'] ?? 14).toDouble();
    final bool useDyslexiaFont = themeMap['useDyslexiaFont'] ?? false;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: Color(primaryColorValue),
      scaffoldBackgroundColor: Color(secondaryColorValue),
      textTheme: ThemeData.light().textTheme.apply(
        fontSizeFactor: fontSize / 14.0,
        fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
        bodyColor: Color(primaryColorValue),
        displayColor: Color(primaryColorValue),
      ),
    );
  }



  void onThemeUpdated() {

  }
  Future<void> _checkNotificationsEnabled()  async {
    final String? notificationFrequency = await _storage.read(key: 'notificationFrequency');
    debugPrint('NotificationFrequency: $notificationFrequency');
    if (notificationFrequency == null || notificationFrequency == '' || notificationFrequency == 'No notifications') {
      _notificationsEnabled = false;
    }
    else if (notificationFrequency == 'Low' || notificationFrequency == 'Medium' || notificationFrequency == 'High') {
      _notificationsEnabled =  true;
      _notificationFrequency = notificationFrequency;
    }
    else {
      debugPrint('Unexpected scenario caught - invalid notification frequency: $notificationFrequency');
      _notificationsEnabled =  false; /// This case should never happen
    }
  }

  bool getNotificationsEnabled () {
    _checkNotificationsEnabled();
    return _notificationsEnabled;
  }

  Future<void> _checkNotificationStyle() async {
    final String? notificationStyle = await _storage.read(key: 'notificationStyle');
    if (notificationStyle == null || notificationStyle == '' || notificationStyle == 'Minimal') {
      _notificationStyle = 'Minimal';
    }
    else {
      _notificationStyle = notificationStyle;
    }
    debugPrint('NotificationStyle: $notificationStyle');
  }

  Future<bool> checkOnboardingCompleted() async {
    final String? value = await _storage.read(key: 'onboardingCompleted');
    debugPrint('Onboarding completed: $value');
    _onboardingCompleted = (value == 'true');
    return _onboardingCompleted;
  }
}
