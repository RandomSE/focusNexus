import 'package:flutter/material.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';

class MiniGamesScreen extends StatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  State<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends State<MiniGamesScreen> {
  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text(
                'Mini-games',
                style: TextStyle(
                  backgroundColor: bundle.secondaryColor,
                  color: bundle.primaryColor,
                ),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: Container(
              color: bundle.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  CommonUtils.buildText('Test 1', bundle.textStyle),
                  CommonUtils.buildText('Test 2', bundle.textStyle),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
