import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/settings/account_wipe_use_case.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/settings/settings_notifications.dart';
import 'package:focusNexus/utils/appearance_transition.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/notification_platform.dart';
import 'package:focusNexus/utils/screen_semantics.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/legal_links_section.dart';
import 'package:focusNexus/widgets/reward_types_multi_select.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/widgets/settings_time_picker.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';
import 'package:focusNexus/widgets/sound_volume_control.dart';
import 'package:focusNexus/utils/theme_styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  Future<void>? _loadFuture;
  bool _exactAlarmGranted = true;

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

  Future<void> _refreshNotificationPermission() async {
    final allowed = await GoalNotifier.checkNotificationsPermissionsGranted();
    final exactAlarm =
        await GoalNotifier.checkExactAlarmPermissionGranted();
    if (!mounted) return;
    ref.read(settingsNotificationsAllowedProvider.notifier).set(allowed);
    setState(() => _exactAlarmGranted = exactAlarm);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _refreshNotificationPermission();
    }
  }

  Future<void> _load() async {
    await _refreshNotificationPermission();
  }

  Future<void> _runAppearanceChange(Future<void> Function() apply) async {
    await runAppearanceChange(ref, apply);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider.notifier).service;
    final notificationsAllowed = ref.watch(settingsNotificationsAllowedProvider);
    final isDeletingAccount = ref.watch(settingsDeletingAccountProvider);
    final showNotificationControls =
        SettingsNotifications.showsNotificationControls(
      settings.notificationFrequency,
    );

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
                      iconTheme: ThemeStyles.iconThemeFor(primaryColor),
                    ),
                    backgroundColor: secondaryColor,
                    body: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const SizedBox(height: 8),
                        ScreenSemantics.sectionHeader('Appearance', textStyle),
                        AppearanceSettingsSection(
                          bundle: bundle,
                          showDarkMode: false,
                        ),
                        ScreenSemantics.sectionHeader(
                          'Rewards & notifications',
                          textStyle,
                        ),
                        RewardTypesMultiSelect(
                          selected: settings.rewardTypes,
                          textStyle: textStyle,
                          activeColor: primaryColor,
                          title: 'Reward types',
                          subtitle:
                              'Enable one or more. At least one must stay on.',
                          onChanged: (next) async {
                            final ok = await settings.setRewardTypes(next);
                            if (!context.mounted) return;
                            if (!ok) {
                              CommonUtils.showSnackBar(
                                context,
                                'Keep at least one reward type enabled.',
                                textStyle,
                                2500,
                                14,
                              );
                            }
                          },
                        ),
                        CommonUtils.buildDropdownButtonFormField(
                          'Notification Frequency',
                          settings.notificationFrequency,
                          NotificationPreferenceOptions.frequencies,
                          textStyle,
                          secondaryColor,
                          (val) => SettingsNotifications.updateFrequency(
                            settings,
                            oldFrequency: settings.notificationFrequency,
                            newFrequency:
                                val ??
                                NotificationPreferenceOptions.defaultFrequency,
                          ),
                        ),
                        if (showNotificationControls)
                          CommonUtils.buildDropdownButtonFormField(
                            'Notification Style',
                            settings.notificationStyle,
                            NotificationPreferenceOptions.styles,
                            textStyle,
                            secondaryColor,
                            (val) => settings.setNotificationStyle(
                              val ?? NotificationPreferenceOptions.styleMinimal,
                            ),
                          )
                        else
                          CommonUtils.buildText(
                            'Notifications are disabled. Settings related to them will not be shown unless re-enabled.',
                            textStyle,
                          ),
                        const Divider(),
                        ScreenSemantics.sectionHeader(
                          'Accessibility',
                          textStyle,
                        ),
                        if (settings.usesCustomizedColours)
                          CommonUtils.buildElevatedButton(
                            'Change customized colours',
                            primaryColor,
                            secondaryColor,
                            textStyle,
                            0,
                            0,
                            () => ref.pushRoute(
                              context,
                              AppRoute.customization,
                            ),
                          )
                        else ...[
                          CommonUtils.buildSwitchListTile(
                            'Dark mode',
                            textStyle,
                            settings.snapshot.isDark,
                            (val) => _runAppearanceChange(
                              () => settings.setUserTheme(
                                val ? 'dark' : 'light',
                              ),
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
                        ],
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
                          'Hide motivational phrases',
                          textStyle,
                          settings.motivatorsDisabled,
                          (val) => settings.setMotivatorsDisabled(val),
                          primaryColor,
                        ),
                        if (showNotificationControls) ...[
                          const Divider(),
                          ScreenSemantics.sectionHeader(
                            'Notification settings',
                            textStyle,
                          ),
                          CommonUtils.buildSwitchListTile(
                            'Daily Affirmations',
                            textStyle,
                            settings.dailyAffirmations,
                            (val) => SettingsNotifications.setDailyAffirmations(
                              settings,
                              val,
                            ),
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
                                      final formatted =
                                          await SettingsTimePicker.pickHHmm(
                                        context,
                                        primaryColor: primaryColor,
                                        secondaryColor: secondaryColor,
                                        textStyle: textStyle,
                                      );
                                      if (formatted == null) return;
                                      await SettingsNotifications
                                          .setDailyAffirmationsTime(
                                        settings,
                                        formatted,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ],
                          CommonUtils.buildSwitchListTile(
                            'Open streak reminders',
                            textStyle,
                            settings.openStreakReminders,
                            (val) =>
                                SettingsNotifications.setOpenStreakReminders(
                              settings,
                              val,
                            ),
                            primaryColor,
                          ),
                          if (settings.openStreakReminders) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: CommonUtils.buildElevatedButton(
                                    settings.openStreakRemindersTime.isNotEmpty
                                        ? 'Selected open streak reminder time: ${settings.openStreakRemindersTime} click me to change'
                                        : 'Choose Time',
                                    primaryColor,
                                    secondaryColor,
                                    textStyle,
                                    4,
                                    0,
                                    () async {
                                      final formatted =
                                          await SettingsTimePicker.pickHHmm(
                                        context,
                                        primaryColor: primaryColor,
                                        secondaryColor: secondaryColor,
                                        textStyle: textStyle,
                                      );
                                      if (formatted == null) return;
                                      await SettingsNotifications
                                          .setOpenStreakRemindersTime(
                                        settings,
                                        formatted,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ],
                          CommonUtils.buildSwitchListTile(
                            'Goal encouragement',
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
                              (_) async {
                                await GoalNotifier.openNotificationSettings();
                                await _refreshNotificationPermission();
                              },
                              primaryColor,
                            ),
                          if (notificationsAllowed &&
                              NotificationPlatform.isAndroid &&
                              !_exactAlarmGranted) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                NotificationPlatform.exactAlarmDeniedUserMessage,
                                style: textStyle.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Open exact alarm settings',
                                style: textStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              onTap: () async {
                                await GoalNotifier.openExactAlarmSettings();
                                await _refreshNotificationPermission();
                              },
                            ),
                          ],
                        ],
                        if (settings.hasProgressiveVisualsReward) ...[
                          const Divider(),
                          ScreenSemantics.sectionHeader('Zen garden', textStyle),
                          CommonUtils.buildSwitchListTile(
                            'Confirm before restart growth',
                            textStyle,
                            !ref.watch(zenGardenSessionProvider).garden
                                .suppressRestartGrowthPrompt,
                            (enabled) async {
                              final session =
                                  ref.read(zenGardenSessionProvider.notifier);
                              if (!session.hasLoadedFromDisk) {
                                await session.loadGarden();
                              }
                              session.setSuppressRestartGrowthPrompt(!enabled);
                            },
                            primaryColor,
                          ),
                        ],
                        const Divider(),
                        ScreenSemantics.sectionHeader(
                          'Goals & sound',
                          textStyle,
                        ),
                        CommonUtils.buildSwitchListTile(
                          'Pause Goals',
                          textStyle,
                          settings.pauseGoals,
                          (val) => SettingsNotifications.setPauseGoals(
                            settings,
                            val,
                          ),
                          primaryColor,
                        ),
                        CommonUtils.buildSwitchListTile(
                          'Sound',
                          textStyle,
                          settings.soundEnabled,
                          settings.setSoundEnabled,
                          primaryColor,
                        ),
                        if (settings.soundEnabled) ...[
                          SoundVolumeControl(bundle: bundle),
                          CommonUtils.buildElevatedButton(
                            'Customize sound effects',
                            primaryColor,
                            secondaryColor,
                            textStyle,
                            0,
                            0,
                            () => ref.pushRoute(
                              context,
                              AppRoute.soundEffects,
                            ),
                          ),
                        ],
                        const Divider(),
                        ScreenSemantics.sectionHeader('Legal', textStyle),
                        if (!settings.hasAcceptedCurrentEula)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Please review and accept the updated End User '
                              'License Agreement to keep using FocusNexus.',
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        LegalLinksSection.buttons(
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          textStyle: textStyle,
                        ),
                        const Divider(),
                        ScreenSemantics.sectionHeader('Account', textStyle),
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
      final wipe = AccountWipeUseCase(
        repos: ref.read(appRepositoriesProvider),
        settings: settings,
        achievements: ref.read(achievementServiceProvider),
        sounds: ref.read(soundServiceProvider),
        ambientCoordinator: ref.read(ambientPlaybackCoordinatorProvider),
        resetZenGardenSession: () async {
          ref.read(zenGardenSessionProvider.notifier).resetForAccountWipe();
        },
        bumpAchievementsList: () {
          ref.read(achievementsListRefreshProvider.notifier).bump();
        },
        invalidatePointsBalance: () {
          ref.invalidate(pointsBalanceProvider);
        },
      );
      await wipe.execute();
      if (!context.mounted) return;
      ref.resetToRoute(context, AppRoute.auth);
    } finally {
      if (mounted) {
        ref.read(settingsDeletingAccountProvider.notifier).set(false);
      }
    }
  }
}
