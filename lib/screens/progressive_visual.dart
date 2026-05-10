import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/progressive_visual_section.dart';
import 'package:focusNexus/utils/BaseState.dart';

/// Entry point for progressive visuals: choose a metaphor, then open its section.
class ProgressiveVisualScreen extends StatefulWidget {
  const ProgressiveVisualScreen({super.key});

  @override
  State<ProgressiveVisualScreen> createState() => _ProgressiveVisualScreenState();
}

class _ProgressiveVisualScreenState extends BaseState<ProgressiveVisualScreen> {
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  bool _themeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    final themeBundle = await initializeScreenTheme();
    if (mounted) {
      setState(() {
        _themeData = themeBundle.themeData;
        _primaryColor = themeBundle.primaryColor;
        _secondaryColor = themeBundle.secondaryColor;
        _textStyle = themeBundle.textStyle;
        _themeLoaded = true;
      });
    }
  }

  void _openSection(VisualThemeId id) {
    Navigator.pushNamed(
      context,
      'progressive_visual_section',
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Theme(
      data: _themeData,
      child: Scaffold(
        backgroundColor: _secondaryColor,
        appBar: AppBar(
          title: Text(
            'Progressive visuals',
            style: TextStyle(color: _primaryColor),
          ),
          backgroundColor: _secondaryColor,
          iconTheme: IconThemeData(color: _primaryColor),
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
              color: _secondaryColor,
              child: ListTile(
                title: Text(label, style: _textStyle),
                subtitle: Text(
                  blurb,
                  style: _textStyle.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: (_textStyle.fontSize ?? 14) * 0.92,
                  ),
                ),
                onTap: () => _openSection(id),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _blurb(VisualThemeId id) {
  return switch (id) {
    VisualThemeId.zenGarden => 'Calm plants and stones; gentle growth stages.',
    VisualThemeId.bonsai => 'Shaped growth; patient, structured progression.',
    VisualThemeId.coralReef => 'Underwater colony; same stages, ocean palette.',
    VisualThemeId.constellation => 'Stars and links; sky metaphor for milestones.',
    VisualThemeId.sandGarden => 'Raked patterns and focal points; minimal motion.',
  };
}
