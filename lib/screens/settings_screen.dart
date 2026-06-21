import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/utils/appearance_transition.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';
import 'package:focusNexus/widgets/sound_volume_control.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  static const _notificationFrequencies = [
    'Low',
    'Medium',
    'High',
    'No notifications',
  ];
  static const _notificationStyles = ['Minimal', 'Vibrant', 'Animated'];
  static const _rewardTypes = [
    'Mini-games',
    'Progressive visuals',
    'Customization',
  ];

  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
      if (!mounted) return;
      ref.read(settingsNotificationsAllowedProvider.notifier).set(allowed);
    }
  }

  Future<void> _refreshNotificationPermission() async {
    final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
    if (!mounted) return;
    ref.read(settingsNotificationsAllowedProvider.notifier).set(allowed);
  }

  Future<void> _load() async {
    await _refreshNotificationPermission();
  }

  Future<void> setAndCheckDailyAffirmations(bool value) async {
    final settings = ref.read(appSettingsProvider.notifier).service;
    await settings.setDailyAffirmations(value);
    if (value) {
      await updateDailyAffirmations(settings.dailyAffirmationsTime);
    } else {
      await GoalNotifier.cancelDailyAffirmationsNotification();
    }
  }

  Future<void> updateDailyAffirmations(String time) async {
    await ref.read(appSettingsProvider.notifier).service.setDailyAffirmationsTime(time);
    await GoalNotifier.startDailyAffirmations(time);
  }

  Future<void> updateNotificationFrequency(
    String oldFrequency,
    String newFrequency,
  ) async {
    final settings = ref.read(appSettingsProvider.notifier).service;
    await settings.setNotificationFrequency(newFrequency);
    if (oldFrequency == 'No notifications' &&
        newFrequency != 'No notifications') {
      await GoalNotifier.requestNotificationPermission();
    }
    if (oldFrequency != 'No notifications' &&
        newFrequency == 'No notifications') {
      await GoalNotifier.cancelAllGoalNotifications();
    }
    await GoalNotifier.refreshSchedulesForFrequencyChange(
      oldFrequency: oldFrequency,
      newFrequency: newFrequency,
    );
  }

  Future<void> _runAppearanceChange(Future<void> Function() apply) async {
    await runAppearanceChange(ref, apply);
  }

  Future<void> setPauseGoalsScreen(bool value) async {
    await ref.read(appSettingsProvider.notifier).service.setPauseGoals(value);
    if (value) {
      await GoalNotifier.cancelAllGoalNotifications();
    }
  }

  ThemeData buildTimePickerTheme(
    Color primaryColor,
    Color secondaryColor,
    TextStyle textStyle,
  ) {
    return ThemeData(
      timePickerTheme: TimePickerThemeData(
        backgroundColor: secondaryColor,
        dialBackgroundColor: secondaryColor,
        dialHandColor: Colors.deepPurple,
        dialTextColor: primaryColor,
        entryModeIconColor: primaryColor,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : secondaryColor,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? secondaryColor
                  : primaryColor,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : secondaryColor,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? secondaryColor
                  : primaryColor,
        ),
        helpTextStyle: textStyle,
        hourMinuteTextStyle: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider.notifier).service;
    final notificationsAllowed = ref.watch(settingsNotificationsAllowedProvider);
    final isDeletingAccount = ref.watch(settingsDeletingAccountProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final primaryColor = bundle.primaryColor;
        final secondaryColor = bundle.secondaryColor;
        final textStyle = bundle.textStyle;

        _loadFuture ??= _load();

        return DeferredScreen<void>(
          loadToken: 'settings-initial',
          load: () => _loadFuture!,
          minLoadingMs: 120,
          loading: (_) => themedLoadingShell(
            bundle,
            title: 'Settings',
            body: SettingsListSkeleton(bundle: bundle),
          ),
          builder: (context, _) => PopScope<Object?>(
            canPop: !isDeletingAccount,
            child: Stack(
              children: [
                Theme(
                  data: bundle.themeData,
                  child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        backgroundColor: secondaryColor,
                        color: primaryColor,
                      ),
                    ),
                    backgroundColor: secondaryColor,
                    iconTheme: IconThemeData(color: primaryColor),
                  ),
                  backgroundColor: secondaryColor,
                  body: Container(
                    color: secondaryColor,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const SizedBox(height: 8),
                        AppearanceSettingsSection(bundle: bundle),
                        CommonUtils.buildDropdownButtonFormField(
                          'Reward Type',
                          settings.rewardType,
                          _rewardTypes,
                          textStyle,
                          secondaryColor,
                          (val) => settings.setRewardType(val ?? 'Mini-games'),
                        ),
                        CommonUtils.buildDropdownButtonFormField(
                          'Notification Frequency',
                          settings.notificationFrequency,
                          _notificationFrequencies,
                          textStyle,
                          secondaryColor,
                          (val) => updateNotificationFrequency(
                            settings.notificationFrequency,
                            val ?? 'Medium',
                          ),
                        ),
                        if (settings.notificationFrequency !=
                            'No notifications')
                          CommonUtils.buildDropdownButtonFormField(
                            'Notification Style',
                            settings.notificationStyle,
                            _notificationStyles,
                            textStyle,
                            secondaryColor,
                            (val) => settings.setNotificationStyle(
                              val ?? 'Minimal',
                            ),
                          )
                        else
                          CommonUtils.buildText(
                            'Notifications are disabled. Settings related to them will not be shown unless re-enabled.',
                            textStyle,
                          ),
                        const Divider(),
                        CommonUtils.buildSwitchListTile(
                          'Dyslexia-friendly Font',
                          textStyle,
                          settings.useDyslexiaFont,
                          (val) => _runAppearanceChange(
                            () => settings.setUseDyslexiaFont(val),
                          ),
                          primaryColor,
                        ),
                        CommonUtils.buildSwitchListTile(
                          'High Contrast Mode',
                          textStyle,
                          settings.highContrastMode,
                          (val) => _runAppearanceChange(
                            () => settings.setHighContrastMode(val),
                          ),
                          primaryColor,
                        ),
                        if (settings.notificationFrequency !=
                            'No notifications') ...[
                          CommonUtils.buildSwitchListTile(
                            'Daily Affirmations',
                            textStyle,
                            settings.dailyAffirmations,
                            setAndCheckDailyAffirmations,
                            primaryColor,
                          ),
                          if (settings.dailyAffirmations) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: CommonUtils.buildElevatedButton(
                                    settings.dailyAffirmationsTime.isNotEmpty
                                        ? 'Selected daily affirmations time: ${settings.dailyAffirmationsTime} click me to change'
                                        : 'Choose Time',
                                    primaryColor,
                                    secondaryColor,
                                    textStyle,
                                    4,
                                    0,
                                    () async {
                                      final selected = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                        initialEntryMode:
                                            TimePickerEntryMode.dial,
                                        builder:
                                            (context, child) => Theme(
                                              data: buildTimePickerTheme(
                                                primaryColor,
                                                secondaryColor,
                                                textStyle,
                                              ),
                                              child: child!,
                                            ),
                                      );
                                      if (selected != null) {
                                        final formatted =
                                            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                                        await updateDailyAffirmations(
                                          formatted,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ],
                          CommonUtils.buildSwitchListTile(
                            'AI Encouragement',
                            textStyle,
                            settings.aiEncouragement,
                            settings.setAiEncouragement,
                            primaryColor,
                          ),
                          if (!notificationsAllowed)
                            CommonUtils.buildSwitchListTile(
                              'Would you like to enable notifications?',
                              textStyle,
                              notificationsAllowed,
                              (val) async {
                                await GoalNotifier.requestNotificationPermission();
                                final allowed =
                                    await GoalNotifier.checkNotificationsPermissionsGranted();
                                if (!mounted) return;
                                ref
                                    .read(
                                      settingsNotificationsAllowedProvider
                                          .notifier,
                                    )
                                    .set(allowed);
                              },
                              primaryColor,
                            ),
                        ],
                        CommonUtils.buildSwitchListTile(
                          'Pause Goals',
                          textStyle,
                          settings.pauseGoals,
                          setPauseGoalsScreen,
                          primaryColor,
                        ),
                        CommonUtils.buildSwitchListTile(
                          'Sound',
                          textStyle,
                          settings.soundEnabled,
                          settings.setSoundEnabled,
                          primaryColor,
                        ),
                        if (settings.soundEnabled)
                          SoundVolumeControl(bundle: bundle),
                        const Divider(),
                        CommonUtils.buildElevatedButton(
                          'Clear preferences and delete account',
                          primaryColor,
                          secondaryColor,
                          textStyle,
                          0,
                          0,
                          isDeletingAccount
                              ? null
                              : () => _confirmAndDeleteAccount(
                                context,
                                primaryColor,
                                secondaryColor,
                                textStyle,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isDeletingAccount)
                ModalBarrier(
                  color: Colors.black.withValues(alpha: 0.45),
                  dismissible: false,
                ),
              if (isDeletingAccount)
                Center(
                  child: Material(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deleting account…',
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeleteAccount(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
    TextStyle textStyle,
  ) async {
    final settings = ref.read(appSettingsProvider.notifier).service;
    final firstConfirmation = await CommonUtils.showInteractableAlertDialog(
      context,
      'Delete Account?',
      'Would you like to delete your account and reset all settings?',
      textStyle,
      secondaryColor,
      barrierDismissible: false,
      actions: [
        CommonUtils.buildElevatedButton(
          'No',
          primaryColor,
          secondaryColor,
          textStyle,
          0,
          0,
          () => Navigator.pop(context, false),
        ),
        CommonUtils.buildElevatedButton(
          'Yes',
          primaryColor,
          secondaryColor,
          textStyle,
          0,
          0,
          () => Navigator.pop(context, true),
        ),
      ],
    );
    if (firstConfirmation != true) return;
    if (!context.mounted) return;

    final finalConfirmation = await CommonUtils.showInteractableAlertDialog(
      context,
      'Delete Account?',
      'Would you like to delete your account and reset all settings? This is permanent and cannot be reversed once done.',
      textStyle,
      secondaryColor,
      barrierDismissible: false,
      actions: [
        CommonUtils.buildElevatedButton(
          'No',
          primaryColor,
          secondaryColor,
          textStyle,
          0,
          0,
          () => Navigator.pop(context, false),
        ),
        CommonUtils.buildElevatedButton(
          'Yes, I would like to permanently delete my account.',
          primaryColor,
          secondaryColor,
          textStyle,
          0,
          0,
          () => Navigator.pop(context, true),
        ),
      ],
    );
    if (finalConfirmation != true) return;
    if (!context.mounted) return;

    ref.read(settingsDeletingAccountProvider.notifier).set(true);
    try {
      await settings.clearAll();
      if (!context.mounted) return;
      ref.resetToRoute(context, AppRoute.auth);
    } finally {
      if (mounted) {
        ref.read(settingsDeletingAccountProvider.notifier).set(false);
      }
    }
  }
}
