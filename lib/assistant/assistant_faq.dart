/// One browsable FAQ item; [keywords] also drive offline intent matching.
class AssistantFaqEntry {
  const AssistantFaqEntry({
    required this.id,
    required this.question,
    required this.answer,
    this.keywords = const [],
    this.negativeKeywords = const [],
  });

  final String id;
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> negativeKeywords;
}

/// Grouped FAQ for the Assistant screen.
class AssistantFaqSection {
  const AssistantFaqSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<AssistantFaqEntry> entries;
}

/// Canonical offline help content (settings, goals, general app).
const List<AssistantFaqSection> assistantFaqSections = [
  AssistantFaqSection(
    title: 'General',
    entries: [
      AssistantFaqEntry(
        id: 'general.about',
        question: 'What is FocusNexus?',
        answer:
            'FocusNexus is a calm productivity app for goals, gentle reminders, '
            'and rewards. You earn points by completing goals and can spend them '
            'in your chosen reward area (Zen garden, customization, or mini-games).',
        keywords: ['what is', 'focusnexus', 'about', 'this app', 'tell me about'],
        negativeKeywords: [
          'point balance',
          'my points',
          'how many points',
          'data policy',
          'privacy',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.data_policy',
        question: 'What is the data use policy?',
        answer:
            'Your data stays on this device. FocusNexus does not upload your goals, '
            'settings, or progress to our servers, does not sell your data, and does '
            'not use your data for advertising. Nothing you enter leaves the app unless '
            'you share it yourself outside the app.',
        keywords: [
          'data',
          'privacy',
          'policy',
          'sell',
          'upload',
          'cloud',
          'local',
          'tracking',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.navigation',
        question: 'How do I navigate the app?',
        answer:
            'Open the Dashboard from the home screen. From there use Goals, Settings, '
            'Achievements, and Reward (the label matches your reward type in Settings). '
            'This Assistant is also on the Dashboard.',
        keywords: ['navigate', 'dashboard', 'where', 'find', 'screen', 'get around'],
        negativeKeywords: ['open settings', 'open goals', 'open achievements'],
      ),
      AssistantFaqEntry(
        id: 'general.open_settings',
        question: 'How do I open Settings?',
        answer:
            'From the Dashboard, tap Settings. You can adjust accessibility, '
            'notifications, sound, reward type, and account options there.',
        keywords: ['open settings', 'settings screen', 'where is settings', 'find settings'],
      ),
      AssistantFaqEntry(
        id: 'general.open_goals',
        question: 'How do I open Goals?',
        answer:
            'From the Dashboard, tap Goals. There you can create goals, filter the '
            'list, use templates, and complete active goals.',
        keywords: ['open goals', 'goals screen', 'where is goals', 'find goals', 'get to goals'],
        negativeKeywords: ['time window', 'time slot', 'time-slot'],
      ),
      AssistantFaqEntry(
        id: 'general.open_achievements',
        question: 'How do I open Achievements?',
        answer:
            'From the Dashboard, tap Achievements. The list shows milestones you can '
            'track and claim when progress is ready.',
        keywords: [
          'open achievements',
          'achievements screen',
          'where are achievements',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.open_reward',
        question: 'How do I open the Reward screen?',
        answer:
            'From the Dashboard, tap Reward. The button label matches your reward '
            'type in Settings (Zen garden, Customization, or Mini-games).',
        keywords: [
          'open reward',
          'reward screen',
          'where is reward',
          'zen garden screen',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.points_balance',
        question: 'Where are my points shown?',
        answer:
            'Your live point balance is on the Dashboard at the top. I cannot read your '
            'balance from here — check the Dashboard for the current number.',
        keywords: [
          'how many points',
          'point balance',
          'my point balance',
          'my points',
          'current points',
          'points do i have',
        ],
        negativeKeywords: ['start with', 'starting points', 'default points', 'earn points'],
      ),
      AssistantFaqEntry(
        id: 'general.in_slot_now',
        question: 'What does “in slot now” mean on the Dashboard?',
        answer:
            'It counts how many time-slot goals are in their active window right now. '
            'Only those goals can be completed or stepped while the slot is open.',
        keywords: ['in slot', 'slot now', 'dashboard line', 'in slot now mean'],
      ),
      AssistantFaqEntry(
        id: 'general.assistant_vs_encouragement',
        question:
            'What is the difference between the Assistant and AI Encouragement?',
        answer:
            'This Assistant is an offline help guide inside the app — browse the FAQ or '
            'ask how features work. AI Encouragement is a separate Settings toggle that '
            'schedules optional local notification messages for demanding goals. Neither '
            'uses the internet.',
        keywords: [
          'assistant vs',
          'difference between assistant',
          'assistant and ai encouragement',
          'this assistant vs',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.onboarding',
        question: 'What happens during onboarding?',
        answer:
            'New users see a welcome flow with slides about goals, rewards, and '
            'personalization (theme, accessibility, notifications). Finish onboarding to '
            'reach the Dashboard. You can change most choices later in Settings.',
        keywords: ['onboarding', 'welcome', 'first time', 'getting started', 'new user'],
      ),
    ],
  ),
  AssistantFaqSection(
    title: 'Goals',
    entries: [
      AssistantFaqEntry(
        id: 'goals.what_is_goal',
        question: 'What is a goal?',
        answer:
            'A goal is something you plan to do. On the Goals screen you set a title, '
            'category, complexity, effort, motivation, time estimate, steps, and optional '
            'deadline hours. Complete it to earn points.',
        keywords: ['what is a goal', 'define goal'],
        negativeKeywords: [
          'time slot',
          'deadline goal',
          'template',
          'add goal',
          'complete goal',
          'complete a goal',
          'how do i complete',
          'earn points',
          'clear',
          'filter',
        ],
      ),
      AssistantFaqEntry(
        id: 'goals.deadline',
        question: 'What is a deadline goal?',
        answer:
            'A deadline goal uses “Hours to complete” when you create it. Reminders can '
            'fire before the deadline depending on your notification settings. It is not '
            'limited to a daily time slot.',
        keywords: ['deadline goal', 'hours to complete', 'due date', 'due'],
        negativeKeywords: ['time slot', 'time-slot'],
      ),
      AssistantFaqEntry(
        id: 'goals.time_slot',
        question: 'What is a time-slot goal?',
        answer:
            'Time-slot goals only allow progress during a scheduled window (shown as a slot '
            'on the goal row). Outside that window the row says “Outside slot.” Open '
            'Goals → Time-slot goals to create or bulk-create them; slots can repeat.',
        keywords: [
          'time slot',
          'time-slot',
          'timeslot',
          'time window',
          'time windows',
          'outside slot',
          'action window',
        ],
        negativeKeywords: ['deadline goal', 'hours to complete', 'in slot now', 'dashboard line'],
      ),
      AssistantFaqEntry(
        id: 'goals.add_complete',
        question: 'How do I add or complete a goal?',
        answer:
            'On Goals, fill in the form and tap Add Goal. For active goals use Complete '
            'or Add Step (multi-step goals). Completing plays a short celebration and '
            'adds points.',
        keywords: [
          'add goal',
          'create goal',
          'complete goal',
          'complete a goal',
          'how do i complete',
          'finish goal',
          'step progress',
          'add step',
        ],
        negativeKeywords: [
          'filter',
          'active vs completed',
          'status filter',
        ],
      ),
      AssistantFaqEntry(
        id: 'goals.templates',
        question: 'What are templates?',
        answer:
            'Templates store preset goal fields. Built-in templates ship with the app; '
            'you can save your own in Template Manager or bulk-create from Multi-template '
            'groups.',
        keywords: ['what are templates', 'goal template', 'save template'],
        negativeKeywords: ['template manager', 'multi-template', 'multi template'],
      ),
      AssistantFaqEntry(
        id: 'goals.template_manager',
        question: 'What is Template Manager vs Multi-template groups?',
        answer:
            'Template Manager saves and edits individual goal presets you can load into '
            'the create form. Multi-template groups let you pick several templates at '
            'once and bulk-create goals (especially useful for time-slot goals).',
        keywords: [
          'template manager',
          'multi-template',
          'multi template',
          'template group',
          'bulk create',
        ],
      ),
      AssistantFaqEntry(
        id: 'goals.repeats',
        question: 'How do repeats work for time slots?',
        answer:
            'When a repeating series is enabled, finishing or rolling the window can spawn '
            'the next instance automatically. Edit an active repeat series from the goals '
            'list when a series is attached to a goal.',
        keywords: ['repeat', 'repeating', 'series', 'every day', 'cadence', 'repeats work', 'how do repeats'],
      ),
      AssistantFaqEntry(
        id: 'goals.earn_points',
        question: 'How do I earn points from goals?',
        answer:
            'Points come from completing goals. The amount depends on category, complexity, '
            'effort, motivation, time, steps, and deadline. Time-slot goals can earn a bonus '
            'multiplier. Extra bonuses can apply when you complete multiple goals in a day.',
        keywords: [
          'earn points',
          'points from goals',
          'reward points',
          'how points',
          'get points',
        ],
        negativeKeywords: ['how many points', 'balance', 'start with'],
      ),
      AssistantFaqEntry(
        id: 'goals.calendar',
        question: 'Can I create time-slot goals from the calendar?',
        answer:
            'Calendar-based creation is not available yet — the app shows “coming soon.” '
            'Use manual create or the bulk wizard from Time-slot goals for now.',
        keywords: ['calendar', 'coming soon', 'calendar goals'],
      ),
      AssistantFaqEntry(
        id: 'goals.status_filters',
        question: 'What are the goal status filters?',
        answer:
            'On Goals, use the status filter to switch between Active and Completed lists. '
            'Category, complexity, and sort options help narrow long lists.',
        keywords: [
          'status filter',
          'active goals',
          'completed goals',
          'filter goals',
          'active vs completed',
        ],
      ),
      AssistantFaqEntry(
        id: 'goals.clear_active',
        question: 'How do I clear active or completed goals?',
        answer:
            'On Goals, use Clear Active Goals or Clear Completed Goals in the actions area. '
            'If any active goal belongs to a repeating schedule, the app asks whether to '
            'cancel those repeats as well.',
        keywords: [
          'clear active',
          'clear completed',
          'remove all goals',
          'delete goals',
        ],
      ),
    ],
  ),
  AssistantFaqSection(
    title: 'Settings',
    entries: [
      AssistantFaqEntry(
        id: 'settings.high_contrast',
        question: 'What does high contrast mode do?',
        answer:
            'High contrast mode increases separation between text, borders, and backgrounds '
            'using your theme colors. Toggle it under Settings → Accessibility (or during '
            'onboarding on the personalize slide).',
        keywords: ['high contrast', 'contrast mode'],
      ),
      AssistantFaqEntry(
        id: 'settings.dyslexia_font',
        question: 'What does dyslexia-friendly font do?',
        answer:
            'It switches the app to the OpenDyslexic typeface and allows more line wrapping '
            'in form fields. Find it under Settings → Accessibility.',
        keywords: ['dyslexia', 'open dyslexic', 'dyslexia font', 'dyslexia friendly'],
      ),
      AssistantFaqEntry(
        id: 'settings.reward_types',
        question: 'What do the reward types do?',
        answer:
            'Settings → Reward Type picks your main reward screen: Mini-games (placeholder '
            'screens today), Progressive visuals (Zen garden), or Customization (theme '
            'colors and fonts unlockable with points).',
        keywords: ['reward type', 'reward types', 'mini-games', 'progressive', 'customization'],
      ),
      AssistantFaqEntry(
        id: 'settings.notification_frequency',
        question: 'What do notification frequency and style do?',
        answer:
            'Frequency (Low / Medium / High / No notifications) controls how often goal '
            'reminders are scheduled. Style (Minimal / Vibrant / Animated) changes reminder '
            'wording and presentation. “No notifications” hides related toggles. Goal '
            'reminders also require system notification permission on your device.',
        keywords: [
          'notification frequency',
          'notification style',
          'reminders',
          'notification permission',
        ],
      ),
      AssistantFaqEntry(
        id: 'settings.daily_affirmations',
        question: 'What are daily affirmations?',
        answer:
            'Optional once-per-day encouraging messages at a time you pick in Settings. '
            'They only schedule when notifications are enabled and the toggle is on.',
        keywords: ['daily affirmation', 'affirmations'],
      ),
      AssistantFaqEntry(
        id: 'settings.ai_encouragement',
        question: 'What is AI Encouragement?',
        answer:
            'AI Encouragement is separate from this Assistant. It sends optional local '
            'notification messages for demanding goals (early, midpoint, before deadline). '
            'Toggle it in Settings when notifications are enabled. No internet is used.',
        keywords: ['ai encouragement', 'encouragement notification'],
        negativeKeywords: ['assistant vs', 'difference between assistant', 'this assistant'],
      ),
      AssistantFaqEntry(
        id: 'settings.pause_goals',
        question: 'What does Pause Goals do?',
        answer:
            'Pause Goals stops goal-related notification scheduling and clears scheduled '
            'reminders until you turn it off again. It does not delete your goals.',
        keywords: ['pause goals', 'pause goal notifications'],
        negativeKeywords: ['delete', 'clear active'],
      ),
      AssistantFaqEntry(
        id: 'settings.sound',
        question: 'How do sound settings work?',
        answer:
            'Settings → Sound enables or disables app sounds. When sound is on, adjust volume '
            'with the slider below.',
        keywords: ['sound', 'volume', 'mute', 'sound settings'],
      ),
      AssistantFaqEntry(
        id: 'settings.delete_account',
        question: 'How do I delete my account and data?',
        answer:
            'Settings → Account → Clear preferences and delete account. You must confirm '
            'twice; this wipes stored data on the device and returns you to the welcome '
            'flow. One profile is supported per device.',
        keywords: ['delete account', 'wipe', 'reset data', 'delete my account'],
      ),
    ],
  ),
  AssistantFaqSection(
    title: 'Rewards & achievements',
    entries: [
      AssistantFaqEntry(
        id: 'rewards.zen_garden',
        question: 'How does the Zen garden work?',
        answer:
            'Earn points from goals, then open Reward when Progressive visuals is selected. '
            'Spend points on plants, growth, and decorations. Tap to select; drag to move on '
            'the sand. Rare color variants can appear as plants grow.',
        keywords: ['zen garden', 'garden', 'plants', 'decor', 'progressive visuals'],
        negativeKeywords: ['restart', 'mutation', 'rebirth'],
      ),
      AssistantFaqEntry(
        id: 'rewards.zen_rebirth',
        question: 'What are Zen garden restart growth and mutations?',
        answer:
            'When a plant or decoration is fully grown, you can spend points to restart '
            'growth from the first stage for another chance at a rare color variant. Each '
            'restart adds to the variant chance (about 5% base, +5% per restart). Variants '
            'can be removed if you prefer the default look.',
        keywords: [
          'restart growth',
          'mutation',
          'variant',
          'rebirth',
          'rare color',
          'restart growth from seed',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.achievements',
        question: 'What are achievements?',
        answer:
            'Achievements track milestones (streaks, categories, counts, and more). Open '
            'Achievements from the Dashboard. When one is ready to claim, you may see a '
            'toast on the Goals screen.',
        keywords: ['what are achievements', 'achievement', 'badge', 'trophy'],
        negativeKeywords: ['claim', 'how do i claim'],
      ),
      AssistantFaqEntry(
        id: 'rewards.claim_achievements',
        question: 'How do I claim achievements?',
        answer:
            'Open Achievements from the Dashboard. When progress is complete, tap an '
            'achievement to claim it. If one becomes ready while you are on Goals, a toast '
            'may appear with the title — open Achievements to claim the reward.',
        keywords: ['claim achievement', 'claim achievements', 'ready to claim'],
      ),
      AssistantFaqEntry(
        id: 'rewards.mini_games',
        question: 'How do mini-games work?',
        answer:
            'Mini-games is a reward type option, but the screens are placeholders today. '
            'Try Progressive visuals (Zen garden) or Customization for full experiences.',
        keywords: ['mini-game', 'minigame', 'mini games', 'how do mini'],
      ),
      AssistantFaqEntry(
        id: 'rewards.starting_points',
        question: 'How many points do I start with?',
        answer:
            'New profiles begin with 50 points by default. Your current balance is always '
            'on the Dashboard.',
        keywords: ['starting points', 'start with', 'default points', 'begin with'],
        negativeKeywords: ['how many points do i have', 'current balance', 'my points'],
      ),
      AssistantFaqEntry(
        id: 'rewards.customization',
        question: 'How does the Customization reward work?',
        answer:
            'Choose Customization as your reward type in Settings, then open Reward from '
            'the Dashboard. Turn on Customized colours to preview and apply custom text and '
            'background colors. The Color Shop lets you spend points to unlock extra swatches; '
            'built-in theme colors stay free.',
        keywords: [
          'customization reward',
          'color shop',
          'unlock color',
          'customized colours',
          'customization screen',
        ],
      ),
    ],
  ),
];

/// Chip labels shown above the message field (6–8 common questions).
const List<String> assistantQuickReplies = [
  'What is a time-slot goal?',
  'How do I add a goal?',
  'How do I earn points?',
  'What is AI Encouragement?',
  'Data privacy policy',
  'How does the Zen garden work?',
];

/// Flat list of every FAQ entry across sections.
List<AssistantFaqEntry> get allAssistantFaqEntries => [
      for (final section in assistantFaqSections) ...section.entries,
    ];

Map<String, AssistantFaqEntry>? _faqByIdCache;

/// Lookup by stable [AssistantFaqEntry.id].
Map<String, AssistantFaqEntry> get assistantFaqById {
  _faqByIdCache ??= {
    for (final entry in allAssistantFaqEntries) entry.id: entry,
  };
  return _faqByIdCache!;
}

AssistantFaqEntry? assistantFaqEntryById(String id) => assistantFaqById[id];

/// Section title containing [entryId], if any.
String? assistantSectionTitleForEntryId(String entryId) {
  for (final section in assistantFaqSections) {
    if (section.entries.any((e) => e.id == entryId)) {
      return section.title;
    }
  }
  return null;
}

/// FAQ entries whose question or answer contains [query] (case-insensitive).
List<AssistantFaqEntry> searchAssistantFaqEntries(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return allAssistantFaqEntries;
  return allAssistantFaqEntries.where((entry) {
    return entry.question.toLowerCase().contains(normalized) ||
        entry.answer.toLowerCase().contains(normalized) ||
        entry.keywords.any((k) => k.toLowerCase().contains(normalized));
  }).toList();
}
