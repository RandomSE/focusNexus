// lib/screens/auth_start_screen.dart
import 'package:flutter/material.dart';
import 'registration_screen.dart';
import '../utils/common_utils.dart';

/// Fixed light welcome styling — independent of persisted user theme.
class AuthStartScreen extends StatelessWidget {
  const AuthStartScreen({super.key});

  static const Color _scaffoldColor = Color(0xFFF2EFE6);
  static const Color _primaryColor = Colors.black87;

  static TextStyle _textStyle({FontWeight? weight}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: weight ?? FontWeight.bold,
      color: _primaryColor,
    );
  }

  static ThemeData _welcomeTheme() {
    final textStyle = _textStyle();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _scaffoldColor,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        onPrimary: _scaffoldColor,
        surface: _scaffoldColor,
        onSurface: _primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _scaffoldColor,
        foregroundColor: _primaryColor,
        elevation: 0,
        titleTextStyle: textStyle,
      ),
      textTheme: TextTheme(
        bodyMedium: textStyle,
        titleMedium: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _textStyle();
    final bodyStyle = _textStyle(weight: FontWeight.normal);

    return Theme(
      data: _welcomeTheme(),
      child: Scaffold(
        backgroundColor: _scaffoldColor,
        appBar: AppBar(
          title: Text('Welcome to FocusNexus', style: textStyle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get started with FocusNexus', style: textStyle),
                const SizedBox(height: 12),
                Text(
                  'One profile per device - set your preferences to begin.',
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CommonUtils.buildElevatedButton(
                  'Get started',
                  _primaryColor,
                  _scaffoldColor,
                  textStyle,
                  0,
                  0,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
