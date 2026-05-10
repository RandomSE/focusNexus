import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_screen.dart';
import 'package:focusNexus/utils/BaseState.dart';

import '../utils/common_utils.dart';

/// One metaphor’s sandbox / growth view (bonsai, coral, etc.).
class ProgressiveVisualSectionScreen extends StatefulWidget {
  const ProgressiveVisualSectionScreen({super.key, required this.themeId});

  final VisualThemeId themeId;

  @override
  State<ProgressiveVisualSectionScreen> createState() =>
      _ProgressiveVisualSectionScreenState();
}

class _ProgressiveVisualSectionScreenState extends BaseState<ProgressiveVisualSectionScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = visualThemeLabel(widget.themeId);

    return Theme(
      data: _themeData,
      child: Scaffold(
        backgroundColor: _secondaryColor,
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(color: _primaryColor),
          ),
          backgroundColor: _secondaryColor,
          iconTheme: IconThemeData(color: _primaryColor),
        ),
        body: switch (widget.themeId) {
          VisualThemeId.zenGarden => ZenGardenScreen(
              themeData: _themeData,
              primaryColor: _primaryColor,
              secondaryColor: _secondaryColor,
              textStyle: _textStyle,
            ),
          _ => Container(
              color: _secondaryColor,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonUtils.buildText(
                    'Growth stages and sandbox for this visual will appear here.',
                    _textStyle,
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildText(
                    'Theme: ${widget.themeId.name}',
                    _textStyle,
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}

String visualThemeLabel(VisualThemeId id) {
  return switch (id) {
    VisualThemeId.zenGarden => 'Zen garden',
    VisualThemeId.bonsai => 'Bonsai',
    VisualThemeId.coralReef => 'Coral reef',
    VisualThemeId.constellation => 'Constellation sky',
    VisualThemeId.sandGarden => 'Zen sand garden',
  };
}
