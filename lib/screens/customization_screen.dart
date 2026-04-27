import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/common_utils.dart';

import '../models/classes/theme_bundle.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends BaseState<CustomizationScreen> {
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  bool _themeLoaded = false;
  bool _hasUnsavedChanges = false;
  final _storage = const FlutterSecureStorage();
  late Color _savedPrimaryColor;
  late Color _savedSecondaryColor;
  late Color _previewPrimaryColor;
  late Color _previewSecondaryColor;

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

  List<Color> get _selectableColors {
    final List<Color> combined = [..._freeDefaultColors, ...allowedColors];
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

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _purchaseColor(String name, int price, Color color) async {
    final currentPointsStr = await _storage.read(key: 'points') ?? '0';
    int currentPoints = int.tryParse(currentPointsStr) ?? 0;
    if (_isFreeDefaultColor(color)) {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        "This color is already available by default",
        _textStyle,
        2000,
        12,
      );
      return;
    }
    if (!allowedColors.contains(color)) {
      // check user doesn't already have.
      if (currentPoints >= price) {
        // Deduct points
        currentPoints -= price;
        await _storage.write(key: 'points', value: currentPoints.toString());

        // Add to allowed colors in BaseState
        await setAllowedColors(color);
        if (!mounted) return;

        CommonUtils.showSnackBar(
          context,
          "Unlocked $name!",
          _textStyle,
          2000,
          12,
        );
        if (mounted) setState(() {}); // Refresh UI to show as unlocked
      } else {
        if (!mounted) return;
        CommonUtils.showSnackBar(
          context,
          "Not enough points! Need $price.",
          _textStyle,
          2000,
          12,
        );
      }
    } else {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        "You already own this color",
        _textStyle,
        2000,
        12,
      );
    }
  }

  Future<void> _openCustomColorPicker() async {
    const int customPrice = 10000;
    Color pickedColor = _previewPrimaryColor;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Pick Custom Color ($customPrice pts)',
              style: _textStyle,
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickedColor,
                onColorChanged: (color) => pickedColor = color,
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: _textStyle),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Buy', style: _textStyle),
                onPressed: () {
                  if (_isFreeDefaultColor(pickedColor)) {
                    Navigator.pop(context);
                    CommonUtils.showSnackBar(
                      context,
                      "That shade is already a default color",
                      _textStyle,
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

  void _selectColor(Color color, bool isPrimarySelection) {
    setState(() {
      if (isPrimarySelection) {
        _previewPrimaryColor = color;
      } else {
        _previewSecondaryColor = color;
      }
      _applyPreviewThemeToScreen();
      _hasUnsavedChanges =
          _previewPrimaryColor != _savedPrimaryColor ||
          _previewSecondaryColor != _savedSecondaryColor;
    });
  }

  void _applyPreviewThemeToScreen() {
    _primaryColor = _previewPrimaryColor;
    _secondaryColor = _previewSecondaryColor;
    _textStyle = getTextStyle(
      userFontSize,
      _previewPrimaryColor,
      useDyslexiaFont,
    );
    _themeData = _themeData.copyWith(
      primaryColor: _previewPrimaryColor,
      scaffoldBackgroundColor: _previewSecondaryColor,
      textTheme: _themeData.textTheme.apply(
        bodyColor: _previewPrimaryColor,
        displayColor: _previewPrimaryColor,
      ),
    );
  }

  void _revertPreviewToSaved() {
    setState(() {
      _previewPrimaryColor = _savedPrimaryColor;
      _previewSecondaryColor = _savedSecondaryColor;
      _applyPreviewThemeToScreen();
      _hasUnsavedChanges = false;
    });
  }

  void _revertPreviewToThemeDefaults() {
    final bool isDark = userTheme == 'dark';
    final bool contrast = highContrastMode;

    final Color defaultPrimary =
        contrast
            ? (isDark ? Colors.cyan : const Color(0xFF004F52))
            : (isDark ? Colors.white70 : Colors.black87);

    final Color defaultSecondary =
        contrast
            ? (isDark ? Colors.black : const Color(0xFFF2EFE6))
            : (isDark ? Colors.black : const Color(0xFFF2EFE6));

    setState(() {
      _previewPrimaryColor = defaultPrimary;
      _previewSecondaryColor = defaultSecondary;
      _applyPreviewThemeToScreen();
      _hasUnsavedChanges =
          _previewPrimaryColor != _savedPrimaryColor ||
          _previewSecondaryColor != _savedSecondaryColor;
    });
  }

  Future<void> _saveCustomization() async {
    await setCustomizationEnabled(true);
    await setCustomizedColors(
      primaryColor: _previewPrimaryColor,
      secondaryColor: _previewSecondaryColor,
    );
    if (!mounted) return;
    setState(() {
      _savedPrimaryColor = _previewPrimaryColor;
      _savedSecondaryColor = _previewSecondaryColor;
      _hasUnsavedChanges = false;
    });
    CommonUtils.showSnackBar(
      context,
      "Customization saved",
      _textStyle,
      2000,
      12,
    );
  }

  Future<bool> _onBackPressed() async {
    if (!_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Save changes?', style: _textStyle),
            content: Text(
              'You have unsaved color changes. Save before leaving?',
              style: _textStyle.copyWith(fontWeight: FontWeight.normal),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _revertPreviewToSaved();
                  Navigator.of(context).pop(true);
                },
                child: Text('Don\'t save', style: _textStyle),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: _textStyle),
              ),
              TextButton(
                onPressed: () async {
                  await _saveCustomization();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                },
                child: Text('Save', style: _textStyle),
              ),
            ],
          ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    if (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

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
        data: _themeData,
        child: Scaffold(
          backgroundColor: _secondaryColor,
          appBar: AppBar(
            title: Text(
              'Customization',
              style: TextStyle(
                backgroundColor: _secondaryColor,
                color: _primaryColor,
              ),
            ),
            backgroundColor: _secondaryColor,
            iconTheme: IconThemeData(color: _primaryColor),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonUtils.buildText("Color Shop", _textStyle),
                const SizedBox(height: 8),
                CommonUtils.buildText(
                  "Tap a swatch to unlock it.",
                  _textStyle.copyWith(
                    fontSize: _textStyle.fontSize! - 2,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _shopData.length,
                  itemBuilder: (context, index) {
                    String name = _shopData.keys.elementAt(index);
                    Color color = _shopData[name]!['color'];
                    int price = _shopData[name]!['price'];
                    bool isUnlocked = allowedColors.contains(color);
                    final bool isFree = _isFreeDefaultColor(color);

                    return GestureDetector(
                      onTap:
                          (isUnlocked || isFree)
                              ? null
                              : () => _purchaseColor(name, price, color),
                      child: Column(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _primaryColor,
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
                          CommonUtils.buildText(
                            isUnlocked ? "Owned" : (isFree ? "Free" : "$price"),
                            _textStyle.copyWith(
                              fontSize: _textStyle.fontSize! - 1,
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
                    _primaryColor,
                    _secondaryColor, // Or a gradient style
                    _textStyle,
                    16,
                    12,
                    _openCustomColorPicker,
                  ),
                ),
                const SizedBox(height: 24),
                CommonUtils.buildText("Theme Preview", _textStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonUtils.buildText(
                            "Primary",
                            _textStyle.copyWith(
                              fontSize: _textStyle.fontSize! - 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectableColors.map((color) {
                                  final bool selected =
                                      _previewPrimaryColor.toARGB32() ==
                                      color.toARGB32();
                                  return GestureDetector(
                                    onTap: () => _selectColor(color, true),
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
                                                  : _primaryColor,
                                          width: selected ? 3 : 1.5,
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
                            _textStyle.copyWith(
                              fontSize: _textStyle.fontSize! - 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectableColors.map((color) {
                                  final bool selected =
                                      _previewSecondaryColor.toARGB32() ==
                                      color.toARGB32();
                                  return GestureDetector(
                                    onTap: () => _selectColor(color, false),
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
                                                  : _primaryColor,
                                          width: selected ? 3 : 1.5,
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
                          style: _textStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonUtils.buildElevatedButton(
                        "Save Changes",
                        _primaryColor,
                        _secondaryColor,
                        _textStyle,
                        16,
                        12,
                        _hasUnsavedChanges ? _saveCustomization : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadScreen() async {
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);
  }

  Future<void> setThemeDataScreen(ThemeBundle themeBundle) async {
    setState(() {
      _themeData = themeBundle.themeData;
      _primaryColor = themeBundle.primaryColor;
      _secondaryColor = themeBundle.secondaryColor;
      _textStyle = themeBundle.textStyle;
      _savedPrimaryColor = _primaryColor;
      _savedSecondaryColor = _secondaryColor;
      _previewPrimaryColor = _primaryColor;
      _previewSecondaryColor = _secondaryColor;
      if (!allowedColors.contains(_primaryColor)) {
        allowedColors.add(_primaryColor);
      }
      if (!allowedColors.contains(_secondaryColor)) {
        allowedColors.add(_secondaryColor);
      }
      _themeLoaded = true;
    });
  }
}
