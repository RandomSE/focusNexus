import 'dart:math';

import 'package:intl/intl.dart';

class TextUtils {
  static int _randomIndex(int length) {
    final random = Random();
    return random.nextInt(length);
  }

  static String _format(DateTime dt) =>
      DateFormat('dd MMMM yyyy HH:mm').format(dt);

  static String buildInitialReminderMessage(
    String goalName,
    String notificationStyle,
    DateTime deadline,
  ) {
    final formattedDeadline = _format(deadline);

    switch (notificationStyle) {
      case 'Vibrant':
        final messages = [
          '🔥 You’ve sparked something! "$goalName" is set for $formattedDeadline.',
          '🎯 Goal locked in: "$goalName" - due by $formattedDeadline.',
          '🌟 Bright beginning! "$goalName" is on track for $formattedDeadline.',
          '📆 Just added: "$goalName" - deadline is $formattedDeadline.',
          '🚀 Ready for lift-off: "$goalName" lands on $formattedDeadline.',
          '💡 Fresh start! "$goalName" is scheduled for $formattedDeadline.',
          '🎉 You’re on your way - "$goalName" wraps up by $formattedDeadline.',
          '📣 New goal alert: "$goalName" ends $formattedDeadline.',
          '⚡ Kickoff complete! "$goalName" is due $formattedDeadline.',
          '🌈 Let the journey begin - "$goalName" finishes by $formattedDeadline.',
        ];
        return messages[_randomIndex(messages.length)];

      case 'Animated':
        final messages = [
          'Just letting you know, "$goalName" is all set. Deadline’s $formattedDeadline.',
          '"$goalName" is officially on the books. Due by $formattedDeadline.',
          'Cool, "$goalName" is in motion. You’ve got until $formattedDeadline.',
          'Hey, "$goalName" was created. Deadline’s $formattedDeadline, just FYI.',
          'Alright, "$goalName" is live. You’ve got time $formattedDeadline’s the mark.',
          'No rush, just a heads-up. "$goalName" is due $formattedDeadline.',
          'You’ve added "$goalName". Deadline’s $formattedDeadline, in case you’re wondering.',
          'Nice, "$goalName" is saved. It wraps up on $formattedDeadline.',
          'Goal noted: "$goalName". Deadline’s $formattedDeadline, all chill.',
          'Just a quiet ping "$goalName" is set with a deadline of $formattedDeadline.',
        ];
        return messages[_randomIndex(messages.length)];

      case 'Minimal':
      default:
        return 'Your goal "$goalName" expires on $formattedDeadline.';
    }
  }

