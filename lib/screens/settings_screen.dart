// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();

  double _fontSize = 14.0;
  String _theme = 'light';
  String _rewardType = 'Avatar';
  String _notificationStyle = 'Minimal';
  String _notificationFrequency = 'Medium';
  bool _rememberMe = false;
  bool _highContrast = false;
  bool _dyslexiaFont = false;
  double _bgBrightness = 0.5;
  bool _aiEncouragement = true;
  bool _dailyAffirmations = true;
  bool _skipToday = false;
  bool _pauseGoals = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _fontSize = double.tryParse(await _read('fontSize')) ?? 14.0;
    _theme = await _read('theme') ?? 'light';
    _rewardType = await _read('rewardType') ?? 'Avatar';
    _notificationStyle = await _read('notificationStyle') ?? 'Minimal';
    _notificationFrequency = await _read('notificationFrequency') ?? 'Medium';
    _rememberMe = await _read('rememberMe') == 'true';
    _highContrast = await _read('highContrast') == 'true';
    _dyslexiaFont = await _read('dyslexiaFont') == 'true';
    _bgBrightness = double.tryParse(await _read('bgBrightness')) ?? 0.5;
    _aiEncouragement = await _read('aiEncouragement') != 'false';
    _dailyAffirmations = await _read('dailyAffirmations') != 'false';
    _skipToday = await _read('skipToday') == 'true';
    _pauseGoals = await _read('pauseGoals') == 'true';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Future<String> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _save(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Widget build(BuildContext context) {
    final isDark = _theme == 'dark';
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: _highContrast ? Colors.yellow : Colors.deepPurple,
      fontFamily: _dyslexiaFont ? 'OpenDyslexic' : null,
      scaffoldBackgroundColor: isDark
          ? Colors.black.withOpacity(_bgBrightness)
          : Colors.white.withOpacity(1 - _bgBrightness),
      textTheme: Theme.of(context).textTheme.apply(
        fontSizeFactor: _fontSize / 14.0,
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
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: _highContrast ? Colors.yellow : Colors.grey[200],
              child: Text(
                'This is a live preview of your settings.',
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
            const Divider(),
            Slider(
              value: _fontSize,
              min: 10,
              max: 24,
              label: 'Font Size $_fontSize',
              onChanged: (v) => setState(() => _fontSize = v),
              onChangeEnd: (v) => _save('fontSize', v.toString()),
            ),
            DropdownButtonFormField<String>(
              value: ['light', 'dark'].contains(_theme) ? _theme : 'light',
              items:
                  ['light', 'dark']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged:
                  (val) => setState(() {
                    _theme = val!;
                    _save('theme', _theme);
                  }),
              decoration: const InputDecoration(labelText: 'Theme'),
            ),
            DropdownButtonFormField<String>(
              value:
                  ['Avatar', 'Mini-game', 'Leaderboard'].contains(_rewardType)
                      ? _rewardType
                      : 'Avatar',
              items:
                  ['Avatar', 'Mini-game', 'Leaderboard']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged:
                  (val) => setState(() {
                    _rewardType = val!;
                    _save('rewardType', _rewardType);
                  }),
              decoration: const InputDecoration(labelText: 'Reward Type'),
            ),
            DropdownButtonFormField(
              value:
                  [
                        'Minimal',
                        'Vibrant',
                        'Animated',
                      ].contains(_notificationStyle)
                      ? _notificationStyle
                      : 'Minimal',
              items:
                  ['Minimal', 'Vibrant', 'Animated']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) => _save('notificationStyle', val!),
              decoration: const InputDecoration(
                labelText: 'Notification Style',
              ),
            ),
            DropdownButtonFormField(
              value:
                  ['Low', 'Medium', 'High'].contains(_notificationFrequency)
                      ? _notificationFrequency
                      : 'Medium',
              items:
                  ['Low', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) => _save('notificationFrequency', val!),
              decoration: const InputDecoration(
                labelText: 'Notification Frequency',
              ),
            ),
            SwitchListTile(
              title: const Text('Remember Me'),
              value: _rememberMe,
              onChanged:
                  (v) => setState(() {
                    _rememberMe = v;
                    _save('rememberMe', v.toString());
                    if (!v) _storage.write(key: 'loggedIn', value: 'false');
                  }),
            ),
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              value: _highContrast,
              onChanged:
                  (v) => setState(() {
                    _highContrast = v;
                    _save('highContrast', v.toString());
                  }),
            ),
            SwitchListTile(
              title: const Text('Dyslexia-friendly Font'),
              value: _dyslexiaFont,
              onChanged:
                  (v) => setState(() {
                    _dyslexiaFont = v;
                    _save('dyslexiaFont', v.toString());
                  }),
            ),
            SwitchListTile(
              title: const Text('Daily Affirmations'),
              value: _dailyAffirmations,
              onChanged:
                  (v) => setState(() {
                    _dailyAffirmations = v;
                    _save('dailyAffirmations', v.toString());
                  }),
            ),
            SwitchListTile(
              title: const Text('AI Encouragement'),
              value: _aiEncouragement,
              onChanged:
                  (v) => setState(() {
                    _aiEncouragement = v;
                    _save('aiEncouragement', v.toString());
                  }),
            ),
            SwitchListTile(
              title: const Text('Skip Today (Tasks/Reminders)'),
              value: _skipToday,
              onChanged:
                  (v) => setState(() {
                    _skipToday = v;
                    _save('skipToday', v.toString());
                  }),
            ),
            SwitchListTile(
              title: const Text('Pause All Goals'),
              value: _pauseGoals,
              onChanged:
                  (v) => setState(() {
                    _pauseGoals = v;
                    _save('pauseGoals', v.toString());
                  }),
            ),
            Slider(
              value: _bgBrightness,
              min: 0.0,
              max: 1.0,
              label: 'Dark Mode Brightness: ${(_bgBrightness * 100).round()}%',
              onChanged: (v) => setState(() => _bgBrightness = v),
              onChangeEnd: (v) => _save('bgBrightness', v.toString()),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () async {
                await _storage.deleteAll();
                setState(() {});
              },
              child: const Text('Clear Preferences and Reset Assistant'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _storage.write(key: 'loggedIn', value: 'false');
                if (!_rememberMe) await _storage.deleteAll();
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
