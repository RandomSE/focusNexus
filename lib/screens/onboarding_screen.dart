import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../utils/common_utils.dart';
import '../utils/onboarding_assets.dart';
import '../models/classes/theme_bundle.dart';
import '../utils/screen_theme.dart';
import '../widgets/appearance_settings_section.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/deferred_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settings = AppRepositories.instance.settings;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage(List<String> images) {
    if (_currentPage < images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final bundle = currentThemeBundle();
    final textStyle = bundle.textStyle;
    final primaryColor = bundle.primaryColor;
    final secondaryColor = bundle.secondaryColor;

    final notificationsGranted =
        await GoalNotifier.checkNotificationsPermissionsGranted();
    if (!mounted) return;

    if (_settings.notificationsEnabled && !notificationsGranted) {
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

    await _settings.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return DeferredScreen<List<String>>(
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
                onPageChanged: (index) => setState(() => _currentPage = index),
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
            if (_currentPage == lastIndex) ...[
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
                  if (_currentPage > 0)
                    CommonUtils.buildElevatedButton(
                      'Previous',
                      primaryColor,
                      secondaryColor,
                      textStyle,
                      0,
                      0,
                      _goToPreviousPage,
                    ),
                  if (_currentPage < lastIndex)
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
