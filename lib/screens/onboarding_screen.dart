import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';
import 'package:focusNexus/utils/BaseState.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/common_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends BaseState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final String baseImagePath = 'assets/images/onboarding_images';
  bool _notificationsEnabled = false;
  int totalImages = 0;
  List<String> onboardingImages = [];
  final primaryColor = CommonUtils.getDefaultPrimaryColor();
  final secondaryColor = CommonUtils.getDefaultSecondaryColor();
  final textStyle = CommonUtils.getDefaultTextStyle();

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  Future<List<String>> get imagePaths async =>
      (json.decode(await rootBundle.loadString('AssetManifest.json'))
              as Map<String, dynamic>)
          .keys
          .where(
            (path) =>
                path.startsWith('assets/images/onboarding_images/') &&
                path.endsWith('.jpg'),
          )
          .toList();

  void _loadImageData() async {
    onboardingImages = await imagePaths;
    totalImages = onboardingImages.length;
  }

  void _goToNextPage() {
    if (_currentPage < totalImages - 1) {
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
    final notificationsGranted =
        await GoalNotifier.checkNotificationsPermissionsGranted();
    debugPrint('Notifications enabled: $notificationsGranted');
    _notificationsEnabled = getNotificationsEnabled();

    if (_notificationsEnabled && !notificationsGranted) {
      final shouldEnable = await CommonUtils.showInteractableAlertDialog(
        context,
        'Enable Notifications',
        'To stay on track with your goals, FocusNexus can send reminders and updates. Would you like to enable notifications?',
        textStyle,
        secondaryColor,
        actions: [
          CommonUtils.buildElevatedButton(
            'Not Now', primaryColor, secondaryColor, textStyle, 0, 0, () => Navigator.pop(context, false),
          ),
          CommonUtils.buildElevatedButton('Enable', primaryColor, secondaryColor, textStyle, 0, 0, () => Navigator.pop(context, true),
          ),
        ],
      );

      if (shouldEnable == true) {
        await GoalNotifier.requestNotificationPermission();
      }
    }

    setOnboardingCompleted(
      true,
    ); // To ensure user only has to endure onboarding once per account made.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalImages,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Center(child: Image.asset(onboardingImages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  CommonUtils.buildElevatedButton('Go to previous image', primaryColor, secondaryColor, textStyle, 0, 0, _goToPreviousPage)
                  //ElevatedButton(
                    //onPressed: _goToPreviousPage,
                    //child: const Text('Go Back'),
                  //),
                else
                  const SizedBox(width: 100), // Placeholder to balance layout

                if (_currentPage < totalImages - 1)
                  CommonUtils.buildElevatedButton('Next', primaryColor, secondaryColor, textStyle, 0, 0, _goToNextPage)
                else
                  CommonUtils.buildElevatedButton('Finish', primaryColor, secondaryColor, textStyle, 0, 0, _finishOnboarding),
                CommonUtils.buildElevatedButton('Skip', primaryColor, secondaryColor, textStyle, 0, 0, _finishOnboarding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
