/// Curated ADHD-friendly dashboard motivators (text only, offline).
abstract final class AdhdMotivatorPack {
  AdhdMotivatorPack._();

  static const lines = <String>[
    'One tap. That is the whole job right now.',
    'Your brain is not broken. It is a firework that forgot the fuse.',
    'Not motivated? Do it scared. Do it tired. Do it anyway.',
    'The goal does not care how you feel. It just needs five minutes.',
    'You opened the app. The hardest part statistically just happened.',
    'Borrow energy from the version of you that already finished this.',
    'Tiny counts. Tiny stacks. Tiny becomes everything eventually.',
    'Start ugly. Fix it later. Later you is a genius.',
    'Your attention wandered. Welcome back. We saved your seat.',
    'One clumsy step beats one perfect plan every single time.',
    'The task shrank while you were not looking. Check again.',
    'You are not procrastinating. You are pre-starting. Now start.',
    'Chaos is your native language. Completion is the dialect. Speak it.',
    'Resistance is just fear wearing a very boring disguise.',
    'The only vibe you need is slightly less stuck than a minute ago.',
    'Your brain wants novelty. Here is some: finish something.',
    'Low energy mode is valid. Low energy mode can still ship a win.',
    'Done imperfectly at 2pm beats perfect at never.',
    'You are mid-quest. Inventory check: one action available. Use it.',
    'The task will not get easier by watching it. Poke it once.',
    'Hyperfocus is offline. Manual mode works fine. Slow is fine.',
    'This is not a guilt trip. It is a boarding call. You can still make it.',
    'Your future self is rooting for you loud enough to echo backward.',
    'Two minutes of real is worth ten hours of almost.',
    'Pick the smallest piece of the thing. Do only that. Stop. Celebrate.',
    'The checklist is not judging you. The checklist is just waiting.',
    'Momentum does not need a running start. It just needs a nudge.',
    'You have rescheduled this before. Today it gets to be different.',
    'Brain fog is weather. You can drive in weather.',
    'Rest was not wasted time. It was the last step. Now comes this step.',
    'You do not need to want to. You just need to begin.',
    'Showing up distracted still counts as showing up.',
    'The goal is patient. More patient than you think. Go meet it.',
    'Progress does not require inspiration. It requires a tap.',
    'Not everything has to be hard. This next step is just a step.',
    'You remembered to check. That is already the brain doing its job.',
    'Forget the whole list. What is the one thing? Just that one.',
    'You have done harder things before breakfast. This is after breakfast.',
    'Reward yourself before if that is what it takes. Then go.',
    'A bad start that continues is worth more than a great start abandoned.',
    'Your goals are not punishments. They are yours. You chose them.',
    'There is no perfect moment. There is this moment. It is sufficient.',
    'You are not behind. The timeline was always flexible.',
    'Name the task out loud. Hear it. It is smaller than it sounded in your head.',
    'Distraction visited. It has to leave now. Show it the door.',
    'The part of you that opened this app is right. Listen to that part.',
    'You do not have to finish today. You have to start today.',
    'Five seconds of courage gets more done than five hours of thinking.',
    'Imposter syndrome means you care. Good. Use that.',
    'Your wins from yesterday still count. Stack one more on top.',
  ];

  /// Rotates through [lines] by [index] (wraps). Empty pack returns a fallback.
  static String lineAt(int index) {
    if (lines.isEmpty) return 'You showed up. That counts.';
    final i = index % lines.length;
    return lines[i < 0 ? i + lines.length : i];
  }

  /// Stable daily seed from local calendar day (time ignored).
  static int seedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static String forDate(DateTime date) => lineAt(seedForDate(date));
}