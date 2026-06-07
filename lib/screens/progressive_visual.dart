import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/utils/screen_theme.dart';

/// Entry point for progressive visuals: choose a metaphor, then open its section.
class ProgressiveVisualScreen extends StatelessWidget {
  const ProgressiveVisualScreen({super.key});

  void _openSection(BuildContext context, VisualThemeId id) {
    Navigator.pushNamed(
      context,
      'progressive_visual_section',
      arguments: id,
    );
  }

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
                'Progressive visuals',
                style: TextStyle(color: bundle.primaryColor),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: VisualThemeId.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final id = VisualThemeId.values[index];
                final label = visualThemeLabel(id);
                final blurb = _blurb(id);
                return Material(
                  color: bundle.secondaryColor,
                  child: ListTile(
                    title: Text(label, style: bundle.textStyle),
                    subtitle: Text(
                      blurb,
                      style: bundle.textStyle.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: (bundle.textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: bundle.primaryColor),
                    onTap: () => _openSection(context, id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _blurb(VisualThemeId id) => switch (id) {
        VisualThemeId.zenGarden =>
          'Grow plants and decor in a calm sandbox garden.',
        _ => 'Coming soon.',
      };
}
