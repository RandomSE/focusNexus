import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/dashboard_goals_label.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/screens/onboarding/onboarding_live_stats.dart';
import 'package:focusNexus/screens/onboarding/onboarding_slides.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    final currentPage = ref.read(onboardingPageIndexProvider);
    if (currentPage < kOnboardingSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    final currentPage = ref.read(onboardingPageIndexProvider);
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final bundle = ref.watch(themeBundleProvider);
    final settings = ref.read(appSettingsProvider.notifier).service;
    final textStyle = bundle.textStyle;
    final primaryColor = bundle.primaryColor;
    final secondaryColor = bundle.secondaryColor;

    final notificationsGranted =
        await GoalNotifier.checkNotificationsPermissionsGranted();
    if (!mounted) return;

    if (settings.notificationsEnabled && !notificationsGranted) {
      final shouldEnable = await CommonUtils.showInteractableAlertDialog(
        context,
        'Enable Notifications',
        'To stay on track with your goals, FocusNexus can send reminders and updates. Would you like to enable notifications?',
        textStyle,
        secondaryColor,
        actions: [
          CommonUtils.buildElevatedButton(
            'Not Now',
            primaryColor,
            secondaryColor,
            textStyle,
            0,
            0,
            () => Navigator.pop(context, false),
          ),
          CommonUtils.buildElevatedButton(
            'Enable',
            primaryColor,
            secondaryColor,
            textStyle,
            0,
            0,
            () => Navigator.pop(context, true),
          ),
        ],
      );
      if (!mounted) return;

      if (shouldEnable == true) {
        await GoalNotifier.requestNotificationPermission();
        if (!mounted) return;
      }
    }

    await settings.setOnboardingCompleted(true);
    if (!mounted) return;
    ref.pushReplacementRoute(context, AppRoute.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return _buildOnboardingContent(context, bundle);
      },
    );
  }

  OnboardingLiveStats _liveStats() {
    final now = DateTime.now();
    final goals = ref.watch(goalsProvider).activeGoals;
    final inSlot = goals.where((g) => isActionWindowActive(g, now)).length;
    final points =
        ref.watch(pointsBalanceProvider).valueOrNull ??
        PointsRepository.defaultBalance;
    return OnboardingLiveStats(
      points: points,
      activeGoals: goals.length,
      goalsInSlotNow: inSlot,
    );
  }

  Widget _buildOnboardingContent(BuildContext context, ThemeBundle bundle) {
    final currentPage = ref.watch(onboardingPageIndexProvider);
    final stats = _liveStats();
    final textStyle = bundle.textStyle;
    final primaryColor = bundle.primaryColor;
    final secondaryColor = bundle.secondaryColor;
    final lastIndex = kOnboardingSlides.length - 1;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: kOnboardingSlides.length,
                onPageChanged: (index) {
                  ref.read(onboardingPageIndexProvider.notifier).set(index);
                },
                itemBuilder: (context, index) {
                  return buildOnboardingSlide(
                    id: kOnboardingSlides[index],
                    bundle: bundle,
                    stats: stats,
                  );
                },
              ),
            ),
            if (currentPage == lastIndex) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppearanceSettingsSection(
                  bundle: bundle,
                  showBottomDivider: false,
                  showDyslexiaSwitch: true,
                  showHighContrastSwitch: true,
                  overflowSafe: true,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (currentPage > 0)
                    CommonUtils.buildElevatedButton(
                      'Previous',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      _goToPreviousPage,
                    ),
                  if (currentPage < lastIndex)
                    CommonUtils.buildElevatedButton(
                      'Next',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      _goToNextPage,
                    )
                  else
                    CommonUtils.buildElevatedButton(
                      'Finish',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      _finishOnboarding,
                    ),
                  CommonUtils.buildElevatedButton(
                    'Skip',
                    primaryColor,
                    secondaryColor,
                    textStyle,
                    0,
                    0,
                    _finishOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
