// lib/screens/auth_start_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import '../utils/common_utils.dart';

class AuthStartScreen extends StatelessWidget {
  const AuthStartScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final primaryColor = CommonUtils.getDefaultPrimaryColor();
    final secondaryColor = CommonUtils.getDefaultSecondaryColor();
    final textStyle = CommonUtils.getDefaultTextStyle();
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to FocusNexus')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Get started with FocusNexus'),
            const SizedBox(height: 20),
            CommonUtils.buildElevatedButton('Register', primaryColor, secondaryColor, textStyle, 0, 0, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen()));
            }),
            const SizedBox(height: 10),
            CommonUtils.buildElevatedButton('Login', primaryColor, secondaryColor, textStyle, 0, 0, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }),
          ],
        ),
      ),
    );
  }
}