import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';
import 'package:focusNexus/utils/BaseState.dart';
import 'package:focusNexus/utils/notifier.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends BaseState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final String baseImagePath = 'assets/images/onboarding_images/';
  bool _notificationsEnabled = false;
  static const platform = MethodChannel('flutter_native_timezone');

  List<String> get imagePaths => [
    baseImagePath + 'dashboard.jpg',
    baseImagePath + 'goals_overview.jpg',
    baseImagePath + 'active_goal.jpg',
    baseImagePath + 'single_goal.jpg',
    baseImagePath + 'template_manager.jpg',
    baseImagePath + 'multi_template_manager.jpg',
    baseImagePath + 'settings_screen_onboarding.jpg',
    // TODO: Add the rest of the paths once all screens are done.
  ];


  void _goToNextPage() {
    if (_currentPage < imagePaths.length - 1) {
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
    debugPrint('Notifications enabled: notificationsGranted');
    _notificationsEnabled = getNotificationsEnabled();
     if(_notificationsEnabled &! notificationsGranted) {
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

       Navigator.pushReplacement(
         context,
         MaterialPageRoute(builder: (_) => const DashboardScreen()),
       );
     }
     else {
       Navigator.pushReplacement( // In case notifications are already enabled system-side (such as user logging back in.)
         context,
         MaterialPageRoute(builder: (_) => const DashboardScreen()),
       );
     }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Image.asset(imagePaths[index]),
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

                if (_currentPage < imagePaths.length - 1)
                  ElevatedButton(
                    onPressed: _goToNextPage,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Finish'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
