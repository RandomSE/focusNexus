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
  late ButtonStyle _buttonStyle;
  bool _themeLoaded = false;
  final _storage = const FlutterSecureStorage();
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
    // int currentPoints = int.tryParse(currentPointsStr) ?? 0; // TODO: uncomment this after testing.
    int currentPoints = 10000;
    debugPrint('Current color: $color');
    debugPrint('Listed colors: $allowedColors'); // TODO: CONT here. colors stored as int, not used as int.
    if (!allowedColors.contains(color)) { // check user doesn't already have.
      if (currentPoints >= price) {
        // Deduct points
        currentPoints -= price;
        await _storage.write(key: 'points', value: currentPoints.toString());

        // Add to allowed colors in BaseState
        await setAllowedColors(color);

        setState(() {
          _primaryColor = color;
          _textStyle = getTextStyle(userFontSize, color, useDyslexiaFont);
        });

        CommonUtils.showSnackBar(
            context, "Unlocked $name!", _textStyle, 2000, 12);
        setState(() {}); // Refresh UI to show as unlocked
      } else {
        CommonUtils.showSnackBar(
            context, "Not enough points! Need $price.", _textStyle, 2000, 12);
      }
    }
    else {
      CommonUtils.showSnackBar(
          context, "You already own this color", _textStyle, 2000, 12);
    }
  }

  Future<void> _openCustomColorPicker() async {
    const int customPrice = 10000;
    Color pickedColor = _primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick Custom Color ($customPrice pts)', style: _textStyle),
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
              Navigator.pop(context);
              _purchaseColor("Custom", customPrice, pickedColor);
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    if (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Theme(
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

                  return GestureDetector(
                    onTap: isUnlocked ? null : () =>
                        _purchaseColor(name, price, color),
                    child: Column(
                      children: [
                        Container(
                          width: 45, height: 45,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 2),
                          ),
                          child: isUnlocked
                              ? const Icon(Icons.check, color: Colors.white)
                              : const Icon(
                              Icons.lock, color: Colors.white70, size: 16),
                        ),
                        CommonUtils.buildText("$price", _textStyle),
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
                    _openCustomColorPicker
                ),
              ),
            ],
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
      _buttonStyle = themeBundle.buttonStyle;
      _themeLoaded = true;
    });
  }

}