import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../models/classes/goal_set.dart';
import '../models/classes/theme_bundle.dart';
import '../utils/common_utils.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  final _storage = const FlutterSecureStorage();

  // Common user preferences with defaults
  double _userFontSize = 14.0;
  String _userTheme = 'light';
  String _rewardType = 'Mini-games';
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
  String _dailyAffirmationsTime = '06:00';

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

  bool stringEqualsTrue(String value)  {
    return value == 'true';
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
  bool get dailyAffirmations => _dailyAffirmations;
  bool get aiEncouragement => _aiEncouragement;
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

  Future<String> get dailyAffirmationsTime async {
    String extractedString = await readFromStorage('dailyAffirmationsTime');
    if (extractedString == '') {
      return 'No current time.';
    }
    else {
      _dailyAffirmationsTime = extractedString;
      return _dailyAffirmationsTime;
    }
  }

  Future<String> get rewardType async {
    String extractedString = await readFromStorage('rewardType');
    if (extractedString == '') {
      return 'Mini-games';
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

  Future<bool> getBoolFromStorage (String key) async {
    String extractedString = await readFromStorage(key);
    bool returnedValue = false;
    if (extractedString == '') {
      return returnedValue;
    }
    else {
      return stringEqualsTrue(extractedString);
    }
  }

  Future<String> getStringFromStorage (String key) async {
    String extractedString = await readFromStorage(key);
    return extractedString; // no real validation needed here. If specific values are warranted, simply validate there or make a wrapper method that calls this and validates that way.
  }

  Future<int> getIntFromStorage(String key) async {
    if (key.isEmpty) return 0;
    final String? stored = await _storage.read(key: key);
    final int parsed = int.tryParse(stored ?? '') ?? 0;
    return parsed;
  }

  Color getPrimaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) {
      if (isDark) {
        return Colors.cyan;
      }
      return const Color(0xFF004F52);
    }
    return Colors.black87;
  }

  Color getSecondaryColor(bool isDark, bool contrastMode) {
    if (contrastMode) {
      if (isDark) {
        return Colors.black;
      }
      return const Color(0xFFF2EFE6);
    }
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

  bool getNotificationsEnabled () {
    _checkNotificationsEnabled();
    return _notificationsEnabled;
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

  Future<void> setOnboardingCompleted(bool value) async {
    setState(() => _onboardingCompleted = value);
    await _storage.write(key: 'onboardingCompleted', value: value.toString());
    onThemeUpdated();
  }

  Future<void> setBoolVariableStorageOnly(String key, bool value) async {
    if (key != '') {
      debugPrint('Key: $key, Value: $value');
      await _storage.write(key: key, value: value.toString());
    }
  }


  Future<void> setBoolVariable(String key, bool value) async { // TODO: Replace all calls to set bool variables with THIS instead, once all bool variables are added here.
    final Map<String, void Function()> localSetters = {
      'onboardingCompleted': () => setState(() => _onboardingCompleted = value),
      'rememberMe': () => setState(() => _rememberMe = value),
      'aiEncouragement': () => setState(() => _aiEncouragement = value),
      'dailyAffirmations': () => setState(() => _dailyAffirmations = value),
    };

    final setter = localSetters[key];
    if (setter != null) {
      setter(); // update local state
      await _storage.write(key: key, value: value.toString()); // persist
      onThemeUpdated(); // trigger any downstream updates
    } else {
      debugPrint('No known set method was called for key "$key".');
    }
  }

  Future<void> setStringVariableStorageOnly (String key, String value) async {// TODO: Replace all calls to set string variables with THIS instead, once all string variables are added here.)
    debugPrint('Key: $key, Value: $value');
    if (key != '' && value != '') {
      await _storage.write(key: key, value: value);
    } else {
      debugPrint('Key or value is empty. Key: $key, Value: $value');
    }
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

      if (!isFontSizeError) { // No need to throw error for Font size error. it doesn't effect project function.
        debugPrint('Theme application failed: $e');
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

  Future<void> setStringValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> clearPreferences() async {
    await _storage.deleteAll();

    setState(() {
      _userFontSize = 14.0;
      _userTheme = 'light';
      _rewardType = 'Mini-games';
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
    await setRewardType('Mini-games');
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
    await setOnboardingCompleted(false);
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

  Future<void> incrementStoredInt(String key) async {
    if (key.isEmpty) {
      debugPrint('Cannot increment: key is empty.');
      return;
    }

    final int current = await getIntFromStorage(key);
    final int updated = current + 1;
    await _storage.write(key: key, value: updated.toString());
    debugPrint('Incremented $key: $current → $updated');
  }

  Future<void> decreaseStoredInt(String key) async {
    if (key.isEmpty) {
      debugPrint('Cannot decrease: key is empty.');
      return;
    }

    final int current = await getIntFromStorage(key);
    final int updated = current - 1;
    await _storage.write(key: key, value: updated.toString());
    debugPrint('Decreased $key: $current → $updated');
  }

  Future<void> setStoredInt(String key, int value) async {
    if (key.isEmpty || value.toString().isEmpty) {
      debugPrint('Cannot increment: key or value is empty. key: $key value: $value');
      return;
    }

    final int current = await getIntFromStorage(key);
    await _storage.write(key: key, value: value.toString());
    debugPrint('Set $key: $current → $value');
  }

  Future<void> checkOrAddDate() async {
    const String key = 'dateGoalsCompleted';
    final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    await checkAndUpdateWeekProgress();
    await checkAndUpdateMonthProgress();

    String extracted = await getStringFromStorage(key);
    List<String> dates = extracted.isNotEmpty
        ? extracted.split(',').map((e) => e.trim()).toList()
        : [];

    // If today's date is already the last entry, do nothing
    if (dates.isNotEmpty && dates.last == today || dates.contains(today)) {
      await updateDailyVariables(dates, key, today);
      debugPrint('Date already recorded as last entry: $today');
      return;
    }

    // If list is full, remove the oldest entry
    if (dates.length >= 31) {
      dates.removeAt(0);
    }

    // Add today's date
    await setStoredInt('goalsCompletedToday', 1);
    dates.add(today);
    final updated = dates.join(',');

    await setStringVariableStorageOnly(key, updated);
    debugPrint('Added date: $today → $updated');
  }

  Future<void> updateDailyVariables(List<String> dates, String key, String dateToday) async {
    await incrementStoredInt('goalsCompletedToday');

    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    final String formattedYesterday = DateFormat('dd-MM-yyyy').format(yesterday);

    if (dates.contains(formattedYesterday)) {
      await incrementStoredInt('consecutiveDaysWithGoalsCompleted');
      debugPrint('Yesterday was also completed. Incremented streak.');
    } else {
      await setStoredInt('consecutiveDaysWithGoalsCompleted', 1);
      debugPrint('No goal completed yesterday. Streak reset to 1.');
    }
  }

  Future<void> checkAndUpdateWeekProgress() async {
    const String weekKey = 'lastWeekGoalWasCompleted';
    final String currentWeek = _getWeekIdentifier(DateTime.now());
    final String storedWeek = await getStringFromStorage(weekKey);

    if (storedWeek != currentWeek) {
      await setStringVariableStorageOnly(weekKey, currentWeek);
      await setStoredInt('goalsCompletedThisWeek', 1);

      final bool isConsecutive = _isPreviousWeek(storedWeek, currentWeek);
      if (isConsecutive) {
        await incrementStoredInt('consecutiveWeeksWithGoalsCompleted');
      } else {
        await setStoredInt('consecutiveWeeksWithGoalsCompleted', 1);
      }

      debugPrint('New week detected. Reset weekly count and updated streak logic.');
    } else {
      await incrementStoredInt('goalsCompletedThisWeek');
      debugPrint('Same week. Incremented weekly goal count.');
    }
  }

  Future<void> checkAndUpdateMonthProgress() async {
    const String monthKey = 'lastMonthGoalWasCompleted';
    final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final String storedMonth = await getStringFromStorage(monthKey);

    if (storedMonth != currentMonth) {
      await setStringVariableStorageOnly(monthKey, currentMonth);
      await setStoredInt('goalsCompletedThisMonth', 1);
      debugPrint('New month detected. Reset monthly count.');
    } else {
      await incrementStoredInt('goalsCompletedThisMonth');
      debugPrint('Same month. Incremented monthly goal count.');
    }
  }

  Future<void> checkAndUpdateGoalAchievementStats(GoalSet goal) async {
    final bool isHighComplexity = goal.complexity.toLowerCase() == 'high';
    final bool isHighEffort = goal.effort.toLowerCase() == 'high';
    final bool isHighMotivation = goal.motivation.toLowerCase() == 'high';
    final bool isAllHigh = isHighComplexity && isHighEffort && isHighMotivation;

    if (goal.points >= 100) {
      await incrementStoredInt('goalsCompletedWithHighPoints');
    }
    if (isHighComplexity) {
      await incrementStoredInt('goalsCompletedWithHighComplexity');
    }
    if (isHighEffort) {
      await incrementStoredInt('goalsCompletedWithHighEffort');
    }
    if (isHighMotivation) {
      await incrementStoredInt('goalsCompletedWithHighMotivation');
    }
    if (isAllHigh) {
      await incrementStoredInt('goalsCompletedWithAllHigh');
    }
    if (goal.time >= 150) {
      await incrementStoredInt('goalsCompletedWithHighTimeRequirement');
    }
    if (goal.steps >= 15) {
      await incrementStoredInt('goalsCompletedWithManySteps');
    }

    // Check if completed at least 20 hours before deadline
    if (goal.deadline.isNotEmpty) {
      try {
        final DateTime deadlineDate = DateFormat('dd MMMM yyyy HH:mm').parse(goal.deadline);
        final DateTime now = DateTime.now();
        final Duration difference = deadlineDate.difference(now);
        if (difference.inHours >= 20) {
          await incrementStoredInt('goalsCompletedEarly');
        }
      } catch (e) {
        debugPrint('Invalid deadline format: ${goal.deadline}');
      }
    }
  }


  bool _isPreviousWeek(String storedWeek, String currentWeek) {
    if (storedWeek.isEmpty || currentWeek.isEmpty) return false;

    try {
      final DateTime current = DateFormat('yyyy-MM-dd').parse(currentWeek);
      final DateTime previousWeekStart = current.subtract(const Duration(days: 7));
      final String previousWeek = _getWeekIdentifier(previousWeekStart);
      return storedWeek == previousWeek;
    } catch (_) {
      return false;
    }
  }

  String _getWeekIdentifier(DateTime date) {
    final int weekday = date.weekday;
    final DateTime startOfWeek = date.subtract(Duration(days: weekday - 1));
    debugPrint(startOfWeek.toString());
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }




}