  static String buildFollowUpReminderMessage(
    String goalName,
    int goalId,
    String notificationStyle,
    DateTime deadline,
  ) {
    final formattedDeadline = _format(deadline);

    if (notificationStyle == 'Minimal') {
      return '"$goalName / Id: $goalId" is due $formattedDeadline.';
    }

    if (notificationStyle == 'Vibrant') {
      final messages = [
        'Reminder - "$goalName / Id: $goalId" is closing in. Deadline is $formattedDeadline.',
        'Heads up. "$goalName / Id: $goalId" wraps up by $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is almost there. Due $formattedDeadline.',
        '"$goalName / Id: $goalId" is reaching its finish line. Deadline is $formattedDeadline.',
        'Quick check-in. "$goalName / Id: $goalId" ends $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is on the final stretch. Deadline is $formattedDeadline.',
        '"$goalName / Id: $goalId" is counting down. Due $formattedDeadline.',
        'Time’s ticking. "$goalName" closes $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is nearly done. Deadline is $formattedDeadline.',
        'Just a flash reminder. "$goalName / Id: $goalId" finishes $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    if (notificationStyle == 'Animated') {
      final messages = [
        'Hey again. "$goalName / Id: $goalId" is still hanging out. Deadline is $formattedDeadline.',
        'Just checking in. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is inching closer to $formattedDeadline.',
        'Still time. "$goalName / Id: $goalId" wraps up $formattedDeadline.',
        'Friendly ping. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'You’re doing great. "$goalName / Id: $goalId" finishes $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is quietly approaching $formattedDeadline.',
        'Just keeping you posted. "$goalName / Id: $goalId" ends $formattedDeadline.',
        'Almost there. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'Reminder vibes. "$goalName / Id: $goalId" deadline is $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    // Fallback
    return 'Reminder: "$goalName / Id: $goalId" is due $formattedDeadline.';
  }

  static String buildEncouragementMessage(
    String goalName,
    int goalId,
    String deadline,
    List<String> reasons,
    int encouragementValue,
    int biggestValue,
    int timeScore,
    int stepScore,
    int complexityScore,
    int effortScore,
    int motivationScore,
    String notificationStyle,
  ) {
    // determine dominant factor among the five scores
    final Map<String, int> factorScores = {
      'time': timeScore,
      'steps': stepScore,
      'complexity': complexityScore,
      'effort': effortScore,
      'motivation': motivationScore,
    };

    String dominantFactor = 'overall';
    int dominantScore = 0;
    factorScores.forEach((k, v) {
      if (v > dominantScore) {
        dominantScore = v;
        dominantFactor = k;
      }
    });

    // ensure dominant reason appears first in reasons list if present
    final List<String> orderedReasons = [];
    // try to derive short reason labels for factors, prefer existing reasons if they mention factor
    final Map<String, String> factorReasonFallback = {
      'time': 'This goal requires a lot of time.',
      'steps': 'This goal involves many steps.',
      'complexity': 'This goal is complex.',
      'effort': 'This goal needs high effort.',
      'motivation': 'This goal may be hard to stay motivated for.',
      'overall': 'This goal has multiple challenging aspects.',
    };

    // put matching reasons first (if they contain the factor word), otherwise add fallback for dominant, then other reasons
    bool addedDominantFromList = false;
    for (final r in reasons) {
      if (r.toLowerCase().contains(dominantFactor.toLowerCase())) {
        orderedReasons.add(r);
        addedDominantFromList = true;
      }
    }
    if (!addedDominantFromList) {
      orderedReasons.add(
        factorReasonFallback[dominantFactor] ??
            factorReasonFallback['overall']!,
      );
    }
    // append other unique reasons without duplicating
    for (final r in reasons) {
      if (!orderedReasons.contains(r)) orderedReasons.add(r);
    }

    // helper to pick a variant index deterministically from goalId
    int variantIndex(int variants) {
      final int id = goalId.abs();
      return variants == 0 ? 0 : id % variants;
    }

    // message variant pools (10 each)
    final List<String> minimalVariants = [
      'Keep at $goalName. Small steps count.',
      'One step on $goalName is progress.',
      'Steady pace wins $goalName.',
      'Focus on one tiny move for $goalName.',
      'One thing at a time for $goalName.',
      'Don’t finish, just start $goalName.',
      'Breathe, begin $goalName calmly.',
      'Trust the plan, take the next $goalName step.',
      'One small choice for $goalName is a win.',
      'Consistency beats speed. Keep $goalName going.',
    ];

    final List<String> vibrantVariants = [
      'Momentum’s building. Keep $goalName alive!',
      'Turn $goalName into a bold win!',
      'You’ve got this. Make $goalName happen!',
      'This is your moment. Tackle $goalName!',
      'Small wins grow. Show up for $goalName!',
      'Own it. Start $goalName with confidence!',
      'Right path. Keep $goalName moving!',
      'Purpose fuels progress. Take on $goalName!',
      'Today’s step drives $goalName tomorrow!',
      'Light the fuse. Push through $goalName!',
    ];

    final List<String> animatedVariants = [
      'You’re the star. Shine with $goalName!',
      'Break down $goalName, celebrate parts!',
      'See the finish, step toward $goalName!',
      'Add flair, enjoy $goalName!',
      'You can do $goalName. Believe in yourself!',
      'Treat $goalName as a fun challenge!',
      'Get animated. Show $goalName energy!',
      'Playful steps spark $goalName progress!',
      'Make $goalName a ritual you enjoy!',
      'Bring character. Start $goalName with fun!',
    ];

    // build core message based on rules
    String coreMessage;

    // if a single factor dominates by being > 3, focus on that factor
    if (biggestValue >= 3) {
      // if the dominant factor is time or steps, use their combined intensity for tier base message
      if (dominantFactor == 'time' || dominantFactor == 'steps') {
        final int intensity =
            dominantScore; // caller already used larger scaling
        if (intensity > 13) {
          coreMessage =
              'This goal is a major commitment and worth special attention.';
        } else if (intensity > 8) {
          coreMessage = 'This goal requires notable dedication and planning.';
        } else {
          coreMessage =
              'This goal has important demands in terms of $dominantFactor.';
        }
      } else {
        // dominant is complexity/effort/motivation
        coreMessage =
            'This goal is mainly challenging because of $dominantFactor.';
      }
    } else if (biggestValue == encouragementValue) {
      coreMessage =
          'The primary challenge here is $dominantFactor. Take it step by step.';
    } else {
      coreMessage =
          'You’ve set a meaningful goal. Stay steady and be kind to yourself.';
    }

    // pick styled variant
    final String styleLower = notificationStyle.toLowerCase();
    String variantPrefix;
    if (styleLower == 'minimal') {
      variantPrefix = minimalVariants[variantIndex(minimalVariants.length)];
    } else if (styleLower == 'vibrant') {
      variantPrefix = vibrantVariants[variantIndex(vibrantVariants.length)];
    } else if (styleLower == 'animated') {
      variantPrefix = animatedVariants[variantIndex(animatedVariants.length)];
    } else {
      // fallback to minimal
      variantPrefix = minimalVariants[variantIndex(minimalVariants.length)];
    }

    // assemble reason text: dominant reason first, then up to 3 others to avoid overwhelm
    final int maxReasonsToShow = 3;
    final List<String> reasonsToShow =
        orderedReasons.take(maxReasonsToShow).toList();
    final String reasonText =
        reasonsToShow.isNotEmpty
            ? '\n\nWhy this matters:\n• ${reasonsToShow.join('\n• ')}'
            : '';

    // produce final message: variantPrefix + a short core sentence + reasons + deadline info
    final String finalCore = '$variantPrefix $coreMessage';
    final String deadlineText =
        deadline.isNotEmpty ? '\n\nDeadline: $deadline' : '';

    return '$finalCore$reasonText$deadlineText';
  }

  static final List<String> _affirmations = [
    'You are capable of amazing things.',
    'Today is a fresh start. make it count.',
    'Your effort matters, even in small steps.',
    'You bring value just by being you.',
    'Progress is progress, no matter the pace.',
    'You’ve overcome before. you’ll do it again.',
    'Your presence makes a difference.',
    'You are worthy of kindness and care.',
    'One step forward is still forward.',
    'You’re allowed to take breaks and still succeed.',
    'You are growing, even when it’s hard to see.',
    'You deserve encouragement. here it is.',
    'You’re doing better than you think.',
    'You are not alone in this journey.',
    'You’ve got strength that shows up quietly.',
    'You are enough, exactly as you are.',
    'You’re building something meaningful.',
    'You’ve got this. one moment at a time.',
    'You are resilient and resourceful.',
    'You’re allowed to ask for help.',
    'You are making progress, even when it’s slow.',
    'You’re showing up. and that matters.',
    'You are more than your productivity.',
    'You’re allowed to feel proud of yourself.',
    'You are learning and evolving every day.',
    'You’ve got courage tucked inside you.',
    'You are worthy of rest and renewal.',
    'You’re doing something brave by trying.',
    'You are making space for growth.',
    'You are a work in progress. and that’s beautiful.',
  ];

  static String generateDailyAffirmationBody() {
    final random = Random();
    final index = random.nextInt(_affirmations.length);
    return _affirmations[index];
  }
}