import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  final _storage = const FlutterSecureStorage();

  Future<void> _saveUserPreferences() async {
    await _storage.write(key: 'name', value: _nameController.text);
    await _storage.write(key: 'email', value: _emailController.text);
    await _storage.write(key: 'age', value: _ageController.text);
    await _storage.write(key: 'notificationStyle', value: _notificationStyle);
    await _storage.write(key: 'frequency', value: _frequency);
    await _storage.write(key: 'tone', value: _tone);
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@\\s]+@[^@\\s]+\\.com\$').hasMatch(email);
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
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value != null && _isEmailValid(value)
                    ? null
                    : 'Enter a valid .com email',
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value != null && _isNumeric(value) ? null : 'Enter a valid age',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration:
                const InputDecoration(labelText: 'Notification Style'),
                items: ['Vibrant', 'Minimal', 'Animated']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _notificationStyle = value),
                validator: (value) =>
                value == null ? 'Select notification style' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: ['Low', 'Medium', 'High']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _frequency = value),
                validator: (value) =>
                value == null ? 'Select frequency' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tone'),
                items: ['Professional', 'Friendly', 'Casual']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _tone = value),
                validator: (value) => value == null ? 'Select tone' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _saveUserPreferences();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preferences saved securely')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Continue'),
              )
            ],
          ),
        ),
      ),
    );
  }
}