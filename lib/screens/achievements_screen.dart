import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  Future<void> _claimAll(
    WidgetRef ref,
    BuildContext context,
    ThemeBundle bundle,
    AchievementService service,
  ) async {
    final result = await service.completeAllClaimable();
    ref.read(achievementsListRefreshProvider.notifier).bump();
    if (!context.mounted) return;
    CommonUtils.showSnackBar(
      context,
      result.claimedCount == 0
          ? 'Nothing to claim.'
          : 'Claimed ${result.claimedCount} achievements '
              '(+${result.pointsGained} points)',
      bundle.textStyle,
      3000,
      16,
    );
  }

  Future<void> _openAchievement(
    WidgetRef ref,
    BuildContext context,
    Achievement achievement,
    ThemeBundle bundle,
    AchievementService service,
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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              iconTheme: ThemeStyles.iconThemeFor( bundle.primaryColor),
            ),
            backgroundColor: bundle.secondaryColor,
            body: Container(
              color: bundle.secondaryColor,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasClaimable) ...[
                      CommonUtils.buildElevatedButton(
                        'Claim all ready',
                        bundle.primaryColor,
                        Colors.deepPurple,
                        bundle.textStyle,
                        14,
                        10,
                        () => _claimAll(ref, context, bundle, service),
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
                      final displayProgress = AchievementProgress.displayPercent(
                        progress: achievement.progress,
                        isCompleted: achievement.isCompleted,
                      );
                      final readyToClaim = displayProgress >= 100;
                      final buttonColor = readyToClaim
                          ? Colors.deepPurple
                          : bundle.secondaryColor;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: CommonUtils.buildElevatedButton(
                          achievement.title,
                          bundle.primaryColor,
                          buttonColor,
                          bundle.textStyle,
                          14,
                          10,
                          () => _openAchievement(
                            ref,
                            context,
                            achievement,
                            bundle,
                            service,
                          ),
                          borderColor: readyToClaim
                              ? Colors.deepPurple
                              : bundle.primaryColor,
                        ),
                      );
                    }),
                    Text(
                      'Completed achievements',
                      style: bundle.textStyle.copyWith(
                        color: Colors.deepPurple,
                      ),
                    ),
                    ...catalog.completed.map((achievement) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: CommonUtils.buildElevatedButton(
                          achievement.title,
                          bundle.primaryColor,
                          bundle.secondaryColor,
                          bundle.textStyle,
                          14,
                          10,
                          () => _openAchievement(
                            ref,
                            context,
                            achievement,
                            bundle,
                            service,
                          ),
                        ),
                      );
                    }),
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
