import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/screen_theme.dart';

/// Font sizes offered in Settings and Registration.
final List<double> kFontSizeOptions =
    List<double>.generate(15, (i) => (10 + i).toDouble());

String _fontSizeLabel(double size) => size.toInt().toString();

/// Stable label style for non-appearance form fields at extreme font sizes.
TextStyle controlTextStyle(TextStyle live) {
  return TextStyle(
    fontSize: (live.fontSize ?? 14).clamp(12.0, 18.0),
    fontWeight: FontWeight.bold,
    color: live.color,
  );
}

/// Font size + theme controls for Settings / Registration (no custom colour pickers).
class VisualSettingsPanel extends StatelessWidget {
  const VisualSettingsPanel({
    super.key,
    required this.bundle,
    this.overflowSafe = false,
    this.showDyslexiaSwitch = false,
    this.showHighContrastSwitch = false,
  });

  final ThemeBundle bundle;
  final bool overflowSafe;
  final bool showDyslexiaSwitch;
  final bool showHighContrastSwitch;

  AppSettings get _settings => AppRepositories.instance.settings;

  @override
  Widget build(BuildContext context) {
    final textStyle = overflowSafe
        ? controlTextStyle(bundle.textStyle)
        : bundle.textStyle;
    final secondaryColor = bundle.secondaryColor;
    final primaryColor = bundle.primaryColor;
    final fontSizeValue = kFontSizeOptions.contains(_settings.userFontSize)
        ? _settings.userFontSize
        : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommonUtils.buildDropdownButtonFormField(
          'Font Size',
          fontSizeValue,
          kFontSizeOptions,
          textStyle,
          secondaryColor,
          (val) {
            if (val != null) _settings.setUserFontSize(val);
          },
          displayText: _fontSizeLabel,
        ),
        CommonUtils.buildDropdownButtonFormField(
          'Theme',
          _settings.userTheme,
          const ['light', 'dark'],
          textStyle,
          secondaryColor,
          (val) => _settings.setUserTheme(val ?? 'light'),
        ),
        if (showDyslexiaSwitch)
          CommonUtils.buildSwitchListTile(
            'Dyslexia-friendly Font',
            textStyle,
            _settings.useDyslexiaFont,
            _settings.setUseDyslexiaFont,
            primaryColor,
            dense: overflowSafe,
            titleMaxLines: overflowSafe ? 2 : 1,
          ),
        if (showHighContrastSwitch)
          CommonUtils.buildSwitchListTile(
            'High Contrast Mode',
            textStyle,
            _settings.highContrastMode,
            _settings.setHighContrastMode,
            primaryColor,
            dense: overflowSafe,
            titleMaxLines: overflowSafe ? 2 : 1,
          ),
      ],
    );
  }
}

/// Shared appearance block (theme presets only — not custom reward colours).
class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({
    super.key,
    required this.bundle,
    this.showBottomDivider = true,
    this.overflowSafe = false,
    this.showDyslexiaSwitch = false,
    this.showHighContrastSwitch = false,
  });

  final ThemeBundle bundle;
  final bool showBottomDivider;
  final bool overflowSafe;
  final bool showDyslexiaSwitch;
  final bool showHighContrastSwitch;

  AppSettings get _settings => AppRepositories.instance.settings;

  @override
  Widget build(BuildContext context) {
    final textStyle = bundle.textStyle;
    final secondaryColor = bundle.secondaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: secondaryColor,
          child: CommonUtils.buildText(
            'This is a live preview of your visual settings.',
            textStyle,
          ),
        ),
        const Divider(),
        ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            return VisualSettingsPanel(
              bundle: currentThemeBundle(),
              overflowSafe: overflowSafe,
              showDyslexiaSwitch: showDyslexiaSwitch,
              showHighContrastSwitch: showHighContrastSwitch,
            );
          },
        ),
        if (showBottomDivider) const Divider(),
      ],
    );
  }
}
