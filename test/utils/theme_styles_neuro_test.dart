import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/user_prefs_snapshot.dart';
import 'package:focusNexus/utils/theme_styles.dart';

void main() {
  const prefs = UserPrefsSnapshot();

  test('default palette uses calm non-extreme surfaces', () {
    final lightPrimary = ThemeStyles.resolvePrimaryColor(
      isDark: false,
      highContrast: false,
      prefs: prefs,
    );
    final lightSecondary = ThemeStyles.resolveSecondaryColor(
      isDark: false,
      highContrast: false,
      prefs: prefs,
    );
    final darkPrimary = ThemeStyles.resolvePrimaryColor(
      isDark: true,
      highContrast: false,
      prefs: prefs,
    );
    final darkSecondary = ThemeStyles.resolveSecondaryColor(
      isDark: true,
      highContrast: false,
      prefs: prefs,
    );

    expect(lightPrimary, isNot(Colors.black));
    expect(lightSecondary, isNot(Colors.white));
    expect(darkPrimary, isNot(Colors.white70));
    expect(darkSecondary, isNot(Colors.black));
  });

  test('buildThemeData applies accent to interactive controls', () {
    const accent = Color(0xFF5B6FF6);
    final theme = ThemeStyles.buildThemeData(
      isDark: false,
      primaryColor: const Color(0xFF1D2730),
      secondaryColor: const Color(0xFFF3F6F4),
      accentColor: accent,
      fontSize: 16,
      useDyslexiaFont: false,
    );

    expect(theme.colorScheme.primary, accent);
    final elevatedStyle = theme.elevatedButtonTheme.style;
    expect(elevatedStyle, isNotNull);
  });

  test('outlinedActionButtonStyle keeps label readable in dark mode', () {
    const primary = Color(0xFFE5ECF4);
    const secondary = Color(0xFF141A22);
    const accent = Color(0xFF8FA1FF);

    final style = ThemeStyles.outlinedActionButtonStyle(
      primaryColor: primary,
      secondaryColor: secondary,
      borderColor: accent,
    );
    final background = style.backgroundColor?.resolve({}) ?? secondary;
    final foreground = style.foregroundColor?.resolve({}) ?? primary;

    expect(foreground, primary);
    expect(background, isNot(equals(foreground)));
    expect(style.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48));
  });
}
