import 'dart:convert';

import 'package:focusNexus/assistant/assistant_chat_reply.dart';

const String kAssistantRelatedQuestionsKey = 'relatedQuestions';
const String kAssistantDisambiguationOptionsKey = 'disambiguationOptions';

/// Removed with assistant create rollback; stripped on read/write.
const String kAssistantPendingActionKey = 'pendingAction';
const String kAssistantPostActionChipsKey = 'postActionChips';

const _deprecatedAssistantMessageKeys = {
  kAssistantPendingActionKey,
  kAssistantPostActionChipsKey,
};

List<String> decodeAssistantStringList(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return decoded.whereType<String>().toList();
}

/// Drops legacy assistant-create keys from a persisted or in-memory message map.
Map<String, String> sanitizeAssistantMessage(Map<String, String> message) {
  if (_deprecatedAssistantMessageKeys.every((key) => !message.containsKey(key))) {
    return message;
  }
  final cleaned = Map<String, String>.from(message);
  for (final key in _deprecatedAssistantMessageKeys) {
    cleaned.remove(key);
  }
  return cleaned;
}

List<Map<String, String>> sanitizeAssistantMessages(
  List<Map<String, String>> messages,
) => messages.map(sanitizeAssistantMessage).toList();

Map<String, String> encodeAssistantReply(AssistantChatReply reply) {
  return {
    'role': 'assistant',
    'content': reply.text,
    if (reply.relatedQuestions.isNotEmpty)
      kAssistantRelatedQuestionsKey: jsonEncode(reply.relatedQuestions),
    if (reply.disambiguationOptions.isNotEmpty)
      kAssistantDisambiguationOptionsKey: jsonEncode(reply.disambiguationOptions),
  };
}
