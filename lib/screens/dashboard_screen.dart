// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

import '../models/classes/achievement_tracking_variables.dart';
import '../repositories/app_repositories.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';
import '../services/achievement_service.dart';
import '../utils/screen_theme.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/settings_themed_builder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _settings = AppRepositories.instance.settings;
  int _points = 0;
  bool _servicesReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPoints();
    await AchievementTrackingVariables().initializeIfNeeded();
    await AchievementService().initialize();
    GoalNotifier.initialize();
    if (mounted) setState(() => _servicesReady = true);
  }

  Future<void> _loadPoints() async {
    final value = await AppRepositories.instance.points.ensureInitialized();
    if (mounted) setState(() => _points = value);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        if (!_servicesReady) {
          return themedLoadingShell(
            bundle,
            title: 'Dashboard',
            body: DashboardSkeleton(bundle: bundle),
          );
        }
        final rewardType = _settings.rewardType;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Dashboard',
                style: bundle.textStyle,
                textAlign: TextAlign.center,
              ),
              backgroundColor: bundle.secondaryColor,
            ),
            backgroundColor: bundle.secondaryColor,
            body: Container(
              color: bundle.secondaryColor,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Points: $_points',
                      style: bundle.textStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 60),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Settings',
                    () => Navigator.pushNamed(context, 'settings')
                        .then((_) => _loadPoints()),
                    bundle.textStyle,
                    bundle.secondaryColor,
                  ),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Reward: $rewardType',
                    () => Navigator.pushNamed(context, 'reward'),
                    bundle.textStyle,
                    bundle.secondaryColor,
                  ),
                  CommonUtils.buildCenteredButton(
                    context,
                    'AI Assistant',
                    () async {
                      final proceed =
                          await CommonUtils.showInteractableAlertDialog(
                        context,
                        'AI Chat Screen',
                        '',
                        bundle.textStyle,
                        bundle.secondaryColor,
                        actions: [
                          CommonUtils.buildTextButton(
                            () => Navigator.pop(context, false),
                            'Cancel',
                            bundle.textStyle,
                          ),
                          CommonUtils.buildTextButton(
                            () => Navigator.pop(context, true),
                            'OK',
                            bundle.textStyle,
                          ),
                        ],
                        content: SingleChildScrollView(
                          child: Text(
                            'By continuing, you acknowledge that you use this AI chat at your own discretion and responsibility. '
                            'It is for general informational and supportive purposes only, and not a substitute for professional medical, psychological, or therapeutic advice. '
                            'Do not rely on it for decisions regarding your health, safety, or wellbeing.',
                            style: bundle.textStyle,
                          ),
                        ),
                      );
                      if (proceed == true && context.mounted) {
                        Navigator.pushNamed(context, 'chat');
                      }
                    },
                    bundle.textStyle,
                    bundle.secondaryColor,
                  ),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Achievements',
                    () => Navigator.pushNamed(context, 'achievements'),
                    bundle.textStyle,
                    bundle.secondaryColor,
                  ),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Goal Setting',
                    () => Navigator.pushNamed(context, 'goals')
                        .then((_) => _loadPoints()),
                    bundle.textStyle,
                    bundle.secondaryColor,
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
