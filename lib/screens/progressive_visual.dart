import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/progressive_visual_section.dart';

/// Legacy progressive-visuals entry; routes now open Zen garden directly.
class ProgressiveVisualScreen extends StatelessWidget {
  const ProgressiveVisualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProgressiveVisualSectionScreen(
      themeId: VisualThemeId.zenGarden,
    );
  }
}
