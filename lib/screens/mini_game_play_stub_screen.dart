import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Play stub: accepts round config, does not call recordScore.
class MiniGamePlayStubScreen extends ConsumerWidget {
  const MiniGamePlayStubScreen({super.key, required this.config});

  final MiniGameRoundConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text(
                'Play',
                style: TextStyle(color: bundle.primaryColor),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(bundle.primaryColor),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonUtils.buildText('Coming soon', bundle.textStyle),
                  const SizedBox(height: 8),
                  CommonUtils.buildText(
                    config.endless ? 'Mode: Endless' : 'Mode: Duration',
                    bundle.textStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
