// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/screens/registration_screen.dart';
import '../utils/BaseState.dart';
import '../utils/common_utils.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseState<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _rememberMe = false;
  final _storage = const FlutterSecureStorage();
  String showPasswordText = 'Show Password';
  bool hidePassword = true;
  final primaryColor = CommonUtils.getDefaultPrimaryColor();
  final secondaryColor = CommonUtils.getDefaultSecondaryColor();
  final textStyle = CommonUtils.getDefaultTextStyle();

  Future<void> _login() async {
    final storedUser = await _storage.read(key: 'username');
    final storedPass = await _storage.read(key: 'password');

    if (_userController.text == storedUser &&
        _passController.text == storedPass) {
      await setLoggedIn(true);
      if (_rememberMe) {
        await setRememberMe(true);
      }
      final isOnboardingComplete = (await checkOnboardingCompleted());
      if (!isOnboardingComplete) {
        debugPrint('Pushing to onboarding.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        debugPrint('Taking to dashboard instead.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else if (storedUser == null || storedPass == null) {
      CommonUtils.showSnackBar(context, 'You have not registered yet. Register an account.', textStyle, 1000, 5);
    } else {
      CommonUtils.showSnackBar(context, 'Invalid username or password', textStyle, 1500, 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            CommonUtils.buildTextField(_userController, 'Username', textStyle),
            CommonUtils.buildTextField(_passController, 'Password', textStyle, hideText: hidePassword),
            Row(
              children: [
                CommonUtils.buildSwitch(_rememberMe, (val) => setState(() => _rememberMe = val), primaryColor),
                CommonUtils.buildText('Remember Me', textStyle),
              ],
            ),
            CommonUtils.buildElevatedButton(showPasswordText, primaryColor, secondaryColor, textStyle, 0, 0,  () {
              setState(() {
                hidePassword = !hidePassword;
                showPasswordText = hidePassword ? 'Show Password' : 'Hide Password';
              });
            },
            ),
            const SizedBox(height: 20),
            CommonUtils.buildElevatedButton('Login', primaryColor, secondaryColor, textStyle, 1, 1, _login),
            //ElevatedButton(onPressed: _login, child: const Text('Login')),
            CommonUtils.buildElevatedButton('Register', primaryColor, secondaryColor, textStyle, 1, 1, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              );
            },
            ),
          ],
        ),
      ),
    );
  }
}
