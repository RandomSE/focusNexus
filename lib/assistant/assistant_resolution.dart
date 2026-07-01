/// How the offline Assistant resolved a user message.
enum AssistantResolutionKind {
  exact,
  keyword,
  disambiguation,
  fallback,
  professionalAdvice,
  achievement,
}

/// Structured resolver output; [text] is user-facing reply content.
class AssistantResolution {
  const AssistantResolution({
    required this.kind,
    required this.text,
    this.entryId,
    this.relatedQuestions = const [],
    this.disambiguationOptions = const [],
    this.relatedEntryIds = const [],
    this.disambiguationEntryIds = const [],
  });

  final AssistantResolutionKind kind;
  final String text;
  final String? entryId;
  final List<String> relatedQuestions;
  final List<String> disambiguationOptions;
  final List<String> relatedEntryIds;
  final List<String> disambiguationEntryIds;
}
