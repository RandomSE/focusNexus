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

/// Font size + dark-mode controls for Settings / Registration / Onboarding.
class VisualSettingsPanel extends StatefulWidget {
  const VisualSettingsPanel({
    super.key,
    required this.bundle,
    this.overflowSafe = false,
    this.showDyslexiaSwitch = false,
    this.showHighContrastSwitch = false,
    required this.onAppearanceChange,
  });

  final ThemeBundle bundle;
  final bool overflowSafe;
  final bool showDyslexiaSwitch;
  final bool showHighContrastSwitch;
  final Future<void> Function(Future<void> Function() apply) onAppearanceChange;

  @override
  State<VisualSettingsPanel> createState() => _VisualSettingsPanelState();
}

class _VisualSettingsPanelState extends State<VisualSettingsPanel> {
  AppSettings get _settings => AppRepositories.instance.settings;

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.overflowSafe
        ? controlTextStyle(widget.bundle.textStyle)
        : widget.bundle.textStyle;
    final secondaryColor = widget.bundle.secondaryColor;
    final primaryColor = widget.bundle.primaryColor;
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
            if (val == null) return;
            widget.onAppearanceChange(() => _settings.setUserFontSize(val));
          },
          displayText: _fontSizeLabel,
        ),
        CommonUtils.buildSwitchListTile(
          'Dark mode',
          textStyle,
          _settings.snapshot.isDark,
          (val) {
            widget.onAppearanceChange(
              () => _settings.setUserTheme(val ? 'dark' : 'light'),
            );
          },
          primaryColor,
          dense: widget.overflowSafe,
          titleMaxLines: widget.overflowSafe ? 2 : 1,
        ),
        if (widget.showDyslexiaSwitch)
          CommonUtils.buildSwitchListTile(
            'Dyslexia-friendly Font',
            textStyle,
            _settings.useDyslexiaFont,
            (val) =>
                widget.onAppearanceChange(() => _settings.setUseDyslexiaFont(val)),
            primaryColor,
            dense: widget.overflowSafe,
            titleMaxLines: widget.overflowSafe ? 2 : 1,
          ),
        if (widget.showHighContrastSwitch)
          CommonUtils.buildSwitchListTile(
            'High Contrast Mode',
            textStyle,
            _settings.highContrastMode,
            (val) => widget.onAppearanceChange(
              () => _settings.setHighContrastMode(val),
            ),
            primaryColor,
            dense: widget.overflowSafe,
            titleMaxLines: widget.overflowSafe ? 2 : 1,
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

  Future<void> _onAppearanceChange(Future<void> Function() apply) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    await apply();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            return VisualSettingsPanel(
              bundle: currentThemeBundle(),
              overflowSafe: overflowSafe,
              showDyslexiaSwitch: showDyslexiaSwitch,
              showHighContrastSwitch: showHighContrastSwitch,
              onAppearanceChange: _onAppearanceChange,
            );
          },
        ),
        if (showBottomDivider) const Divider(),
      ],
    );
  }
}
