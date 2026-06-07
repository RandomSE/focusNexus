import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Abstraction for AI chat backends (testable via Riverpod override).
abstract class AiChatService {
  Future<String> sendMessage(String message);
}

/// Groq-backed chat client (reads [GROQ_API_KEY] from dotenv).
class GroqAiChatService implements AiChatService {
  const GroqAiChatService();

  static const _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? 'No response';
    }
    return 'Error: ${response.statusCode} ${response.body}';
  }
}
