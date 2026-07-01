import 'package:focusNexus/assistant/assistant_live_context.dart';
import 'package:focusNexus/assistant/assistant_resolution.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';

bool _looksLikeAchievementLookup(String normalized) {
  const faqExclusions = [
    'claim achievement',
    'what are achievement',
    'how do mini',
    'what is ai encouragement',
  ];
  if (faqExclusions.any(normalized.contains)) return false;

  const triggers = [
    'badge',
    'trophy',
    'how do i get',
    'how to get',
    'how do i unlock',
    'how to unlock',
    'goal setter',
    'completionist',
    'juggler',
  ];
  return triggers.any(normalized.contains);
}

int _scoreAchievementHint(String normalized, AssistantAchievementHint hint) {
  final title = normalizeAssistantQuery(hint.title);
  final task = normalizeAssistantQuery(hint.task);
  var score = 0;

  if (normalized.contains(title)) score += 8;

  for (final token in title.split(' ')) {
    if (token.length < 4) continue;
    if (normalized.contains(token)) score += 2;
  }

  for (final token in task.split(' ')) {
    if (token.length < 5) continue;
    if (normalized.contains(token)) score += 1;
  }

  return score;
}

/// Matches achievement glossary queries when [context.achievements] is available.
AssistantResolution? resolveAchievementGlossaryQuery(
  String message, {
  required AssistantLiveContext liveContext,
}) {
  final normalized = normalizeAssistantQuery(message);
  if (normalized.isEmpty || liveContext.achievements.isEmpty) return null;
  if (!_looksLikeAchievementLookup(normalized)) return null;

  AssistantAchievementHint? best;
  var bestScore = 0;
  for (final hint in liveContext.achievements) {
    final score = _scoreAchievementHint(normalized, hint);
    if (score > bestScore) {
      bestScore = score;
      best = hint;
    }
  }

  if (best == null || bestScore < 4) return null;

  return AssistantResolution(
    kind: AssistantResolutionKind.achievement,
    text:
        '“${best.title}” — ${best.task} '
        'Open Achievements from the Dashboard to track progress and claim rewards.',
  );
}
