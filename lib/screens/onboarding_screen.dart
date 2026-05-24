import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../utils/common_utils.dart';
import '../utils/onboarding_assets.dart';
import '../models/classes/theme_bundle.dart';
import '../utils/screen_theme.dart';
import '../widgets/skeleton_loaders.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settings = AppRepositories.instance.settings;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _onboardingImages = [];
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    final images = await loadOnboardingImagePaths();
    if (!mounted) return;
    setState(() {
      _onboardingImages = images;
      _imagesLoaded = true;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _onboardingImages.length - 1) {
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

      if (shouldEnable == true) {
        await GoalNotifier.requestNotificationPermission();
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
        if (!_imagesLoaded) {
          return Scaffold(
            backgroundColor: bundle.secondaryColor,
            body: OnboardingSkeleton(bundle: bundle),
          );
        }

        return _buildOnboardingContent(context, bundle);
      },
    );
  }

  Widget _buildOnboardingContent(BuildContext context, ThemeBundle bundle) {
    final textStyle = bundle.textStyle;
    final primaryColor = bundle.primaryColor;
    final secondaryColor = bundle.secondaryColor;

    if (_onboardingImages.isEmpty) {
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

    final lastIndex = _onboardingImages.length - 1;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingImages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Image.asset(
                        _onboardingImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
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
