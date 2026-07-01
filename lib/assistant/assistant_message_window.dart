/// How many chat bubbles stay visible before the user expands history.
const int kAssistantVisibleMessageCount = 8;

List<Map<String, String>> visibleAssistantMessages({
  required List<Map<String, String>> messages,
  required bool showAll,
}) {
  if (showAll || messages.length <= kAssistantVisibleMessageCount) {
    return messages;
  }
  return messages.sublist(messages.length - kAssistantVisibleMessageCount);
}

int hiddenAssistantMessageCount({
  required List<Map<String, String>> messages,
  required bool showAll,
}) {
  if (showAll || messages.length <= kAssistantVisibleMessageCount) {
    return 0;
  }
  return messages.length - kAssistantVisibleMessageCount;
}
