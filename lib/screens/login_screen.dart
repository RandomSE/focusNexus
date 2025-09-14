// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _rememberMe = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _login() async {
    final storedUser = await _storage.read(key: 'username');
    final storedPass = await _storage.read(key: 'password');

    if (_userController.text == storedUser &&
        _passController.text == storedPass) {
      if (_rememberMe) {
        await _storage.write(key: 'loggedIn', value: 'true');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
              obscureText: true,
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
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
