import 'package:flutter/material.dart';
import 'package:focusNexus/utils/BaseState.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = userTheme == 'dark';
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: highContrastMode ? Colors.yellow : Colors.deepPurple,
      scaffoldBackgroundColor: isDark
          ? Colors.black.withOpacity(backgroundBrightness)
          : Colors.white.withOpacity(1 - backgroundBrightness),
      textTheme: Theme.of(context).textTheme.apply(
        fontSizeFactor: userFontSize / 14.0,
        fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
        bodyColor: isDark ? Colors.grey[300] : Colors.black,
        displayColor: isDark ? Colors.grey[300] : Colors.black,
      ),
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Live Preview:',
              style: TextStyle(
                fontSize: userFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: highContrastMode ? Colors.yellow : Colors.grey[200],
              child: Text(
                'This is a live preview of your settings.',
                style: TextStyle(fontSize: userFontSize),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Font Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (userFontSize > 10) setUserFontSize(userFontSize - 2);
                  },
                ),
                Text('${userFontSize.toInt()}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (userFontSize < 24) setUserFontSize(userFontSize + 2);
                  },
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: userTheme,
              items: ['light', 'dark']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setUserTheme(val ?? 'light'),
              decoration: const InputDecoration(labelText: 'Theme'),
            ),
            DropdownButtonFormField<String>(
              value: rewardType,
              items: ['Avatar', 'Mini-game', 'Leaderboard']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setRewardType(val ?? 'Avatar'),
              decoration: const InputDecoration(labelText: 'Reward Type'),
            ),
            DropdownButtonFormField<String>(
              value: notificationStyle,
              items: ['Minimal', 'Vibrant', 'Animated']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setNotificationStyle(val ?? 'Minimal'),
              decoration: const InputDecoration(labelText: 'Notification Style'),
            ),
            DropdownButtonFormField<String>(
              value: notificationFrequency,
              items: ['Low', 'Medium', 'High']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setNotificationFrequency(val ?? 'Medium'),
              decoration: const InputDecoration(labelText: 'Notification Frequency'),
            ),
            SwitchListTile(title: const Text('Remember Me'), value: rememberMe, onChanged: setRememberMe),
            SwitchListTile(title: const Text('High Contrast Mode'), value: highContrastMode, onChanged: setHighContrastMode),
            SwitchListTile(title: const Text('Dyslexia-friendly Font'), value: useDyslexiaFont, onChanged: setUseDyslexiaFont),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Light Mode Intensity:',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                Text('${((backgroundBrightness / 0.7) * 100).round() ~/ 10 * 10}%'),
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
            SwitchListTile(title: const Text('Daily Affirmations'), value: dailyAffirmations, onChanged: setDailyAffirmations),
            SwitchListTile(title: const Text('AI Encouragement'), value: aiEncouragement, onChanged: setAiEncouragement),
            SwitchListTile(title: const Text('Skip Today (Tasks/Reminders)'), value: skipToday, onChanged: setSkipToday),
            SwitchListTile(title: const Text('Pause Goals'), value: pauseGoals, onChanged: setPauseGoals),
            const Divider(),
            ElevatedButton(
              onPressed: () async {
                await clearPreferences();
                setState(() {});
              },
              child: const Text('Clear Preferences and Reset Assistant'),
            ),
            ElevatedButton(
              onPressed: () async {
                await setRememberMe(false);
                await setLoggedIn(false);
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, 'auth');
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
