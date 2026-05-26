import 'dart:math';

/// Selects daily affirmation copy with stable per-day output and contextual variety.
abstract final class AffirmationSelector {
  AffirmationSelector._();

  static const _pool = <String>[
    'You are capable of amazing things.',
    'Today is a fresh start — make it count.',
    'Your effort matters, even in small steps.',
    'You bring value just by being you.',
    'Progress is progress, no matter the pace.',
    'You have overcome hard days before; you can do it again.',
    'Your presence makes a difference.',
    'You are worthy of kindness and care.',
    'One step forward is still forward.',
    'You are allowed to take breaks and still succeed.',
    'You are growing, even when it is hard to see.',
    'You deserve encouragement — here it is.',
    'You are doing better than you think.',
    'You are not alone in this journey.',
    'You have strength that shows up quietly.',
    'You are enough, exactly as you are.',
    'You are building something meaningful.',
    'You have got this — one moment at a time.',
    'You are resilient and resourceful.',
    'You are allowed to ask for help.',
    'You are making progress, even when it is slow.',
    'Showing up matters — and you are showing up.',
    'You are more than your productivity.',
    'You are allowed to feel proud of yourself.',
    'You are learning and evolving every day.',
    'You have courage tucked inside you.',
    'You are worthy of rest and renewal.',
    'Trying itself is brave — keep going.',
    'You are making space for growth.',
    'You are a work in progress, and that is beautiful.',
  ];

  static const _weekdayPrefixes = <int, List<String>>{
    DateTime.monday: [
      'New week, new momentum.',
      'Start steady — you have got this.',
    ],
    DateTime.tuesday: [
      'Keep your rhythm going.',
      'Small wins stack up today.',
    ],
    DateTime.wednesday: [
      'Midweek check-in: you are doing fine.',
      'Halfway through — stay present.',
    ],
    DateTime.thursday: [
      'You are closer than you think.',
      'Push gently, not harshly.',
    ],
    DateTime.friday: [
      'Finish strong, then rest well.',
      'Close the week with intention.',
    ],
    DateTime.saturday: [
      'Recovery is productive too.',
      'Give yourself room to breathe.',
    ],
    DateTime.sunday: [
      'Reset and recharge today.',
      'Prepare calmly for the week ahead.',
    ],
  };

  static const _styleOpeners = <String, List<String>>{
    'Minimal': ['', ''],
    'Vibrant': ['✨ ', '🌟 ', '💪 '],
    'Animated': ['Hey — ', 'Quick note: ', 'Just a nudge: '],
  };

  /// Stable message for [date] (time-of-day ignored). Varies by day and context.
  static String forDate(
    DateTime date, {
    String notificationStyle = 'Minimal',
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final core = _coreForDay(day);
    final prefix = _contextualPrefix(day, notificationStyle);
    if (prefix.isEmpty) return core;
    return '$prefix$core';
  }

  /// Preview upcoming messages (testing / debug).
  static List<String> previewRange(DateTime startDay, int days) {
    if (days <= 0) return const [];
    final start = DateTime(startDay.year, startDay.month, startDay.day);
    return List.generate(
      days,
      (i) => forDate(start.add(Duration(days: i))),
    );
  }

  static int get affirmationCount => _pool.length;

  static String _coreForDay(DateTime day) {
    final index = _indexForDay(day);
    final previousIndex = _indexForDay(day.subtract(const Duration(days: 1)));
    if (index == previousIndex) {
      return _pool[(index + 1) % _pool.length];
    }
    return _pool[index];
  }

  static int _indexForDay(DateTime day) {
    final seed = _daySeed(day);
    final rng = Random(seed);
    return rng.nextInt(_pool.length);
  }

  static int _daySeed(DateTime day) {
    return Object.hash(day.year, day.month, day.day, _pool.length);
  }

  static String _contextualPrefix(DateTime day, String notificationStyle) {
    final weekdayLines = _weekdayPrefixes[day.weekday];
    final styleLines =
        _styleOpeners[notificationStyle] ?? _styleOpeners['Minimal']!;
    final seed = _daySeed(day) ^ notificationStyle.hashCode;
    final rng = Random(seed);

    final useWeekday = rng.nextBool();
    if (useWeekday && weekdayLines != null && weekdayLines.isNotEmpty) {
      return '${weekdayLines[rng.nextInt(weekdayLines.length)]} ';
    }

    final opener = styleLines[rng.nextInt(styleLines.length)];
    return opener;
  }
}
