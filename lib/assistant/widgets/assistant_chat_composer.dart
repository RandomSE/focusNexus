import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:focusNexus/assistant/widgets/assistant_quick_replies.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Label above the ask field (short enough for large dyslexia text).
const String kAssistantQuestionFieldLabel = 'Your question';

/// Widget-test anchor for the ask-section text field.
const Key kAssistantQuestionFieldKey = Key('assistant-question-field');

/// Quick replies and text field at the end of the scrollable ask section.
class AssistantChatComposer extends StatelessWidget {
  const AssistantChatComposer({
    super.key,
    required this.bundle,
    required this.controller,
    required this.onSend,
    required this.onQuickReplySelected,
  });

  final ThemeBundle bundle;
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickReplySelected;

  @override
  Widget build(BuildContext context) {
    final dyslexia = usesOpenDyslexic(bundle.textStyle);
    final field = KeyedSubtree(
      key: kAssistantQuestionFieldKey,
      child: _AssistantQuestionField(
        bundle: bundle,
        controller: controller,
        onSend: onSend,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssistantQuickReplies(
          bundle: bundle,
          onSelected: onQuickReplySelected,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: dyslexia
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: onSend,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: field),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: onSend,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AssistantQuestionField extends StatelessWidget {
  const _AssistantQuestionField({
    required this.bundle,
    required this.controller,
    required this.onSend,
  });

  final ThemeBundle bundle;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final dyslexia = usesOpenDyslexic(bundle.textStyle);
    return labeledFormField(
      label: kAssistantQuestionFieldLabel,
      textStyle: bundle.textStyle,
      field: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey != LogicalKeyboardKey.enter) {
            return KeyEventResult.ignored;
          }
          if (HardwareKeyboard.instance.isShiftPressed) {
            return KeyEventResult.ignored;
          }
          onSend();
          return KeyEventResult.handled;
        },
        child: TextField(
          style: bundle.textStyle,
          controller: controller,
          decoration: formInputDecoration(
            label: kAssistantQuestionFieldLabel,
            textStyle: bundle.textStyle,
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          minLines: 1,
          maxLines: dyslexia ? 4 : 1,
          keyboardType: TextInputType.text,
        ),
      ),
    );
  }
}
