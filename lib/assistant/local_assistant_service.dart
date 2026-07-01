import 'package:focusNexus/assistant/assistant_chat_reply.dart';
import 'package:focusNexus/assistant/assistant_live_context.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';
import 'package:focusNexus/services/ai_chat_service.dart';

/// Offline app guide — keyword FAQ matching, no network.
class LocalAssistantService implements AiChatService {
  LocalAssistantService({
    Future<AssistantLiveContext> Function()? readLiveContext,
  }) : _readLiveContext = readLiveContext ?? _emptyContext;

  final Future<AssistantLiveContext> Function() _readLiveContext;

  static Future<AssistantLiveContext> _emptyContext() async =>
      const AssistantLiveContext();

  @override
  Future<AssistantChatReply> sendMessage(String message) async {
    final liveContext = await _readLiveContext();
    final resolution = resolveAssistantQuery(message, liveContext: liveContext);
    return assistantChatReplyFromResolution(resolution);
  }
}
