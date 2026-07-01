/// User-visible Assistant reply plus optional follow-up chips.
class AssistantChatReply {
  const AssistantChatReply({
    required this.text,
    this.relatedQuestions = const [],
    this.disambiguationOptions = const [],
  });

  final String text;
  final List<String> relatedQuestions;
  final List<String> disambiguationOptions;
}
