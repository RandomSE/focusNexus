import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_screen.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';

/// One metaphor’s sandbox / growth view (bonsai, coral, etc.).
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
            body: switch (themeId) {
              VisualThemeId.zenGarden => ZenGardenScreen(
                  themeData: bundle.themeData,
                  primaryColor: bundle.primaryColor,
                  secondaryColor: bundle.secondaryColor,
                  textStyle: bundle.textStyle,
                ),
              _ => Container(
                  color: bundle.secondaryColor,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonUtils.buildText(
                        'Growth stages and sandbox for this visual will appear here.',
                        bundle.textStyle,
                      ),
                    ],
                  ),
                ),
            },
          ),
        );
      },
    );
  }
}
