import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';
import 'package:focusNexus/utils/BaseState.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  @override
  void initState(){
    super.initState();
    _loadImageData();
  }


  Future<List<String>> get imagePaths async =>
      (json.decode(await rootBundle.loadString('AssetManifest.json')) as Map<
          String,
          dynamic>)
          .keys
          .where((path) =>
      path.startsWith('assets/images/onboarding_images/') &&
          path.endsWith('.jpg'))
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
    final notificationsGranted = await GoalNotifier.checkNotificationsPermissionsGranted();
    debugPrint('Notifications enabled: $notificationsGranted');
    _notificationsEnabled = getNotificationsEnabled();

    if (_notificationsEnabled && !notificationsGranted) {
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'To stay on track with your goals, FocusNexus can send reminders and updates. Would you like to enable notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (shouldEnable == true) {
        await GoalNotifier.requestNotificationPermission();
      }
    }

    setOnboardingCompleted(true); // To ensure user only has to endure onboarding once per account made.
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
                return Center(
                  child: Image.asset(onboardingImages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: _goToPreviousPage,
                    child: const Text('Go Back'),
                  )
                else
                  const SizedBox(width: 100), // Placeholder to balance layout

                if (_currentPage < totalImages - 1)
                  ElevatedButton(
                    onPressed: _goToNextPage,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Finish'),
                  ),

                ElevatedButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
