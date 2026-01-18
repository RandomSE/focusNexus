import 'package:flutter/material.dart';
import 'package:focusNexus/utils/BaseState.dart';
import '../services/ai_service.dart';
import '../utils/common_utils.dart';

import '../models/classes/theme_bundle.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends BaseState<AiChatScreen> {
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  bool _themeLoaded = false;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Theme(
      data: _themeData,
      child: Scaffold(
        backgroundColor: _secondaryColor,
        appBar: AppBar(
          title: Text('AI Chat', style: _textStyle),
          backgroundColor: _secondaryColor,
          iconTheme: IconThemeData(color: _primaryColor),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment:
                        msg['role'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            msg['role'] == 'user'
                                ? _primaryColor.withOpacity(0.2)
                                : _secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg['content']!, style: _textStyle),
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
                    child: CommonUtils.buildTextField(_controller, 'Type your message...', _textStyle, hideText: false,),
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
  }

  Future<void> _loadScreen() async {
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);
  }

  Future<void> setThemeDataScreen(ThemeBundle themeBundle) async {
    setState(() {
      _themeData = themeBundle.themeData;
      _primaryColor = themeBundle.primaryColor;
      _secondaryColor = themeBundle.secondaryColor;
      _textStyle = themeBundle.textStyle;
      _themeLoaded = true;
    });
  }
}
