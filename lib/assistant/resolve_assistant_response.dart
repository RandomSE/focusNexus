import 'package:focusNexus/assistant/assistant_achievement_match.dart';
import 'package:focusNexus/assistant/assistant_chat_reply.dart';
import 'package:focusNexus/assistant/assistant_faq.dart';
import 'package:focusNexus/assistant/assistant_fuzzy_match.dart';
import 'package:focusNexus/assistant/assistant_live_context.dart';
import 'package:focusNexus/assistant/assistant_resolution.dart';
import 'package:focusNexus/assistant/assistant_synonyms.dart';

const _fallbackResponse =
    'I am not sure about that. Browse the FAQ sections above or ask about '
    'goals, time slots, points, settings, rewards, or privacy.';

const _professionalAdviceResponse =
    'I cannot give medical, mental health, legal, or financial advice. '
    'Please speak with a qualified professional. I can help with how '
    'FocusNexus features work if you would like.';

/// Normalized phrasing → canonical FAQ entry id (quick replies and aliases).
const Map<String, String> assistantQueryAliases = {
  'what does high contrast do': 'settings.high_contrast',
  'data privacy policy': 'general.data_policy',
  'how do i earn points': 'goals.earn_points',
  'what are reward types': 'settings.reward_types',
  'how do i add a goal': 'goals.add_complete',
  'how do i complete a goal': 'goals.add_complete',
  'what is my point balance': 'general.points_balance',
  'how do i open settings': 'general.open_settings',
  'open settings': 'general.open_settings',
  'open goals': 'general.open_goals',
  'open achievements': 'general.open_achievements',
  'open reward': 'general.open_reward',
  'assistant vs ai encouragement': 'general.assistant_vs_encouragement',
  'difference between assistant and ai encouragement':
      'general.assistant_vs_encouragement',
  'what does in slot now mean': 'general.in_slot_now',
  'active vs completed goals filter': 'goals.status_filters',
  'explain time windows for goals': 'goals.time_slot',
};

