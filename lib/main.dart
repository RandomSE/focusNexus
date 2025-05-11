// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/auth_start_screen.dart';

void main() {
  runApp(const FocusNexusApp());
}

class FocusNexusApp extends StatelessWidget {
  const FocusNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthStartScreen(),
    );
  }
}
