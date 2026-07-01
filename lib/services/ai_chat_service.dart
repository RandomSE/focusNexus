import 'package:focusNexus/assistant/assistant_chat_reply.dart';

/// Abstraction for Assistant chat backends (testable via Riverpod override).
abstract class AiChatService {
  Future<AssistantChatReply> sendMessage(String message);
}
