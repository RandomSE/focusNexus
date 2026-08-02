import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

/// Shared HUD / end-overlay text styles from [ThemeBundle] (font size, dyslexia, HC).
class MiniGameThemedHud {
  MiniGameThemedHud(this.bundle);

  final ThemeBundle bundle;

  Color get foreground => bundle.primaryColor;

  TextStyle get label => bundle.textStyle.copyWith(
    color: foreground,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.6,
  );

  TextStyle get title => bundle.textStyle.copyWith(
    color: foreground,
    fontWeight: FontWeight.w600,
    fontSize: (bundle.textStyle.fontSize ?? 14) * 1.15,
  );

  TextStyle get score => bundle.textStyle.copyWith(
    color: foreground,
    fontWeight: FontWeight.w300,
    fontSize: (bundle.textStyle.fontSize ?? 14) * 3.2,
    height: 1.0,
  );

  TextStyle get body => bundle.textStyle.copyWith(color: foreground);

  TextStyle get hint => bundle.textStyle.copyWith(
    color: foreground.withValues(alpha: 0.72),
    fontSize: (bundle.textStyle.fontSize ?? 14) * 0.95,
  );

  /// Compact HUD style: keeps dyslexia [fontFamily] but fixed size/height so
  /// large Accessibility font sizes cannot blow out mini-game chrome.
  TextStyle compact({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.15,
    Color? color,
  }) {
    return TextStyle(
      inherit: false,
      color: color ?? foreground,
      fontSize: fontSize,
      fontFamily: bundle.textStyle.fontFamily,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: 0.2,
    );
  }
}
