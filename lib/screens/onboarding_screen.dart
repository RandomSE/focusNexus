import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/onboarding_assets.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage(List<String> images) {
    final currentPage = ref.read(onboardingPageIndexProvider);
    if (currentPage < images.length - 1) {
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
        return DeferredScreen<List<String>>(
          loadToken: 'onboarding-images',
          load: loadOnboardingImagePaths,
          loading: (_) => Scaffold(
            backgroundColor: bundle.secondaryColor,
            body: OnboardingSkeleton(bundle: bundle),
          ),
          builder: (context, images) =>
              _buildOnboardingContent(context, bundle, images),
        );
      },
    );
  }

  Widget _buildOnboardingContent(
    BuildContext context,
    ThemeBundle bundle,
    List<String> onboardingImages,
  ) {
    final currentPage = ref.watch(onboardingPageIndexProvider);
    final textStyle = bundle.textStyle;
    final primaryColor = bundle.primaryColor;
    final secondaryColor = bundle.secondaryColor;

    if (onboardingImages.isEmpty) {
      return Scaffold(
        backgroundColor: secondaryColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Onboarding images are missing from the app bundle.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CommonUtils.buildElevatedButton(
                  'Continue anyway',
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
        ),
      );
    }

    final lastIndex = onboardingImages.length - 1;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingImages.length,
                onPageChanged: (index) {
                  ref.read(onboardingPageIndexProvider.notifier).set(index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Image.asset(
                        onboardingImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
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
                      () => _goToNextPage(onboardingImages),
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
