import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  final _storage = const FlutterSecureStorage();

  // Common user preferences with defaults
  double _userFontSize = 14.0;
  String _userTheme = 'light';
  String _rewardType = 'Avatar';
  String _notificationStyle = 'Minimal';
  String _notificationFrequency = 'Medium';
  bool _rememberMe = false;
  bool _highContrastMode = false;
  bool _useDyslexiaFont = false;
  double _backgroundBrightness = 0.0;
  bool _aiEncouragement = true;
  bool _dailyAffirmations = true;
  bool _skipToday = false;
  bool _pauseGoals = false;
  bool _loggedIn = false;
  late ThemeData _themeData;
  bool _notificationsEnabled = false;


  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _checkNotificationsEnabled();
    initializeTheme(); // <- unified async theme init
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

  Future<void> _loadUserPreferences() async {
    final theme = await _storage.read(key: 'theme') ?? 'light';
    final fontSize = double.tryParse(await _storage.read(key: 'fontSize') ?? '') ?? 14.0;
    final useDyslexiaFont = (await _storage.read(key: 'dyslexiaFont')) == 'true';
    final highContrastMode = (await _storage.read(key: 'highContrast')) == 'true';
    final dailyAffirmations = (await _storage.read(key: 'dailyAffirmations')) == 'true';
    final aiEncouragement = (await _storage.read(key: 'aiEncouragement')) == 'true';
    final bgBrightness = double.tryParse(await _storage.read(key: 'bgBrightness') ?? '') ?? 0.0;

    if (!mounted) return;
    setState(() {
      _userTheme = theme;
      _userFontSize = fontSize;
      _highContrastMode = highContrastMode;
      _useDyslexiaFont = useDyslexiaFont;
      _dailyAffirmations = dailyAffirmations;
      _aiEncouragement = aiEncouragement;
      _backgroundBrightness = bgBrightness;
    });
  }

  // Getters
  double get userFontSize => _userFontSize;
  String get userTheme => _userTheme;
  String get rewardType => _rewardType;
  String get notificationStyle => _notificationStyle;
  String get notificationFrequency => _notificationFrequency;
  bool get rememberMe => _rememberMe;
  bool get highContrastMode => _highContrastMode;
  bool get useDyslexiaFont => _useDyslexiaFont;
  double get backgroundBrightness => _backgroundBrightness;
  bool get aiEncouragement => _aiEncouragement;
  bool get dailyAffirmations => _dailyAffirmations;
  bool get skipToday => _skipToday;
  bool get pauseGoals => _pauseGoals;
  bool get loggedIn => _loggedIn;
  ThemeData get themeData => _themeData;

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
    setState(() => _rememberMe = value);
    await _storage.write(key: 'rememberMe', value: value.toString());
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

  Future<void> setBackgroundBrightness(double value) async {
    setState(() => _backgroundBrightness = value);
    await _storage.write(key: 'bgBrightness', value: value.toString());
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

  Future<void>setLoggedIn(bool value) async {
    setState(() => _loggedIn = value);
    await _storage.write(key: 'pauseGoals', value: value.toString());
    onThemeUpdated();

  }

  Future<void> setThemeData({
    ThemeData? themeData,
    bool? isDark,
    bool? highContrastMode,
    Color? primaryColor,
    Color? secondaryColor,
    double? backgroundBrightness,
    double? userFontSize,
    bool? useDyslexiaFont,
  }) async {
    setState(() {
      // Determine primary and secondary colors
      final bool darkMode = isDark ?? false;
      final bool contrastMode = highContrastMode ?? false;

      primaryColor = contrastMode ? Colors.cyan : (darkMode ? Colors.white : Colors.black);
      secondaryColor = contrastMode ? Colors.black : (darkMode ? Colors.black : Colors.white.withOpacity(1 - (backgroundBrightness ?? 1.0)));

      _themeData = themeData ??
          ThemeData(
            brightness: darkMode ? Brightness.dark : Brightness.light,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: secondaryColor,
            textTheme: ThemeData.light().textTheme.apply(
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

  }

  Future<ThemeData> setAndGetThemeData({
    ThemeData? themeData,
    bool? isDark,
    bool? highContrastMode,
    Color? primaryColor,
    Color? secondaryColor,
    double? backgroundBrightness,
    double? userFontSize,
    bool? useDyslexiaFont,
  }) async {
    late ThemeData newTheme;

    // Compute fallback theme values
    final bool darkMode = isDark ?? false;
    final bool contrastMode = highContrastMode ?? false;
    final double brightnessFactor = backgroundBrightness ?? 1.0;
    final double fontSize = userFontSize ?? 14.0;
    final bool dyslexiaFont = useDyslexiaFont ?? false;

    final Color resolvedPrimaryColor =
        primaryColor ?? (contrastMode ? Colors.cyan : (darkMode ? Colors.white : Colors.black));

    final Color resolvedSecondaryColor = secondaryColor ??
        (contrastMode
            ? Colors.black
            : (darkMode
            ? Colors.black
            : Colors.white.withOpacity(1 - brightnessFactor)));

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
      _backgroundBrightness = 0.0;
      _aiEncouragement = true;
      _dailyAffirmations = true;
      _skipToday = false;
      _pauseGoals = false;
      _loggedIn = false;
    });

    await setUserFontSize(14.0);
    await setUserTheme('light');
    await setRewardType('Avatar');
    await setNotificationStyle('Minimal');
    await setNotificationFrequency('Medium');
    await setRememberMe(false);
    await setHighContrastMode(false);
    await setUseDyslexiaFont(false);
    await setBackgroundBrightness(0.0);
    await setAiEncouragement(true);
    await setDailyAffirmations(true);
    await setSkipToday(false);
    await setPauseGoals(false);
    await setLoggedIn(false);
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

  Color getPrimaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) return Colors.cyan;
    if (isDark) return Colors.white;
    return Colors.black87; // Less stark than pure black, more readable than opacity tricks
  }

  Color getSecondaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) return Colors.black;
    if (isDark) return Colors.black;
    return const Color(0xFFF5F5F5); // A soft, neutral off-white for light mode
  }


  TextStyle getTextStyle(double fontSize, Color primaryColor, bool useDyslexiaFont) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: primaryColor,
      fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null
    );

  }

  void onThemeUpdated() {

  }
  Future<void> _checkNotificationsEnabled()  async {
    final String? notificationFrequency = await _storage.read(key: 'notificationFrequency');
    if (notificationFrequency == null || notificationFrequency == '' || notificationFrequency == 'No notifications') {
      _notificationsEnabled = false;
    }
    else if (notificationFrequency == 'Low' || notificationFrequency == 'Medium' || notificationFrequency == 'High') {
      _notificationsEnabled =  true;
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

  Future<String> getNotificationStyle() async {
    await _checkNotificationStyle();
    return _notificationStyle;
  }



}