/// Normalizes user text for keyword matching.
String normalizeAssistantQuery(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _looksLikeProfessionalAdviceRequest(String normalized) {
  const triggers = [
    'do i have adhd',
    'diagnose',
    'diagnosis',
    'medication',
    'therapy',
    'suicide',
    'self harm',
    'depression treatment',
    'am i autistic',
  ];
  return triggers.any(normalized.contains);
}

bool _normalizedContains(String normalized, String phrase) {
  final key = normalizeAssistantQuery(phrase);
  if (key.isEmpty) return false;
  if (normalized.contains(key)) return true;
  if (key.contains(' ')) {
    final parts = key.split(' ').where((part) => part.length >= 4);
    if (parts.isEmpty) return false;
    return parts.every((part) => _normalizedContains(normalized, part));
  }
  return assistantFuzzyContains(normalized, key);
}

int _scoreEntry(AssistantFaqEntry entry, String normalized) {
  for (final negative in entry.negativeKeywords) {
    if (_normalizedContains(normalized, negative)) {
      return 0;
    }
  }

  var score = 0;
  for (final keyword in entry.keywords) {
    final key = normalizeAssistantQuery(keyword);
    if (key.isEmpty) continue;
    if (_normalizedContains(normalized, key)) {
      score += key.contains(' ') ? 4 : 2;
    }
  }

  final questionNorm = normalizeAssistantQuery(entry.question);
  for (final token in questionNorm.split(' ')) {
    if (token.length < 5) continue;
    if (_normalizedContains(normalized, token)) score += 1;
  }
  return score;
}

class _ScoredEntry {
  const _ScoredEntry(this.entry, this.score);

  final AssistantFaqEntry entry;
  final int score;
}

List<AssistantFaqEntry> _relatedEntries(AssistantFaqEntry entry, {int limit = 2}) {
  for (final section in assistantFaqSections) {
    if (!section.entries.any((e) => e.id == entry.id)) continue;
    return section.entries.where((e) => e.id != entry.id).take(limit).toList();
  }
  return const [];
}

String _formatDisambiguation(List<AssistantFaqEntry> entries) {
  final buffer = StringBuffer('I found a few possible topics:\n\n');
  for (final entry in entries) {
    final snippet = entry.answer.length > 120
        ? '${entry.answer.substring(0, 117)}...'
        : entry.answer;
    buffer.writeln('• ${entry.question} — $snippet');
  }
  return buffer.toString().trimRight();
}

AssistantResolution _resolutionForEntry(
  AssistantFaqEntry entry,
  AssistantResolutionKind kind, {
  AssistantLiveContext? liveContext,
}) {
  final related = _relatedEntries(entry);
  final text = _applyLiveContextToAnswer(
    entry: entry,
    answer: entry.answer,
    liveContext: liveContext,
  );
  return AssistantResolution(
    kind: kind,
    entryId: entry.id,
    text: text,
    relatedQuestions: related.map((e) => e.question).toList(),
    relatedEntryIds: related.map((e) => e.id).toList(),
  );
}

String _applyLiveContextToAnswer({
  required AssistantFaqEntry entry,
  required String answer,
  AssistantLiveContext? liveContext,
}) {
  if (liveContext == null) return answer;
  if (entry.id == 'general.points_balance' && liveContext.pointsBalance != null) {
    return 'You currently have ${liveContext.pointsBalance} points. '
        'Your balance is also shown at the top of the Dashboard.';
  }
  return answer;
}

AssistantResolution _applyLiveContext(
  AssistantResolution resolution, {
  AssistantLiveContext? liveContext,
}) {
  if (liveContext == null || resolution.entryId == null) return resolution;
  final entry = assistantFaqEntryById(resolution.entryId!);
  if (entry == null) return resolution;
  final text = _applyLiveContextToAnswer(
    entry: entry,
    answer: resolution.text,
    liveContext: liveContext,
  );
  if (text == resolution.text) return resolution;
  return AssistantResolution(
    kind: resolution.kind,
    text: text,
    entryId: resolution.entryId,
    relatedQuestions: resolution.relatedQuestions,
    disambiguationOptions: resolution.disambiguationOptions,
    relatedEntryIds: resolution.relatedEntryIds,
    disambiguationEntryIds: resolution.disambiguationEntryIds,
  );
}

/// Structured offline intent resolution for [message].
AssistantResolution resolveAssistantQuery(
  String message, {
  AssistantLiveContext? liveContext,
}) {
  final normalized = normalizeAssistantQuery(message);
  if (normalized.isEmpty) {
    return const AssistantResolution(
      kind: AssistantResolutionKind.fallback,
      text: _fallbackResponse,
    );
  }
  if (_looksLikeProfessionalAdviceRequest(normalized)) {
    return const AssistantResolution(
      kind: AssistantResolutionKind.professionalAdvice,
      text: _professionalAdviceResponse,
    );
  }

  for (final entry in allAssistantFaqEntries) {
    if (normalizeAssistantQuery(entry.question) == normalized) {
      return _resolutionForEntry(
        entry,
        AssistantResolutionKind.exact,
        liveContext: liveContext,
      );
    }
  }

  // Priority: aliases and quick-reply aliases before achievement glossary.
  final aliasId = assistantQueryAliases[normalized];
  if (aliasId != null) {
    final entry = assistantFaqEntryById(aliasId);
    if (entry != null) {
      return _resolutionForEntry(
        entry,
        AssistantResolutionKind.exact,
        liveContext: liveContext,
      );
    }
  }

  for (final quickReply in assistantQuickReplies) {
    if (normalizeAssistantQuery(quickReply) == normalized) {
      final alias = assistantQueryAliases[normalized];
      if (alias != null) {
        final entry = assistantFaqEntryById(alias);
        if (entry != null) {
          return _resolutionForEntry(
            entry,
            AssistantResolutionKind.exact,
            liveContext: liveContext,
          );
        }
      }
    }
  }

  final achievementResolution = resolveAchievementGlossaryQuery(
    message,
    liveContext: liveContext ?? const AssistantLiveContext(),
  );
  if (achievementResolution != null) {
    return achievementResolution;
  }

  final expanded = expandAssistantQuery(normalized);
  final scored = <_ScoredEntry>[];
  for (final entry in allAssistantFaqEntries) {
    final score = _scoreEntry(entry, expanded);
    if (score > 0) scored.add(_ScoredEntry(entry, score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));

  if (scored.isEmpty) {
    return const AssistantResolution(
      kind: AssistantResolutionKind.fallback,
      text: _fallbackResponse,
    );
  }

  final best = scored.first;
  final secondScore = scored.length > 1 ? scored[1].score : 0;
  final margin = best.score - secondScore;

  final ambiguous = best.score < 4 &&
      secondScore > 0 &&
      margin <= 1 &&
      scored.length > 1;
  if (ambiguous) {
    final options = scored.take(2).map((s) => s.entry).toList();
    return AssistantResolution(
      kind: AssistantResolutionKind.disambiguation,
      text: _formatDisambiguation(options),
      disambiguationOptions: options.map((e) => e.question).toList(),
      disambiguationEntryIds: options.map((e) => e.id).toList(),
    );
  }

  if (best.score >= 2 && (best.score >= 4 || margin >= 2 || secondScore == 0)) {
    return _applyLiveContext(
      _resolutionForEntry(
        best.entry,
        AssistantResolutionKind.keyword,
        liveContext: liveContext,
      ),
      liveContext: liveContext,
    );
  }

  return const AssistantResolution(
    kind: AssistantResolutionKind.fallback,
    text: _fallbackResponse,
  );
}

/// Picks the best FAQ answer for [message], or a tier B/C template.
String resolveAssistantResponse(
  String message, {
  AssistantLiveContext? liveContext,
}) =>
    resolveAssistantQuery(message, liveContext: liveContext).text;

/// Maps a structured resolution to a chat reply for the UI layer.
AssistantChatReply assistantChatReplyFromResolution(AssistantResolution resolution) {
  return AssistantChatReply(
    text: resolution.text,
    relatedQuestions: resolution.relatedQuestions,
    disambiguationOptions: resolution.disambiguationOptions,
  );
}
