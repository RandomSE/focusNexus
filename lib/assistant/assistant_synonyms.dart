/// Extra tokens appended to a normalized query before keyword scoring.
const Map<String, List<String>> assistantTokenSynonyms = {
  'settings': ['preferences', 'configure'],
  'points': ['balance', 'score'],
  'assistant': ['help', 'guide'],
  'encouragement': ['ai encouragement'],
  'slot': ['time slot', 'window'],
  'privacy': ['data policy', 'data use'],
  'reward': ['rewards'],
  'achievement': ['achievements', 'badge'],
  'garden': ['zen garden'],
  'template': ['templates'],
  'notification': ['notifications', 'reminders'],
  'contrast': ['high contrast'],
};

/// Expands [normalized] with synonym phrases for broader offline matching.
String expandAssistantQuery(String normalized) {
  if (normalized.isEmpty) return normalized;
  final tokens = normalized.split(' ').where((t) => t.isNotEmpty).toSet();
  final extras = <String>[];
  for (final token in tokens) {
    final synonyms = assistantTokenSynonyms[token];
    if (synonyms != null) extras.addAll(synonyms);
  }
  if (extras.isEmpty) return normalized;
  return '$normalized ${extras.join(' ')}';
}
