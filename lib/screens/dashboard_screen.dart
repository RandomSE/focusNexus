import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/goals/dashboard_goals_label.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/rewards/reward_type_selection.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/services/daily_open_reward_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/utils/external_url_launcher.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/screen_semantics.dart';
import 'package:focusNexus/widgets/dashboard_motivator_banner.dart';
import 'package:focusNexus/widgets/dashboard_consistency_section.dart';
import 'package:focusNexus/widgets/debug_points_credit_panel.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late int _motivatorIndex;
  late String _motivatorText;
  int _randomMessageIndex = 0;
  CustomAffirmationPackData _pack = CustomAffirmationPackData.empty;
  bool _motivatorDismissed = false;
  bool _dailyRewardAttempted = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _motivatorIndex = AdhdMotivatorPack.seedForDate(now);
    _motivatorText = AdhdMotivatorPack.lineAt(_motivatorIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).load();
      unawaited(_loadMotivatorPack());
      _tryDailyOpenReward();
    });
  }

  Future<void> _loadMotivatorPack() async {
    final pack = await ref
        .read(appRepositoriesProvider)
        .phrasePacks
        .read(PhrasePackKind.dashboardMotivator);
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _pack = pack;
      if (pack.enabled && pack.playbackMessages.isNotEmpty) {
        if (pack.mode == CustomAffirmationPlaybackMode.random) {
          _motivatorText =
              CustomAffirmationPackSelector.customCoreForDate(pack, now)!;
          _randomMessageIndex =
              CustomAffirmationPackSelector.messageIndexForText(
            pack,
            _motivatorText,
          );
        } else {
          _motivatorIndex =
              CustomAffirmationPackSelector.sequenceIndexForDate(pack, now);
          _motivatorText = CustomAffirmationPackSelector.lineAtPlaylistIndex(
            pack,
            _motivatorIndex,
          );
        }
      } else {
        _motivatorIndex = AdhdMotivatorPack.seedForDate(now);
        _motivatorText = AdhdMotivatorPack.lineAt(_motivatorIndex);
      }
    });
  }

  void _swapMotivator() {
    setState(() {
      final playback = _pack.playbackMessages;
      if (_pack.enabled && playback.isNotEmpty) {
        if (_pack.mode == CustomAffirmationPlaybackMode.random) {
          _randomMessageIndex =
              CustomAffirmationPackSelector.nextRandomMessageIndex(
            messageCount: playback.length,
            currentIndex: _randomMessageIndex,
            random: Random(),
          );
          _motivatorText = playback[_randomMessageIndex].text;
        } else {
          _motivatorIndex++;
          _motivatorText = CustomAffirmationPackSelector.lineAtPlaylistIndex(
            _pack,
            _motivatorIndex,
          );
        }
      } else {
        _motivatorIndex++;
        _motivatorText = AdhdMotivatorPack.lineAt(_motivatorIndex);
      }
    });
  }

  Future<void> _tryDailyOpenReward() async {
    if (_dailyRewardAttempted || !mounted) return;
    _dailyRewardAttempted = true;
    try {
      final repos = ref.read(appRepositoriesProvider);
      final service = DailyOpenRewardService(
        storage: repos.storage,
        points: repos.points,
      );
      final result = await service.tryGrant();
      if (!mounted) return;
      if (!result.granted) return;

      await ref.read(achievementServiceProvider).updateProgressForTrackingKeys({
        StorageKeys.consecutiveDaysAppOpened,
      });
      if (!mounted) return;

      final settings = ref.read(appSettingsProvider).snapshot;
      if (settings.openStreakReminders) {
        await GoalNotifier.startOpenStreakReminder(
          settings.openStreakRemindersTime,
        );
      }
      if (!mounted) return;

      final textStyle = ref.read(themeBundleProvider).textStyle;
      CommonUtils.showSnackBar(
        context,
        'Daily open: +${result.amount} points '
        '(streak day ${result.newStreak})',
        textStyle,
        3500,
        16,
      );
    } catch (e, stack) {
      debugLog('Dashboard daily open reward failed soft: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(pointsBalanceProvider);
    final settings = ref.watch(appSettingsProvider).snapshot;
    final activeGoals = ref.watch(goalsProvider).activeGoals;
    final goalsInSlotNow = activeGoals
        .where((g) => isActionWindowActive(g, DateTime.now()))
        .length;
    final goalsButtonLabel = dashboardGoalsButtonLabel(
      activeGoals.length,
      goalsInSlotNow: goalsInSlotNow,
    );

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final rewardTypes = settings.rewardTypes;
        final achievementService = ref.watch(achievementServiceProvider);
        // Rebuild when mini-games / claim flows bump refresh (service is keepAlive).
        ref.watch(achievementsListRefreshProvider);
        final hasClaimableAchievements = achievementService.all.any(
          (a) => !a.isCompleted && a.progress >= 100,
        );
        final pointsLabel = pointsAsync.when(
          data: (points) => 'Points: $points',
          loading: () => 'Points: ...',
          error: (_, _) => 'Points: -',
        );

        return Theme(
          data: bundle.themeData,
          child: PopScope(
            canPop: false,
            child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ScreenSemantics.statusText(
                      pointsLabel,
                      bundle.textStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (!settings.motivatorsDisabled && !_motivatorDismissed) ...[
                    const SizedBox(height: 12),
                    DashboardMotivatorBanner(
                      text: _motivatorText,
                      textStyle: bundle.textStyle,
                      accentColor: bundle.primaryColor,
                      onSwap: _swapMotivator,
                      onDismiss: () {
                        setState(() => _motivatorDismissed = true);
                      },
                    ),
                  ],
                  if (kDebugMode) const DebugPointsCreditPanel(),
                  const SizedBox(height: 16),
                  DashboardConsistencySection(bundle: bundle),
                  const SizedBox(height: 24),
                  CommonUtils.buildCenteredButton(
                    context,
                    goalsButtonLabel,
                    () => ref.pushRoute(context, AppRoute.goals),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                    semanticsHint: 'Opens goals screen',
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    'Settings',
                    () => ref.pushRoute(context, AppRoute.settings),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                    semanticsHint: 'Opens settings',
                  ),
                  const SizedBox(height: 12),
                  CommonUtils.buildCenteredButton(
                    context,
                    hasClaimableAchievements
                        ? 'Achievements - ready to claim'
                        : 'Achievements',
                    () => ref.pushRoute(context, AppRoute.achievements),
                    hasClaimableAchievements
                        ? bundle.textStyle.copyWith(
                            color: bundle.secondaryColor,
                            fontWeight: FontWeight.w700,
                          )
                        : bundle.textStyle,
                    hasClaimableAchievements
                        ? bundle.primaryColor
                        : bundle.secondaryColor,
                    borderColor: hasClaimableAchievements
                        ? bundle.accentColor
                        : bundle.primaryColor,
                    semanticsHint: hasClaimableAchievements
                        ? 'Opens achievements; rewards ready to claim'
                        : 'Opens achievements',
                  ),
                  const SizedBox(height: 12),
                  for (final rewardLabel in rewardTypes) ...[
                    CommonUtils.buildCenteredButton(
                      context,
                      rewardLabel,
                      () => ref.pushRoute(
                        context,
                        RewardTypeSelection.routeForStorageValue(rewardLabel),
                      ),
                      bundle.textStyle,
                      bundle.secondaryColor,
                      borderColor: bundle.primaryColor,
                      semanticsHint: 'Opens $rewardLabel',
                    ),
                    const SizedBox(height: 12),
                  ],
                  CommonUtils.buildCenteredButton(
                    context,
                    'Assistant',
                    () => ref.pushRoute(context, AppRoute.chat),
                    bundle.textStyle,
                    bundle.secondaryColor,
                    borderColor: bundle.primaryColor,
                    semanticsHint: 'Opens app assistant',
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () async {
                        final opened =
                            await openExternalUrl(kLegalContactDiscordUrl);
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not open Discord. Visit $kLegalContactDiscordUrl',
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(kDiscordBrandBlueValue),
                        side: const BorderSide(
                          color: Color(kDiscordBrandBlueValue),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Join Discord',
                        style: bundle.textStyle.copyWith(
                          color: const Color(kDiscordBrandBlueValue),
                          fontWeight: FontWeight.w600,
                          fontSize: (bundle.textStyle.fontSize ?? 14) * 0.9,
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
