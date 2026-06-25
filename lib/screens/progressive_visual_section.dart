import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_screen.dart';
import '../utils/screen_theme.dart';

/// Zen garden progressive visual section.
class ProgressiveVisualSectionScreen extends StatelessWidget {
  const ProgressiveVisualSectionScreen({super.key, required this.themeId});

  final VisualThemeId themeId;

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final title = visualThemeLabel(themeId);

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text(
                title,
                style: TextStyle(color: bundle.primaryColor),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: ZenGardenScreen(
              themeData: bundle.themeData,
              primaryColor: bundle.primaryColor,
              secondaryColor: bundle.secondaryColor,
              textStyle: bundle.textStyle,
            ),
          ),
        );
      },
    );
  }
}
