import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Minimum and maximum font sizes offered in Settings and Onboarding.
const double kMinFontSize = 10;
const double kMaxFontSize = 24;

/// Clamps [value] to the allowed font-size range.
double clampUserFontSize(double value) =>
    value.clamp(kMinFontSize, kMaxFontSize);

String _fontSizeLabel(double size) => size.toInt().toString();

/// Stable label style for non-appearance form fields at extreme font sizes.
TextStyle controlTextStyle(TextStyle live) {
  return TextStyle(
    fontSize: (live.fontSize ?? 14).clamp(12.0, 18.0),
    fontWeight: FontWeight.bold,
    color: live.color,
  );
}

class _FontSizeStepper extends StatelessWidget {
  const _FontSizeStepper({
    required this.currentSize,
    required this.textStyle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onAdjust,
  });

  final double currentSize;
  final TextStyle textStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final ValueChanged<int> onAdjust;

  @override
  Widget build(BuildContext context) {
    Widget stepButton(String label, int delta) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CommonUtils.buildElevatedButton(
            label,
            primaryColor,
            secondaryColor,
            textStyle,
            6,
            10,
            () => onAdjust(delta),
            borderColor: primaryColor,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Font size',
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _fontSizeLabel(currentSize),
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            stepButton('-5', -5),
            stepButton('-1', -1),
            stepButton('+1', 1),
            stepButton('+5', 5),
          ],
        ),
      ],
    );
  }
}

/// Font size + dark-mode controls for Settings / Registration / Onboarding.
class VisualSettingsPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingsProvider);
    final settings = ref.read(appSettingsProvider.notifier).service;
    final textStyle = overflowSafe
        ? controlTextStyle(bundle.textStyle)
        : bundle.textStyle;
    final secondaryColor = bundle.secondaryColor;
    final primaryColor = bundle.primaryColor;
    final fontSizeValue = clampUserFontSize(settings.userFontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        outlinedFormRow(
          _FontSizeStepper(
            currentSize: fontSizeValue,
            textStyle: textStyle,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            onAdjust: (delta) {
              final next = clampUserFontSize(fontSizeValue + delta);
              if (next == fontSizeValue) return;
              onAppearanceChange(() => settings.setUserFontSize(next));
            },
          ),
          textStyle,
        ),
        CommonUtils.buildSwitchListTile(
          'Dark mode',
          textStyle,
          settings.snapshot.isDark,
          (val) {
            onAppearanceChange(
              () => settings.setUserTheme(val ? 'dark' : 'light'),
            );
          },
          primaryColor,
          dense: overflowSafe,
          titleMaxLines: overflowSafe ? 2 : 1,
        ),
        if (showDyslexiaSwitch)
          CommonUtils.buildSwitchListTile(
            'Dyslexia-friendly Font',
            textStyle,
            settings.useDyslexiaFont,
            (val) =>
                onAppearanceChange(() => settings.setUseDyslexiaFont(val)),
            primaryColor,
            dense: overflowSafe,
            titleMaxLines: overflowSafe ? 2 : 1,
          ),
        if (showHighContrastSwitch)
          CommonUtils.buildSwitchListTile(
            'High Contrast Mode',
            textStyle,
            settings.highContrastMode,
            (val) => onAppearanceChange(
              () => settings.setHighContrastMode(val),
            ),
            primaryColor,
            dense: overflowSafe,
            titleMaxLines: overflowSafe ? 2 : 1,
          ),
      ],
    );
  }
}

/// Shared appearance block (theme presets only — not custom reward colours).
class AppearanceSettingsSection extends ConsumerWidget {
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

  Future<void> _onAppearanceChange(
    WidgetRef ref,
    Future<void> Function() apply,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    await apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveBundle = ref.watch(themeBundleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualSettingsPanel(
          bundle: liveBundle,
          overflowSafe: overflowSafe,
          showDyslexiaSwitch: showDyslexiaSwitch,
          showHighContrastSwitch: showHighContrastSwitch,
          onAppearanceChange: (apply) => _onAppearanceChange(ref, apply),
        ),
        if (showBottomDivider) const Divider(),
      ],
    );
  }
}
