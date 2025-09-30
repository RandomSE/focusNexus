// ✅ Updated getUserPreferences in common_utils.dart to apply to all widgets
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommonUtils {
  static final _storage = FlutterSecureStorage();

  static Future<void> getUserPreferences(State state) async {
    final theme = await _storage.read(key: 'theme') ?? 'light';
    final fontSize = double.tryParse(await _storage.read(key: 'fontSize') ?? '') ?? 14.0;
    final highContrast = (await _storage.read(key: 'highContrast')) == 'true';
    final dyslexiaFont = (await _storage.read(key: 'dyslexiaFont')) == 'true';

    if (state.mounted) {
      state.setState(() {
        (state as dynamic).userTheme = theme;
        (state as dynamic).userFontSize = fontSize;
        (state as dynamic).highContrastMode = highContrast;
        (state as dynamic).useDyslexiaFont = dyslexiaFont;
      });
    }
  }
}
