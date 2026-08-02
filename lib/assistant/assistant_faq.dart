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
  const AssistantFaqSection({required this.title, required this.entries});

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
            'in the reward types you enable in Settings (Progressive visuals / Zen '
            'garden, Customization, and/or Mini-games).',
        keywords: [
          'what is',
          'focusnexus',
          'about',
          'this app',
          'tell me about',
        ],
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
            'Achievements, and a button for each reward type you enabled (Mini-games, '
            'Progressive visuals, Customization). This Assistant is also on the Dashboard.',
        keywords: [
          'navigate',
          'dashboard',
          'where',
          'find',
          'screen',
          'get around',
        ],
        negativeKeywords: ['open settings', 'open goals', 'open achievements'],
      ),
      AssistantFaqEntry(
        id: 'general.open_settings',
        question: 'How do I open Settings?',
        answer:
            'From the Dashboard, tap Settings. You can adjust accessibility, '
            'notifications, sound, reward types, and account options there.',
        keywords: [
          'open settings',
          'settings screen',
          'where is settings',
          'find settings',
        ],
      ),
      AssistantFaqEntry(
        id: 'general.open_goals',
        question: 'How do I open Goals?',
        answer:
            'From the Dashboard, tap Goals. There you can create goals, filter the '
            'list, use templates, and complete active goals.',
        keywords: [
          'open goals',
          'goals screen',
          'where is goals',
          'find goals',
          'get to goals',
        ],
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
        question: 'How do I open a reward screen?',
        answer:
            'From the Dashboard, tap the button named for each reward type you enabled '
            'in Settings (Mini-games, Progressive visuals / Zen garden, or Customization). '
            'You can enable more than one type at once.',
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
            'balance from here - check the Dashboard for the current number.',
        keywords: [
          'how many points',
          'point balance',
          'my point balance',
          'my points',
          'current points',
          'points do i have',
        ],
        negativeKeywords: [
          'start with',
          'starting points',
          'default points',
          'earn points',
        ],
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
            'This Assistant is an offline help guide inside the app - browse the FAQ or '
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
        keywords: [
          'onboarding',
          'welcome',
          'first time',
          'getting started',
          'new user',
        ],
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
        negativeKeywords: [
          'deadline goal',
          'hours to complete',
          'in slot now',
          'dashboard line',
        ],
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
        negativeKeywords: ['filter', 'active vs completed', 'status filter'],
      ),
      AssistantFaqEntry(
        id: 'goals.templates',
        question: 'What are templates?',
        answer:
            'Templates store preset goal fields. Built-in templates ship with the app; '
            'you can save your own in Template Manager or bulk-create from Multi-template '
            'groups.',
        keywords: ['what are templates', 'goal template', 'save template'],
        negativeKeywords: [
          'template manager',
          'multi-template',
          'multi template',
        ],
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
        keywords: [
          'repeat',
          'repeating',
          'series',
          'every day',
          'cadence',
          'repeats work',
          'how do repeats',
        ],
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
            'Calendar-based creation is not available yet - the app shows “coming soon.” '
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
        keywords: [
          'dyslexia',
          'open dyslexic',
          'dyslexia font',
          'dyslexia friendly',
        ],
      ),
      AssistantFaqEntry(
        id: 'settings.reward_types',
        question: 'What do the reward types do?',
        answer:
            'Settings -> Reward types is a checklist: enable one or more of Mini-games, '
            'Progressive visuals, and Customization. At least one must stay on '
            '(subtitle: Select at least one.). Each enabled type gets its own Dashboard '
            'button. Mini-games include Firefly Jar, Stone Balance, Breath Pacer, '
            'Meteor Catch, Word Bloom, and Rain Catcher. Progressive visuals '
            'is the Zen garden (plants, decor, Cherry Blossom Tree). Customization unlocks '
            'theme colors with points on the Customization screen - fonts stay under Settings '
            'Appearance, and Dark mode is under Accessibility.',
        keywords: [
          'reward type',
          'reward types',
          'mini-games',
          'progressive',
          'customization',
          'select at least one',
          'enable more than one',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'color shop',
          'zen garden work',
          'word bloom',
          'rain catcher',
        ],
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
        id: 'settings.open_streak_reminders',
        question: 'What are open streak reminders?',
        answer:
            'Optional local notification that nudges you to open the app again so your '
            'daily open streak does not reset. Find Open streak reminders under Settings '
            'when notifications are enabled. Default is off. No data is uploaded.',
        keywords: [
          'open streak reminder',
          'open streak reminders',
          'streak reminder',
          'come back streak',
        ],
      ),
      AssistantFaqEntry(
        id: 'settings.ai_encouragement',
        question: 'What is AI Encouragement?',
        answer:
            'AI Encouragement is separate from this Assistant. It sends optional local '
            'notification messages for demanding goals (early, midpoint, before deadline). '
            'Toggle it in Settings when notifications are enabled. No internet is used.',
        keywords: ['ai encouragement', 'encouragement notification'],
        negativeKeywords: [
          'assistant vs',
          'difference between assistant',
          'this assistant',
        ],
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
            'Under Settings -> Goals & sound, turn Sound on or off and set the master '
            'Volume. When sound is on, tap Customize sound effects to open the Sound '
            'effects screen for per-channel enable, volume, and Preview.',
        keywords: [
          'sound',
          'volume',
          'mute',
          'sound settings',
          'goals & sound',
        ],
        negativeKeywords: [
          'firefly click',
          'stone landing',
          'game failed',
          'goal creation',
          'what can i customize under sound',
        ],
      ),
      AssistantFaqEntry(
        id: 'settings.sound_effects_detail',
        question: 'What can I customize under sound effects?',
        answer:
            'Open Settings -> Goals & sound -> Customize sound effects. The Sound effects '
            'screen has a Music button (opens unlocked tracks only: Mini-games Breath '
            'background, Zen garden, Cherry blossom stage / Living Canopy / Peace / Power / '
            'Bonsai) and a Music volume slider, then SFX groups: Goals (Goal creation, Goal '
            'completion), Achievements (Achievement completion), and Mini-games (Firefly '
            'click, Stone landing, Game failed, Breath click, Meteor click, Word Bloom '
            'click, Word collected, Rain catch, Rain miss). Each row can be '
            'enabled or muted, has its own volume %, and a Preview button. Master Sound must '
            'be on for these to play.',
        keywords: [
          'sound effects',
          'customize sound',
          'customize sound effects',
          'firefly click',
          'stone landing',
          'game failed',
          'breath click',
          'breath background',
          'meteor click',
          'word bloom click',
          'word collected',
          'rain catch',
          'rain miss',
          'goal creation',
          'goal completion',
          'achievement completion',
          'preview sound',
          'music',
          'music volume',
          'zen garden music',
          'cherry blossom music',
          'bonsai garden',
        ],
      ),
      AssistantFaqEntry(
        id: 'settings.appearance',
        question: 'How do Font size and Dark mode work?',
        answer:
            'Under Settings -> Appearance, adjust Font size with the steppers. Dark mode is '
            'under Settings -> Accessibility with Dyslexia-friendly Font and High Contrast '
            'Mode (also available during onboarding). These are free settings - they are not '
            'Color Shop unlocks.',
        keywords: [
          'font size',
          'dark mode',
          'appearance',
          'theme setting',
          'settings appearance',
          'accessibility dark',
        ],
        negativeKeywords: ['color shop', 'customized colours', 'dyslexia'],
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
            'Enable Progressive visuals in Settings, then open Progressive visuals from the '
            'Dashboard. Use Menu for garden actions (Add plant, Shop, Inventory, Select, '
            'Cherry tree when unlocked). Hide menu clears chrome; a simple tap on the sand '
            'brings Menu back. Tap Add plant for a free seed, then Grow next to advance stages '
            '(the first plant growth can be free). Open Shop for the Decoration shop, or '
            'Inventory to Place or Sell 1 items. Tap to select; drag to move on the sand. '
            'Use Select for bulk moves (Selection on, then To inventory). Skip wait spends '
            'points to skip a growth pause. When unlocked, Visit Cherry Blossom Tree opens '
            'the tree screen. Rare color variants can appear as plants grow.',
        keywords: [
          'zen garden',
          'garden',
          'plants',
          'decor',
          'progressive visuals',
          'add plant',
          'decoration shop',
          'grow next',
        ],
        negativeKeywords: [
          'restart',
          'mutation',
          'rebirth',
          'cherry blossom',
          'bonsai',
          'firefly',
          'stone balance',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.zen_shop_inventory',
        question:
            'How do I buy and manage plants and decorations in the Zen garden?',
        answer:
            'In the Zen garden, Shop opens the Decoration shop (items such as Stepping '
            'stones, Koi pond, Stone lantern, Wood bench, Bamboo fence, Moss rock). Bought '
            'items go to Inventory. From Inventory tap Place on the sand or Sell 1 for '
            'points. On the garden, Select an item and use To inventory to stash it. Grow '
            'next advances plant or decor stages for points (or free when the UI says so). '
            'Skip wait spends points to clear a growth timer early.',
        keywords: [
          'buy decoration',
          'decoration shop',
          'inventory',
          'sell 1',
          'place decor',
          'shop zen',
          'skip wait',
          'to inventory',
        ],
        negativeKeywords: ['cherry blossom', 'restart growth', 'mutation'],
      ),
      AssistantFaqEntry(
        id: 'rewards.zen_rebirth',
        question: 'What are Zen garden restart growth and mutations?',
        answer:
            'When a plant or decoration is fully grown, Restart growth or Restart growth '
            'from seed restarts from the first stage for another chance at a rare color '
            'variant. Restart does not cost points. Each restart raises the variant chance '
            '(about 5% base, +5% per restart). Use Remove special variant if you prefer the '
            'default look. In Settings (when Progressive visuals is enabled), Confirm before '
            'restart growth can be turned back on if you chose Don\'t ask again earlier.',
        keywords: [
          'restart growth',
          'mutation',
          'variant',
          'rebirth',
          'rare color',
          'restart growth from seed',
          'don\'t ask again',
          'remove special variant',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.cherry_blossom_tree',
        question: 'What is the Cherry Blossom Tree?',
        answer:
            'Unlock it when you hold 10,000 points at once or have spent 10,000 lifetime '
            'points in the Zen garden. Then tap Visit Cherry Blossom Tree. Open Menu for '
            'Grow tree / Max tree / Prestige tree (and path choices); View tree or Hide menu '
            'clears chrome so the tree can fill the screen. Each stage has 25 '
            'growth levels. Use Grow tree for one level or Max tree to grow as far as your '
            'wallet allows in the current stage. At level 25, Prestige tree advances to the '
            'next stage. After Living Canopy, choose Power or Peace. '
            'Peace leads to Serenity; Power leads to the Power canopy. '
            'Later, if only one finale path is unlocked, Menu shows Change path with the '
            'unlock price beside Peace / Power. Once both paths are unlocked, Menu shows '
            'only the Peace and Power buttons. Clearing each growth stage unlocks a Cherry '
            'achievement (about 10% of that stage total, min 100 points). Completing Peace or '
            'Power finales unlocks hidden Path of Peace / Path of Power achievements '
            '(500,000 points each). Each grow adds a mini tree toward Bonsai - '
            'open Bonsai from the tree screen.',
        keywords: [
          'cherry blossom',
          'cherry blossom tree',
          'sakura',
          'zen tree',
          'visit cherry blossom',
          '10000 points zen',
          'max tree',
          'prestige tree',
          'grow tree',
          'living canopy',
          'power',
          'peace',
          'serenity',
          'change path',
          'menu cherry',
        ],
        negativeKeywords: [
          'restart',
          'mutation',
          'bonsai garden',
          'what is the bonsai',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.bonsai_garden',
        question: 'What is the Bonsai garden?',
        answer:
            'From the Cherry Blossom Tree screen, tap Bonsai to open Bonsai garden. Growing '
            'and prestiging the tree unlocks mini trees for past stages. Place unlocked '
            'bonsai into empty pots, or use View garden / View tree to browse without editing.',
        keywords: [
          'bonsai garden',
          'bonsai',
          'view garden',
          'view tree',
          'mini tree',
          'pot',
        ],
        negativeKeywords: ['restart', 'mutation', 'what is the cherry'],
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
            'Open Achievements from the Dashboard (the button highlights when rewards are '
            'ready). Tap an achievement to claim it, or use Claim all ready to claim every '
            'completed unclaimed achievement at once - a short message shows how many you '
            'claimed and points gained. If one becomes ready while you are on Goals, a toast '
            'may appear with the title.',
        keywords: [
          'claim achievement',
          'claim achievements',
          'ready to claim',
          'claim all',
          'claim all ready',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.mini_games',
        question: 'How do mini-games work?',
        answer:
            'Open Mini-games from the Dashboard when that reward type is enabled. The hub '
            'shows a Last played shortcut (Firefly Jar until you play something), then each '
            'game title and portrait art. Locked games show a lock and chains; tap to unlock '
            'for points (or see the cost if you cannot afford it yet). Unlocked games open '
            'the lobby for the description, play cost, free entries (one Duration and one '
            'Endless when you unlock), high scores, Mode, and Start. Firefly Jar and '
            'Breath Pacer unlock free; other games cost points to unlock. Start spends points '
            'unless a free entry covers that Start. Firefly Jar, Stone Balance, Breath Pacer, '
            'Meteor Catch, Word Bloom, and Rain Catcher are playable today - ask about any of '
            'them for controls and scoring.',
        keywords: [
          'mini-game',
          'minigame',
          'mini games',
          'how do mini',
          'game lobby',
          'duration high score',
          'endless high score',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'breath pacer',
          'meteor catch',
          'word bloom',
          'rain catcher',
          'drag to aim',
          'catch fireflies',
          'catch meteors',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.firefly_jar',
        question: 'How does Firefly Jar work?',
        answer:
            'From Mini-games, open Firefly Jar. Unlock is free. Duration Start costs 60 '
            'points for a 90-second round. Endless Start costs 160 (60 play + 100 endless). '
            'Opening the lobby grants one free Duration and one free Endless entry the first '
            'time. Tap fireflies to catch them - score is catch count. Lobby shows Duration high '
            'score and Endless high score separately. Endless has no time fail; difficulty '
            'ramps over time. Firefly click plays when that sound channel is on.',
        keywords: [
          'firefly jar',
          'firefly',
          'catch fireflies',
          'jar game',
          'firefly click',
        ],
        negativeKeywords: [
          'stone balance',
          'drag to aim',
          'stack',
          'meteor catch',
          'catch meteors',
          'word bloom',
          'rain catcher',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.stone_balance',
        question: 'How does Stone Balance work?',
        answer:
            'From Mini-games, open Stone Balance. Unlock costs 300 points and grants one free '
            'Duration and one free Endless entry. Duration Start costs 100 points (90 seconds); '
            'Endless Start costs 250 (100 + 150). The first stone places '
            'automatically as a foundation (not counted in height, not at the screen edge). '
            'Drag or tap to aim the ghost stone, then release to drop straight down. '
            'Height is how many stones you stack on top. Too much overhang or leaning the '
            'tower too far sideways topples it after a slide-and-fall animation. Stone '
            'landing and Game failed sounds play when those channels are enabled. '
            'Achievements reward Duration / Endless height milestones and timing out at '
            'height 30 or more.',
        keywords: [
          'stone balance',
          'stack stones',
          'drag to aim',
          'drag or tap to aim',
          'topple',
          'cairn',
          'stone landing',
          'height score',
          'height 30',
          'endless summit',
        ],
        negativeKeywords: [
          'firefly jar',
          'catch fireflies',
          'meteor catch',
          'catch meteors',
          'word bloom',
          'rain catcher',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.breath_pacer',
        question: 'How does Breath Pacer work?',
        answer:
            'From Mini-games, open Breath Pacer. Unlock is free. Duration Start costs 60 '
            'points for a guided 90-second session. Endless Start costs 150 '
            '(60 + 90). Opening the lobby grants one free Duration and one free Endless entry '
            'the first time. Follow the breathing rhythm: Inhale 4, Hold 4, Exhale 6, Hold 2. '
            'A white ring contracts toward the center before each transition. Tap near the '
            'transition for Perfect or Good timing. The score starts at 0 and has no cap, but '
            'only the first qualifying tap per transition counts; misses and rapid repeated '
            'taps reduce it. Your saved high score and score achievements use the highest score '
            'reached during the round, even if later penalties lower the displayed score. '
            'Endless evolves the pattern every 3 cycles and shows a perfect streak; use End or '
            'Back to finish the session. Breath background music and Breath click play together '
            'when those sound channels are on. The short PCM cue mixes over the background '
            'without lowering or stopping the music. There is no fail state.',
        keywords: [
          'breath pacer',
          'breathing game',
          'inhale hold exhale',
          'calm score',
          '4 4 6 2 breathing',
          'settled steady warming up',
          'breath click',
          'breath background',
          'breath pacer high score',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'meteor catch',
          'catch fireflies',
          'stack stones',
          'catch meteors',
          'word bloom',
          'rain catcher',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.meteor_catch',
        question: 'How does Meteor Catch work?',
        answer:
            'From Mini-games, open Meteor Catch. Unlock costs 250 points and grants one free '
            'Duration and one free Endless entry. Duration Start costs 90 '
            'points for a 90-second night-sky run. Endless Start costs 220 (90 + 130). '
            'Drag to draw a swipe path (preview only while your finger is down). On lift, '
            'if the drawn path is at least about a meteor wide, that full polyline becomes a '
            'tangible barrier for 0.5 seconds. A mint edge arrow warns briefly before each '
            'meteor enters (decoy / trick meteors use a red arrow). Meteors are caught only when their head '
            'touches the drawn barrier stroke (contact, not predicted arrival); the '
            'barrier does not clear on a hit, so several meteors can strike the same path. '
            'Short taps create no barrier. Misses give no feedback. Standard / ice / fire '
            'mixes are about 70 / 20 / 10; Endless later adds decoys (-2) and rare golden '
            '(+10) meteors. Score is point total (not catch count). A Streak counter below '
            'score tracks consecutive catches without missing (does not change points); '
            'tier colors step at 10 / 20 / 30 / 40 / 50. Approach arrows scale with speed '
            '(longer = faster). Waves speed up every 15 seconds. Meteor click plays when '
            'that sound channel is on; overlapping late catches start fresh clicks. '
            'Duration achievements track best score at 15 / 35 / 80 / 100 (Meteor Shower '
            'I-IV) and catch streaks at 10 / 20 / 30 / 40 / 50 (Meteor Streak I-V). '
            'Endless Skies is best Endless score 250; Endless Streak is best Endless '
            'catch streak 100. There is no fail state; Duration ends at 90 seconds.',
        keywords: [
          'meteor catch',
          'meteors',
          'catch meteors',
          'swipe meteors',
          'meteor click',
          'night sky meteors',
          'meteor shower',
          'endless skies',
          'meteor streak',
          'endless streak',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'breath pacer',
          'catch fireflies',
          'stack stones',
          'inhale',
          'comet cursor',
          'word bloom',
          'rain catcher',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.word_bloom',
        question: 'How does Word Bloom work?',
        answer:
            'From Mini-games, open Word Bloom. Unlock costs 200 points and grants one free '
            'Duration and one free Endless entry. Duration Start costs 80 '
            'points for a 90-second round. Endless Start costs 200 (80 + 120). '
            'Tap a glowing affirmation to shatter it, then tap each letter so it arcs into '
            'its outline slot. Any glyph of the correct next character scores 2 and fills '
            'the next open slot of that letter (duplicate Es in CENTERED are interchangeable). '
            'A wrong character scores 1 and breaks perfect order. Completing a word adds 5 '
            'points; a perfect-order word also grows an order streak '
            '(+1, +2, +3...) that resets when any letter is out of order. Early words are '
            'shorter (4-5 letters) and later ones grow longer. '
            'Spaces in SHOW UP lock automatically. Duration ends at 90 seconds with no fail '
            'state. Endless keeps going; after 90 seconds words draw from a 9-14 letter pool, '
            'scatter is faster, a gold letter can appear (bonus sparkle on first tap, no '
            'extra score), and near-stopped letters drift toward the edges. Use End or Back '
            'to finish Endless. Word Bloom click plays on each letter collect; Word collected '
            'plays when the full word blooms back together (when those channels are on). '
            'Achievements track Duration best scores at 50 / 100 / 175 / 250 / 350 '
            '(Word Bloom I-V), Endless Lexicon at 1000 score, Duration order streaks '
            'at 3 / 6 / 9 / 12 / 15 (Order Streak I-V), and Endless Order at 30.',
        keywords: [
          'word bloom',
          'affirmation letters',
          'shatter word',
          'letter slots',
          'word bloom click',
          'word collected',
          'endless lexicon',
          'order streak',
          'endless order',
          'gold letter',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'breath pacer',
          'meteor catch',
          'catch fireflies',
          'stack stones',
          'catch meteors',
          'inhale',
          'rain catcher',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.rain_catcher',
        question: 'How does Rain Catcher work?',
        answer:
            'From Mini-games, open Rain Catcher. Unlock costs 150 points and grants one free '
            'Duration and one free Endless entry. Duration Start costs 70 '
            'points for a 90-second round. Endless Start costs 180 (70 + 110). '
            'Drag or tap the lily pad left and right to catch falling raindrops. Score '
            '(Water) is cumulative catch count. A side gauge starts at 0 in '
            'Duration (empty is allowed - Duration does not fail at 0) and at 5 in Endless. '
            'Duration glass marks sit at 30 / 60 / 90 / 120 / 150; Endless uses the same bar '
            'height with denser 45-step marks through 405. Each catch triggers a ripple and '
            'fills the gauge a little, while each miss triggers a splash, drains more than a '
            'catch fills, and resets your Streak to 0. Building a Streak of 1 or more adds '
            'slow passive gauge regeneration. In Endless only, if the gauge reaches 0 the '
            'round ends immediately with Game failed, but your Water score and best streak '
            'are still recorded. Duration ends at 90 seconds; Endless keeps escalating fall '
            'speed after 90 seconds every 20 seconds - use End or Back to finish Endless. '
            'Rain falls at 1.5x the base band in Duration; Endless is one-third quicker '
            '(2x base), with further Endless step ramps after 90 seconds. Drops are spaced '
            'so landings stay at least half a second apart. Rain catch and Rain miss play '
            'on each catch or miss when those sound channels are on. Achievements track '
            'Duration best Water scores at 50 / 75 / 100 / 125 / 150 (Rain Catcher I-V), '
            'Endless Deluge I-IX at 45 / 90 / 135 / 180 / 225 / 270 / 315 / 360 / 405, '
            'Duration catch streaks at 25 / 50 / 75 / 100 / 120 (Rain Streak I-V), and '
            'Endless Rain Streak at 200. The water glass uses marks 30 / 60 / 90 / 120 / 150 '
            'in Duration and 45-step marks through 405 in Endless (same bar height, denser tiers).',
        keywords: [
          'rain catcher',
          'lily pad',
          'catch raindrops',
          'water gauge',
          'rain catch',
          'rain miss',
          'water score',
          'endless deluge',
          'rain streak',
          'endless rain streak',
        ],
        negativeKeywords: [
          'firefly jar',
          'stone balance',
          'breath pacer',
          'meteor catch',
          'word bloom',
          'catch fireflies',
          'stack stones',
          'catch meteors',
          'inhale',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.starting_points',
        question: 'How many points do I start with?',
        answer:
            'New profiles begin with 50 points by default. Your current balance is always '
            'on the Dashboard.',
        keywords: [
          'starting points',
          'start with',
          'default points',
          'begin with',
        ],
        negativeKeywords: [
          'how many points do i have',
          'current balance',
          'my points',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.daily_open',
        question: 'What are daily rewards?',
        answer:
            'The first time you open the app each local calendar day, you get a daily open '
            'bonus: 50 points on day 1 of a streak, then +10 each consecutive day, capped at '
            '350. Missing a day resets the streak. Open-streak achievements (3 / 7 / 30 / 90 '
            'days) are separate claim rewards in Achievements. Nothing is uploaded.',
        keywords: [
          'daily reward',
          'daily rewards',
          'daily open',
          'open streak',
          'streak points',
          'first open',
          'login bonus',
        ],
      ),
      AssistantFaqEntry(
        id: 'rewards.customization',
        question: 'How does the Customization reward work?',
        answer:
            'Enable Customization under Settings -> Reward types, then open Customization '
            'from the Dashboard. Turn on Customized colours to preview and apply custom text '
            'and background colors (Theme Preview, then Save). Color Shop swatches cost '
            'points; built-in theme colors stay free. Pick Custom Color costs 10,000 points '
            'for any RGB. Font size, Dark mode, and Dyslexia-friendly Font are free under '
            'Settings Appearance / Accessibility - they are not Color Shop items.',
        keywords: [
          'customization reward',
          'color shop',
          'unlock color',
          'customized colours',
          'customization screen',
          'theme preview',
          'pick custom color',
        ],
      ),
    ],
  ),
];

/// Chip labels shown above the message field (6-8 common questions).
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
