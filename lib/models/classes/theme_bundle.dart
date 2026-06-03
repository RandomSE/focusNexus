import 'package:flutter/material.dart';

class ThemeBundle {
  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final TextStyle textStyle;
  final ButtonStyle buttonStyle;

  ThemeBundle({
    required this.themeData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textStyle,
    required this.buttonStyle,
  });

  @override
  String toString() {
    return 'ThemeBundle(themeData: $themeData, \n primaryColor: $primaryColor, \n secondaryColor: $secondaryColor, \n accentColor: $accentColor, \n textStyle: $textStyle, buttonStyle: \n $buttonStyle)';
  }
}
