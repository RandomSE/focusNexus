// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _notificationStyle;
  String? _frequency;
  String? _tone;
  String? _username;
  String? _password;
  String? _confirmPassword;
  String? _rewardType;
  String showPasswordText = 'Show Password';
  bool hidePassword = true;
  int passwordMinimumLength = 6;

  final _storage = const FlutterSecureStorage();

  Future<void> _saveUserPreferences() async {
    await _storage.write(key: 'name', value: _nameController.text); // TODO: use this on email for personalization.
    await _storage.write(key: 'email', value: _emailController.text); // TODO: use this to validate email.  change registration flow slightly to ask if they would like to receive emails, and a setting in settings to change this.
    await _storage.write(key: 'age', value: _ageController.text);
    await _storage.write(key: 'notificationStyle', value: _notificationStyle);
    await _storage.write(key: 'notificationFrequency', value: _frequency);
    await _storage.write(key: 'tone', value: _tone);
    await _storage.write(key: 'rewardType', value: _rewardType);
    await _storage.write(key: 'username', value: _username);
    await _storage.write(key: 'password', value: _password);
    await _storage.write(key: 'onboardingCompleted', value: 'false');
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@]+@[^@]+\.(com)$').hasMatch(email);
  }

  bool _isNumeric(String input) => int.tryParse(input) != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter your name'
                            : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value != null && _isEmailValid(value)
                            ? null
                            : 'Enter a valid .com email',
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || !_isNumeric(value)) {
                    return 'Enter a valid age';
                  }

                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 130) {
                    return 'Enter a valid age between 1 and 130';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Notification Frequency'),
                items: ['Low', 'Medium', 'High', 'No notifications']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                value: _frequency,
                onChanged: (value) {
                  setState(() {
                    _frequency = value;
                    if (value == 'No notifications') {
                      _notificationStyle = 'Minimal'; // Default fallback
                    } else {
                      _notificationStyle = null; // Reset to force user selection
                    }
                  });
                },
                validator: (value) => value == null ? 'Select frequency' : null,
              ),

              if (_frequency != null && _frequency != 'No notifications')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Notification Style'),
                  items: ['Vibrant', 'Minimal', 'Animated']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  value: _notificationStyle,
                  onChanged: (value) => setState(() => _notificationStyle = value),
                  validator: (value) => value == null ? 'Select notification style' : null,
                ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reward type'),
                items: ['Avatar', 'Mini-games', 'leaderboard']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                value: ['Avatar', 'Mini-games', 'leaderboard'].contains(_rewardType)
                    ? _rewardType
                    : null,
                onChanged: (value) => setState(() => _rewardType = value),
                validator: (value) => value == null ? 'Select reward type' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter a username'
                            : null,
                onChanged: (val) => _username = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: hidePassword,
                validator:
                    (value) =>
                        value == null || value.length < passwordMinimumLength
                            ? 'Password must be at least $passwordMinimumLength characters'
                            : null,
                onChanged: (val) => _password = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: hidePassword,
                validator: (v) {
                  if (v == null || v.length < passwordMinimumLength) return 'Password must be at least $passwordMinimumLength characters';
                  if (v != _password) return 'Passwords do not match';
                  return null;
                },
              onChanged: (val) => _confirmPassword = val,
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
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _saveUserPreferences();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferences saved securely'),
                      ),
                    );
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
