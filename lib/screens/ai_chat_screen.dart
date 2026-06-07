import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/ai/ai_chat_legal_notice.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(aiChatMessagesProvider.notifier).append({
      'role': 'user',
      'content': text,
    });
    _controller.clear();
    final reply = await ref.read(aiChatServiceProvider).sendMessage(text);
    ref.read(aiChatMessagesProvider.notifier).append({
      'role': 'ai',
      'content': reply,
    });
  }

  @override
  Widget build(BuildContext context) {
    final accepted = ref.watch(aiChatDisclaimerAcceptedProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text('AI Chat', style: bundle.textStyle),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: accepted
                ? _buildChatBody(context, bundle)
                : _buildDisclaimerGate(bundle),
          ),
        );
      },
    );
  }

  Widget _buildDisclaimerGate(ThemeBundle bundle) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: bundle.primaryColor,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Before you use AI Chat',
              style: bundle.textStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: (bundle.textStyle.fontSize ?? 14) * 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(aiChatLegalNotice, style: bundle.textStyle),
            const SizedBox(height: 24),
            CommonUtils.buildElevatedButton(
              'I understand and agree',
              bundle.primaryColor,
              bundle.secondaryColor,
              bundle.textStyle,
              12,
              10,
              () => ref.read(aiChatDisclaimerAcceptedProvider.notifier).accept(),
              borderColor: bundle.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody(BuildContext context, ThemeBundle bundle) {
    final messages = ref.watch(aiChatMessagesProvider);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Align(
                alignment: msg['role'] == 'user'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg['role'] == 'user'
                        ? bundle.primaryColor.withValues(alpha: 0.2)
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
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.paddingOf(context).bottom,
          ),
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
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
