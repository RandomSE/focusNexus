import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/ai/assistant_intro_notice.dart';
import 'package:focusNexus/assistant/assistant_message_codec.dart';
import 'package:focusNexus/assistant/assistant_message_window.dart';
import 'package:focusNexus/assistant/assistant_scroll_zone.dart';
import 'package:focusNexus/assistant/widgets/assistant_chat_composer.dart';
import 'package:focusNexus/assistant/widgets/assistant_faq_panel.dart';
import 'package:focusNexus/assistant/widgets/assistant_related_questions.dart';
import 'package:focusNexus/assistant/widgets/assistant_section_header.dart';
import 'package:focusNexus/assistant/widgets/assistant_side_nav.dart';
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _userMessageAnchorKey = GlobalKey();
  final GlobalKey _faqContentKey = GlobalKey();
  final GlobalKey _askSectionStartKey = GlobalKey();
  final GlobalKey _askSectionEndKey = GlobalKey();
  bool _showAllMessages = false;
  int? _scrollAnchorMessageIndex;
  AssistantNavZone _navZone = AssistantNavZone.none;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scheduleNavZoneUpdate);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scheduleNavZoneUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleNavZoneUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavZone());
  }

  void _updateNavZone() {
    if (!mounted || !_scrollController.hasClients) return;
    final zone = _measureNavZone();
    if (zone != _navZone) {
      setState(() => _navZone = zone);
    }
  }

  AssistantNavZone _measureNavZone() {
    final scrollContext = _scrollController.position.context.storageContext;
    final scrollableRender = scrollContext.findRenderObject() as RenderBox?;
    if (scrollableRender == null || !scrollableRender.hasSize) {
      return AssistantNavZone.none;
    }

    final viewportTop = scrollableRender.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + scrollableRender.size.height;
    final faqRect = _globalRect(_faqContentKey);
    final askRect = _unionRect(
      _globalRect(_askSectionStartKey),
      _globalRect(_askSectionEndKey),
    );

    return assistantNavZoneFor(
      viewportTop: viewportTop,
      viewportBottom: viewportBottom,
      faqContentRect: faqRect,
      askContentRect: askRect,
    );
  }

  Rect? _globalRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Rect? _unionRect(Rect? a, Rect? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return Rect.fromLTRB(
      a.left < b.left ? a.left : b.left,
      a.top,
      a.right > b.right ? a.right : b.right,
      b.bottom,
    );
  }

  Future<void> _sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    ref.read(aiChatMessagesProvider.notifier).append({
      'role': 'user',
      'content': trimmed,
    });
    setState(() {
      _scrollAnchorMessageIndex =
          ref.read(aiChatMessagesProvider).length - 1;
    });
    _controller.clear();
    await _scrollToPendingUserMessage();
    final reply = await ref.read(aiChatServiceProvider).sendMessage(trimmed);
    if (!mounted) return;
    ref.read(aiChatMessagesProvider.notifier).append(encodeAssistantReply(reply));
    await _scrollToPendingUserMessage();
    _scheduleNavZoneUpdate();
  }

  Future<void> _send() => _sendText(_controller.text);

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _scheduleNavZoneUpdate();
  }

  Future<void> _scrollToBottom() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _scheduleNavZoneUpdate();
  }

  Future<void> _scrollToPendingUserMessage() async {
    for (var i = 0; i < 4; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    final target = _userMessageAnchorKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  void _expandMessageHistory() {
    setState(() => _showAllMessages = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scrollToPendingUserMessage());
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
              title: Text('Assistant', style: bundle.textStyle),
              backgroundColor: bundle.secondaryColor,
              iconTheme: IconThemeData(color: bundle.primaryColor),
            ),
            body: accepted
                ? _buildChatBody(context, bundle)
                : _buildIntroGate(bundle),
          ),
        );
      },
    );
  }

  Widget _buildIntroGate(ThemeBundle bundle) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.support_agent_outlined,
              color: bundle.primaryColor,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'About the Assistant',
              style: bundle.textStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: (bundle.textStyle.fontSize ?? 14) * 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(assistantIntroNotice, style: bundle.textStyle),
            const SizedBox(height: 24),
            CommonUtils.buildElevatedButton(
              'Continue to Assistant',
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
    final visibleMessages = visibleAssistantMessages(
      messages: messages,
      showAll: _showAllMessages,
    );
    final hiddenCount = hiddenAssistantMessageCount(
      messages: messages,
      showAll: _showAllMessages,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final visibleStartIndex = messages.length - visibleMessages.length;

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavZone());

    return Stack(
      children: [
        CustomScrollView(
          key: const Key('assistant-main-scroll'),
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AssistantSectionHeader(bundle: bundle, title: 'FAQ'),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _faqContentKey,
                child: AssistantFaqPanel(
                  bundle: bundle,
                  onQuestionSelected: (question) =>
                      unawaited(_sendText(question)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _askSectionStartKey,
                child: AssistantSectionHeader(
                  bundle: bundle,
                  title: 'Ask a question',
                ),
              ),
            ),
              if (hiddenCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: CommonUtils.buildElevatedButton(
                      'Show $hiddenCount earlier message${hiddenCount == 1 ? '' : 's'}',
                      bundle.primaryColor,
                      bundle.secondaryColor,
                      bundle.textStyle,
                      8,
                      8,
                      _expandMessageHistory,
                      borderColor: bundle.accentColor,
                    ),
                  ),
                ),
              if (messages.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Type below or pick a suggested question.',
                      style: bundle.textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final message = visibleMessages[index];
                    final globalIndex = visibleStartIndex + index;
                    final isScrollAnchor = globalIndex == _scrollAnchorMessageIndex &&
                        message['role'] == 'user';
                    return _MessageBubble(
                      key: isScrollAnchor ? _userMessageAnchorKey : null,
                      bundle: bundle,
                      message: message,
                      onQuestionSelected: (question) =>
                          unawaited(_sendText(question)),
                    );
                  },
                  childCount: visibleMessages.length,
                ),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _askSectionEndKey,
                  child: AssistantChatComposer(
                    bundle: bundle,
                    controller: _controller,
                    onSend: () => unawaited(_send()),
                    onQuickReplySelected: (label) =>
                        unawaited(_sendText(label)),
                  ),
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(bottom: bottomInset + 24)),
            ],
          ),
        AssistantSideNav(
          bundle: bundle,
          zone: _navZone,
          onFaq: () => unawaited(_scrollToTop()),
          onAsk: () => unawaited(_scrollToBottom()),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.bundle,
    required this.message,
    required this.onQuestionSelected,
  });

  final ThemeBundle bundle;
  final Map<String, String> message;
  final ValueChanged<String> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';
    final relatedQuestions =
        decodeAssistantStringList(message[kAssistantRelatedQuestionsKey]);
    final disambiguationOptions =
        decodeAssistantStringList(message[kAssistantDisambiguationOptionsKey]);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? bundle.primaryColor.withValues(alpha: 0.2)
              : bundle.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isUser
            ? Text(
                content,
                style: bundle.textStyle,
                softWrap: true,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: bundle.textStyle,
                    softWrap: true,
                  ),
                  if (disambiguationOptions.isNotEmpty)
                    AssistantRelatedQuestions(
                      bundle: bundle,
                      title: 'Did you mean',
                      questions: disambiguationOptions,
                      onQuestionSelected: onQuestionSelected,
                    ),
                  if (relatedQuestions.isNotEmpty)
                    AssistantRelatedQuestions(
                      bundle: bundle,
                      title: 'You might also ask',
                      questions: relatedQuestions,
                      onQuestionSelected: onQuestionSelected,
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'Copy answer',
                      button: true,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Copy answer',
                        icon: Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: bundle.primaryColor.withValues(alpha: 0.75),
                        ),
                        onPressed: content.isEmpty
                            ? null
                            : () => Clipboard.setData(
                                  ClipboardData(text: content),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
