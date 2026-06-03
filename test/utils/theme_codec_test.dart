import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/theme_codec.dart';
import 'package:focusNexus/utils/theme_styles.dart';

void main() {
  test('encodeThemeData and decodeThemeData roundtrip', () {
    const primary = Color(0xFF112233);
    const secondary = Color(0xFF445566);
    final encoded = encodeThemeData(
      isDark: true,
      primaryColor: primary,
      secondaryColor: secondary,
      userFontSize: 14,
      useDyslexiaFont: false,
    );

    final theme = decodeThemeData(encoded);
    expect(theme.brightness, Brightness.dark);
    expect(theme.primaryColor, primary);
    expect(theme.scaffoldBackgroundColor, secondary);
  });

  test('decodeThemeData applies defaults for missing keys', () {
    final theme = decodeThemeData('{}');
    expect(theme.brightness, Brightness.light);
    expect(theme.primaryColor, const Color(0xFF000000));
  });

  test('buildThemeData supports font sizes above default without throwing', () {
    for (final size in [10.0, 15.0, 24.0]) {
      expect(
        () => ThemeStyles.buildThemeData(
          isDark: false,
          primaryColor: Colors.black,
          secondaryColor: Colors.white,
          accentColor: Colors.blue,
          fontSize: size,
          useDyslexiaFont: false,
        ),
        returnsNormally,
      );
    }
  });
}
