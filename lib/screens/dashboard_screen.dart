// lib/screens/dashboard_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsBalanceProvider);
    final settings = ref.watch(appSettingsProvider).snapshot;
    final repos = ref.read(appRepositoriesProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final rewardType = settings.rewardType;
        final pointsLabel = pointsAsync.when(
          data: (points) => 'Points: $points',
          loading: () => 'Points: …',
          error: (_, _) => 'Points: —',
        );

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
                      pointsLabel,
                      style: bundle.textStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    CommonUtils.buildCenteredButton(
                      context,
                      'Test: Set points to 10000',
                      () async {
                        await repos.points.writeBalance(10000);
                      },
                      bundle.textStyle,
                      bundle.secondaryColor,
                      borderColor: bundle.primaryColor,
                    ),
                  ],
                  const SizedBox(height: 24),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Goals',
                    () => ref.pushRoute(context, AppRoute.goals),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Settings',
                    () => ref.pushRoute(context, AppRoute.settings),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Achievements',
                    () => ref.pushRoute(context, AppRoute.achievements),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    rewardType == 'Customization'
                        ? 'Customization'
                        : 'Reward: $rewardType',
                    () => ref.pushRoute(context, AppRoute.reward),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    'AI Chat',
                    () => ref.pushRoute(context, AppRoute.chat),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
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
