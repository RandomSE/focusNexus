// lib/utils/common_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommonUtils {
  static final _storage = FlutterSecureStorage();

  static Future<void> getUserPreferences(State state) async {
    final theme = await _storage.read(key: 'theme') ?? 'light';
    final fontSize = double.tryParse(await _storage.read(key: 'fontSize') ?? '') ?? 14.0;

    if (state.mounted) {
      state.setState(() {
        (state as dynamic).userTheme = theme;
        (state as dynamic).userFontSize = fontSize;
      });
    }
  }
}
