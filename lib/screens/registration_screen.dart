// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/common_utils.dart';
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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _notificationStyle;
  String? _frequency;
  String? _tone;
  String? _rewardType;
  String showPasswordText = 'Show Password';
  bool hidePassword = true;
  int passwordMinimumLength = 6;
  final notificationFrequencies = ['Low', 'Medium', 'High', 'No notifications'];
  final notificationStyles =  ['Vibrant', 'Minimal', 'Animated'];
  final rewardTypes = ['Mini-games', 'Progressive visuals', 'Customization'];

  final primaryColor = CommonUtils.getDefaultPrimaryColor();
  final secondaryColor = CommonUtils.getDefaultSecondaryColor();
  final textStyle = CommonUtils.getDefaultTextStyle();

  final _storage = const FlutterSecureStorage();

  Future<void> _saveUserPreferences() async {
    debugPrint('Saving user preferences...');
    await _storage.write(key: 'name', value: _nameController.text); // TODO: use this on email for personalization.
    await _storage.write(key: 'email', value: _emailController.text); // TODO: use this to validate email.  change registration flow slightly to ask if they would like to receive emails, and a setting in settings to change this.
    await _storage.write(key: 'age', value: _ageController.text);
    await _storage.write(key: 'notificationStyle', value: _notificationStyle);
    await _storage.write(key: 'notificationFrequency', value: _frequency);
    await _storage.write(key: 'tone', value: _tone);
    await _storage.write(key: 'rewardType', value: _rewardType);
    await _storage.write(key: 'username', value: _usernameController.text);
    await _storage.write(key: 'password', value: _passwordController.text);
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
              CommonUtils.buildTextFormField(_nameController, 'Full Name', textStyle, secondaryColor, true, (value) =>
              value == null || value.isEmpty
                  ? 'Enter your name'
                  : null,
              ),
              CommonUtils.buildTextFormField(_emailController, 'Email', textStyle, secondaryColor, true, (value) =>
              value != null && _isEmailValid(value)
                  ? null
                  : 'Enter a valid .com email',
              ),
              CommonUtils.buildTextFormField(_ageController, 'Age in years', textStyle, secondaryColor, true, (value) {
                if (value == null || !_isNumeric(value)) {
                  return 'Enter a valid, numeric age';
                }

                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 130) {
                  return 'Enter a valid, numeric age between 1 and 130';
                }

                return null;
              },
              ),

              const SizedBox(height: 20),
              CommonUtils.buildDropdownButtonFormField('Notification Frequency', _frequency, notificationFrequencies, textStyle, secondaryColor, (value) {
                setState(() {
                  _frequency = value;
                  if (value == 'No notifications') {
                    _notificationStyle = 'Minimal'; // Default fallback
                  } else {
                    _notificationStyle = null; // Reset to force user selection
                  }
                });
              },
                validator: (value) => value == null ? 'Select frequency' : null),

              if (_frequency != null && _frequency != 'No notifications')
                CommonUtils.buildDropdownButtonFormField('Notification Style', _notificationStyle, notificationStyles, textStyle, secondaryColor, (value) => setState(() => _notificationStyle = value),
                validator: (value) => value == null ? 'Select notification style' : null),

              CommonUtils.buildDropdownButtonFormField('Reward type', _rewardType, rewardTypes, textStyle, secondaryColor, (value) => setState(() => _rewardType = value),
              validator: (value) => value == null ? 'Select reward type' : null),

              CommonUtils.buildTextFormField(_usernameController, 'Username', textStyle, secondaryColor, true, (value) =>
              value == null || value.isEmpty
                  ? 'Enter a username'
                  : null),

              CommonUtils.buildTextFormField(_passwordController, 'Password', textStyle, secondaryColor, true, (value) =>
              value == null || value.length < passwordMinimumLength
                  ? 'Password must be at least $passwordMinimumLength characters'
                  : null, hideText:hidePassword),

              CommonUtils.buildTextFormField(_confirmPasswordController, 'Confirm password', textStyle, secondaryColor, true, (v) {
                if (v == null || v.length < passwordMinimumLength) return 'Password must be at least $passwordMinimumLength characters';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              }, hideText: hidePassword),

              CommonUtils.buildElevatedButton(showPasswordText, primaryColor, secondaryColor, textStyle, 0, 0, () {
                setState(() {
                  hidePassword = !hidePassword;
                  showPasswordText = hidePassword ? 'Show Password' : 'Hide Password';
                });
              },
              ),

              const SizedBox(height: 30),

              CommonUtils.buildElevatedButton('Continue', primaryColor, secondaryColor, textStyle, 0, 0, () async {
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
              },),
            ],
          ),
        ),
      ),
    );
  }
}
