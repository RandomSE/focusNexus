import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/customization_preview_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/screen_theme.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() =>
      _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen> {
  AppSettings get _settings => ref.read(appSettingsProvider.notifier).service;

  TextStyle _textStyleFor(Color primary) => _settings.textStyle(
        fontSize: _settings.userFontSize,
        color: primary,
        dyslexia: _settings.useDyslexiaFont,
      );

  List<Color> get _freeDefaultColors {
    // These are the built-in theme/contrast defaults. They should always be selectable for free.
    return const [
      // Light (normal)
      Colors.black87,
      Color(0xFFF2EFE6),
      // Dark (normal)
      Colors.white70,
      Colors.black,
      // High contrast (light)
      Color(0xFF004F52),
      Color(0xFFF2EFE6),
      // High contrast (dark)
      Colors.cyan,
      Colors.black,
    ];
  }

  bool _isFreeDefaultColor(Color color) {
    final int argb = color.toARGB32();
    return _freeDefaultColors.any((c) => c.toARGB32() == argb);
  }

  /// Shorter ratio → taller grid cells so swatch + label fit large / dyslexia text.
  double _colorShopChildAspectRatio(TextStyle textStyle) {
    final fontSize = textStyle.fontSize ?? 14;
    return (0.8 - (fontSize - 14) * 0.018).clamp(0.48, 0.8);
  }

  List<Color> get _selectableColors {
    final List<Color> combined = [
      ..._freeDefaultColors,
      ..._settings.allowedColors,
    ];
    final Map<int, Color> byArgb = <int, Color>{};
    for (final c in combined) {
      byArgb[c.toARGB32()] = c;
    }
    return byArgb.values.toList();
  }

  final Map<String, Map<String, dynamic>> _shopData = {
    'Crimson': {'color': const Color(0xFFDC143C), 'price': 50},
    'Slate Grey': {'color': const Color(0xFF708090), 'price': 100},
    'Goldenrod': {'color': const Color(0xFFDAA520), 'price': 250},
    'Chocolate': {'color': const Color(0xFFD2691E), 'price': 500},
    'Deep Orange': {'color': const Color(0xFFFF4500), 'price': 750},
    'Hot Pink': {'color': const Color(0xFFFF69B4), 'price': 1000},
    'Royal Blue': {'color': const Color(0xFF4169E1), 'price': 1500},
    'Teal': {'color': const Color(0xFF008080), 'price': 2500},
    'Amethyst': {'color': const Color(0xFF9966CC), 'price': 4000},
    'Forest Green': {'color': const Color(0xFF228B22), 'price': 6000},
  };

  Future<void>? _ensureColorsFuture;

  Future<void> _ensureDefaultColorsAllowed() async {
    final bundle = currentThemeBundle(ref);
    for (final c in [bundle.primaryColor, bundle.secondaryColor]) {
      if (!_settings.allowedColors.contains(c)) {
        await _settings.setAllowedColors(c);
      }
    }
  }

  Future<void> _purchaseColor(String name, int price, Color color) async {
    final preview = ref.read(customizationPreviewProvider);
    final textStyle = _textStyleFor(preview.previewPrimary);
    final points = ref.read(appRepositoriesProvider).points;
    if (_isFreeDefaultColor(color)) {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        "This color is already available by default",
        textStyle,
        2000,
        12,
      );
      return;
    }
    if (!_settings.allowedColors.contains(color)) {
      final spent = await points.trySpend(price);
      if (spent != null) {
        await _settings.setAllowedColors(color);
        if (!mounted) return;

        CommonUtils.showSnackBar(
          context,
          "Unlocked $name!",
          textStyle,
          2000,
          12,
        );
      } else {
        if (!mounted) return;
        CommonUtils.showSnackBar(
          context,
          "Not enough points! Need $price.",
          textStyle,
          2000,
          12,
        );
      }
    } else {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        "You already own this color",
        textStyle,
        2000,
        12,
      );
    }
  }

  Future<void> _openCustomColorPicker() async {
    const int customPrice = 10000;
    final preview = ref.read(customizationPreviewProvider);
    Color pickedColor = preview.previewPrimary;
    final textStyle = _textStyleFor(preview.previewPrimary);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Pick Custom Color ($customPrice pts)',
              style: textStyle,
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickedColor,
                onColorChanged: (color) => pickedColor = color,
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: textStyle),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Buy', style: textStyle),
                onPressed: () {
                  if (_isFreeDefaultColor(pickedColor)) {
                    Navigator.pop(context);
                    CommonUtils.showSnackBar(
                      context,
                      "That shade is already a default color",
                      textStyle,
                      2000,
                      12,
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _purchaseColor("Custom", customPrice, pickedColor);
                },
              ),
            ],
          ),
    );
  }

  void _selectColor(Color color, bool isPrimarySelection, ThemeBundle bundle) {
    ref
        .read(customizationPreviewProvider.notifier)
        .selectColor(
          color: color,
          isPrimary: isPrimarySelection,
          savedPrimary: bundle.primaryColor,
          savedSecondary: bundle.secondaryColor,
        );
  }

  void _revertPreviewToSaved() {
    ref.read(customizationPreviewProvider.notifier).revertToSaved();
  }

  void _revertPreviewToThemeDefaults() {
    final isDark = _settings.userTheme == 'dark';
    final contrast = _settings.highContrastMode;
    final defaultPrimary = contrast
        ? (isDark ? Colors.cyan : const Color(0xFF004F52))
        : (isDark ? Colors.white70 : Colors.black87);
    final defaultSecondary = contrast
        ? (isDark ? Colors.black : const Color(0xFFF2EFE6))
        : (isDark ? Colors.black : const Color(0xFFF2EFE6));

    ref
        .read(customizationPreviewProvider.notifier)
        .revertToDefaults(defaultPrimary, defaultSecondary);
  }

  Future<void> _saveCustomization() async {
    final preview = ref.read(customizationPreviewProvider);
    await _settings.setCustomizationEnabled(true);
    await _settings.setCustomizedColors(
      primaryColor: preview.previewPrimary,
      secondaryColor: preview.previewSecondary,
    );
    if (!mounted) return;
    ref.read(customizationPreviewProvider.notifier).markSaved();
    CommonUtils.showSnackBar(
      context,
      "Customization saved",
      _textStyleFor(preview.previewPrimary),
      2000,
      12,
    );
  }

  Future<bool> _onBackPressed() async {
    final preview = ref.read(customizationPreviewProvider);
    if (!preview.hasUnsavedChanges) return true;
    final textStyle = _textStyleFor(preview.previewPrimary);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Save changes?', style: textStyle),
            content: Text(
              'You have unsaved color changes. Save before leaving?',
              style: textStyle.copyWith(fontWeight: FontWeight.normal),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _revertPreviewToSaved();
                  Navigator.of(context).pop(true);
                },
                child: Text('Don\'t save', style: textStyle),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: textStyle),
              ),
              TextButton(
                onPressed: () async {
                  await _saveCustomization();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                },
                child: Text('Save', style: textStyle),
              ),
            ],
          ),
    );
    return shouldLeave ?? false;
  }

  ThemeData _previewThemeData(
    ThemeBundle bundle,
    Color primary,
    Color secondary,
  ) {
    return bundle.themeData.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: secondary,
      textTheme: bundle.themeData.textTheme.apply(
        bodyColor: primary,
        displayColor: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingsProvider);
    final settings = ref.watch(appSettingsProvider.notifier).service;
    final preview = ref.watch(customizationPreviewProvider);
    final pointsAsync = ref.watch(pointsBalanceProvider);
    _ensureColorsFuture ??= _ensureDefaultColorsAllowed();

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final useCustom = settings.customizationEnabled;
        final primary = useCustom && preview.hasUnsavedChanges
            ? preview.previewPrimary
            : bundle.primaryColor;
        final secondary = useCustom && preview.hasUnsavedChanges
            ? preview.previewSecondary
            : bundle.secondaryColor;
        final textStyle = _textStyleFor(primary);
        final pointsLabel = pointsAsync.when(
          data: (points) => 'Points: $points',
          loading: () => 'Points: …',
          error: (_, _) => 'Points: —',
        );

        return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed();
        if (!context.mounted) return;
        if (shouldPop) {
          Navigator.of(context).pushReplacementNamed('dashboard');
        }
      },
      child: Theme(
        data: _previewThemeData(bundle, primary, secondary),
        child: Scaffold(
          backgroundColor: secondary,
          appBar: AppBar(
            title: Text(
              'Customization',
              style: TextStyle(
                backgroundColor: secondary,
                color: primary,
              ),
            ),
            backgroundColor: secondary,
            iconTheme: IconThemeData(color: primary),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pointsLabel, style: textStyle),
                const SizedBox(height: 12),
                CommonUtils.buildSwitchListTile(
                  'Customized colours',
                  textStyle,
                  settings.customizationEnabled,
                  (value) async {
                    await settings.setCustomizationEnabled(value);
                    if (!mounted) return;
                    if (!value) {
                      ref.read(customizationPreviewProvider.notifier).markSaved();
                    } else {
                      ref
                          .read(customizationPreviewProvider.notifier)
                          .initFromBundle(bundle.primaryColor, bundle.secondaryColor);
                    }
                  },
                  primary,
                ),
                if (!settings.customizationEnabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CommonUtils.buildText(
                      'Theme and high contrast from Settings apply while this is off. '
                      'Turn on to pick custom text and background colours here.',
                      textStyle.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: (textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                  ),
                if (settings.customizationEnabled) ...[
                CommonUtils.buildText("Color Shop", textStyle),
                const SizedBox(height: 8),
                CommonUtils.buildText(
                  "Tap a swatch to unlock it.",
                  textStyle.copyWith(
                    fontSize: textStyle.fontSize! - 2,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    // Taller cells for large / dyslexia-friendly labels under the swatch.
                    childAspectRatio: _colorShopChildAspectRatio(textStyle),
                  ),
                  itemCount: _shopData.length,
                  itemBuilder: (context, index) {
                    String name = _shopData.keys.elementAt(index);
                    Color color = _shopData[name]!['color'];
                    int price = _shopData[name]!['price'];
                    bool isUnlocked = settings.allowedColors.contains(color);
                    final bool isFree = _isFreeDefaultColor(color);

                    return GestureDetector(
                      onTap:
                          (isUnlocked || isFree)
                              ? null
                              : () => _purchaseColor(name, price, color),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primary,
                                width: 2,
                              ),
                            ),
                            child:
                                isUnlocked
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    )
                                    : isFree
                                    ? const Icon(
                                      Icons.stars,
                                      color: Colors.white,
                                    )
                                    : const Icon(
                                      Icons.lock,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                          ),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: CommonUtils.buildText(
                                  isUnlocked
                                      ? "Owned"
                                      : (isFree ? "Free" : "$price"),
                                  textStyle.copyWith(
                                    fontSize: textStyle.fontSize! - 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: CommonUtils.buildElevatedButton(
                    "Unlock Custom Color (10,000 pts)",
                    primary,
                    secondary,
                    textStyle,
                    16,
                    12,
                    _openCustomColorPicker,
                  ),
                ),
                const SizedBox(height: 24),
                CommonUtils.buildText("Theme Preview", textStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonUtils.buildText(
                            "Primary",
                            textStyle.copyWith(
                              fontSize: textStyle.fontSize! - 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectableColors.map((color) {
                                  final bool selected =
                                      primary.toARGB32() ==
                                      color.toARGB32();
                                  final bool disabled =
                                      color.toARGB32() ==
                                      secondary.toARGB32();
                                  return GestureDetector(
                                    onTap: disabled
                                        ? null
                                        : () => _selectColor(color, true, bundle),
                                    child: Opacity(
                                      opacity: disabled ? 0.35 : 1,
                                      child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : primary,
                                          width: selected ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonUtils.buildText(
                            "Secondary",
                            textStyle.copyWith(
                              fontSize: textStyle.fontSize! - 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectableColors.map((color) {
                                  final bool selected =
                                      secondary.toARGB32() ==
                                      color.toARGB32();
                                  final bool disabled =
                                      color.toARGB32() ==
                                      primary.toARGB32();
                                  return GestureDetector(
                                    onTap: disabled
                                        ? null
                                        : () => _selectColor(color, false, bundle),
                                    child: Opacity(
                                      opacity: disabled ? 0.35 : 1,
                                      child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : primary,
                                          width: selected ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _revertPreviewToThemeDefaults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB00020),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Revert to Defaults",
                          style: textStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonUtils.buildElevatedButton(
                        "Save Changes",
                        primary,
                        secondary,
                        textStyle,
                        16,
                        12,
                        preview.hasUnsavedChanges ? _saveCustomization : null,
                      ),
                    ),
                  ],
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
