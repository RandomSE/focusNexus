import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/achievements/refresh_zen_after_achievement_claim.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/achievement_catalog_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/achievement_progress.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/views/achievement_detail_view.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/utils/theme_styles.dart';

class AchievementScreen extends ConsumerStatefulWidget {
  const AchievementScreen({super.key});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen> {
  bool _claiming = false;

  Future<void> _claimAll(
    BuildContext context,
    ThemeBundle bundle,
    AchievementService service,
  ) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    CommonUtils.showSnackBar(
      context,
      'Claiming ready achievements...',
      bundle.textStyle,
      2500,
      16,
    );
    try {
      final result = await service.completeAllClaimable();
      ref.read(achievementsListRefreshProvider.notifier).bump();
      await refreshZenAfterAchievementClaim(ref);
      if (!context.mounted) return;
      CommonUtils.showSnackBar(
        context,
        result.claimedCount == 0
            ? 'Nothing to claim.'
            : 'Claimed ${result.claimedCount} achievements '
                '(+${result.pointsGained} points)',
        bundle.textStyle,
        3500,
        16,
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _openAchievement(
    BuildContext context,
    Achievement achievement,
    ThemeBundle bundle,
  ) async {
    final refreshList = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementDetailView(
          achievementId: achievement.id,
          themeData: bundle.themeData,
          primaryColor: bundle.primaryColor,
          secondaryColor: bundle.secondaryColor,
          textStyle: bundle.textStyle,
          buttonStyle: bundle.buttonStyle,
        ),
      ),
    );
    if (refreshList == true) {
      ref.read(achievementsListRefreshProvider.notifier).bump();
      await refreshZenAfterAchievementClaim(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(achievementCatalogProvider);
    final service = ref.watch(achievementServiceProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final hasClaimable = service.all.any(
          (a) => !a.isCompleted && a.progress >= 100,
        );
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Achievements',
                style: TextStyle(
                  backgroundColor: bundle.secondaryColor,
                  color: bundle.primaryColor,
                ),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(bundle.primaryColor),
            ),
            backgroundColor: bundle.secondaryColor,
            body: Container(
              color: bundle.secondaryColor,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasClaimable || _claiming) ...[
                      if (_claiming)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: bundle.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Claiming ready achievements...',
                                  style: bundle.textStyle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        CommonUtils.buildElevatedButton(
                          'Claim all ready',
                          bundle.primaryColor,
                          Colors.deepPurple,
                          bundle.textStyle,
                          14,
                          10,
                          () => _claimAll(context, bundle, service),
                        ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'In-progress achievements',
                      style: bundle.textStyle.copyWith(
                        color: Colors.deepPurple,
                      ),
                    ),
                    ...catalog.inProgress.map((achievement) {
                      final displayProgress =
                          AchievementProgress.displayPercent(
                        progress: achievement.progress,
                        isCompleted: achievement.isCompleted,
                      );
                      final readyToClaim = displayProgress >= 100;
                      final buttonColor = readyToClaim
                          ? Colors.deepPurple
                          : bundle.secondaryColor;
                      return CommonUtils.buildElevatedButton(
                        '${achievement.title} - '
                        '${displayProgress.toStringAsFixed(0)}%',
                        readyToClaim
                            ? bundle.secondaryColor
                            : bundle.primaryColor,
                        buttonColor,
                        bundle.textStyle,
                        10,
                        8,
                        _claiming
                            ? null
                            : () => _openAchievement(
                                  context,
                                  achievement,
                                  bundle,
                                ),
                        borderColor: readyToClaim
                            ? Colors.deepPurpleAccent
                            : bundle.primaryColor,
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Completed achievements',
                      style: bundle.textStyle,
                    ),
                    ...catalog.completed.map(
                      (achievement) => CommonUtils.buildElevatedButton(
                        achievement.title,
                        bundle.primaryColor,
                        bundle.secondaryColor,
                        bundle.textStyle,
                        10,
                        8,
                        _claiming
                            ? null
                            : () => _openAchievement(
                                  context,
                                  achievement,
                                  bundle,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
