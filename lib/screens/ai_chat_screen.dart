import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text('AI Chat', style: bundle.textStyle),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg['role'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg['role'] == 'user'
                                ? bundle.primaryColor.withOpacity(0.2)
                                : bundle.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg['content']!, style: bundle.textStyle),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonUtils.buildTextField(
                          _controller,
                          'Type your message...',
                          bundle.textStyle,
                          hideText: false,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            _messages.add({'role': 'user', 'content': text});
                          });
                          _controller.clear();
                          final reply = await AiService.sendMessage(text);
                          setState(() {
                            _messages.add({'role': 'ai', 'content': reply});
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
