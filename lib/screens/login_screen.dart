// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/screens/registration_screen.dart';
import '../utils/BaseState.dart';
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

  Future<void> _login() async {
    final storedUser = await _storage.read(key: 'username');
    final storedPass = await _storage.read(key: 'password');
    debugPrint('storedUser: $storedUser, storedPass: $storedPass');

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have not registered yet. Register an account.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
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
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: hidePassword,
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged:
                      (val) => setState(() => _rememberMe = val ?? false),
                ),
                const Text('Remember me'),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  hidePassword = !hidePassword;
                  showPasswordText = hidePassword ? 'Show Password' : 'Hide Password';
                });
              },
              child: Text(showPasswordText),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
