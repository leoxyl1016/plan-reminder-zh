import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    final bubbleColor = switch (message.author) {
      ChatAuthor.user => theme.colorScheme.primary,
      ChatAuthor.system => theme.colorScheme.secondary.withValues(alpha: 0.16),
      ChatAuthor.assistant => theme.colorScheme.surface,
    };

    final textColor = switch (message.author) {
      ChatAuthor.user => Colors.white,
      ChatAuthor.assistant => theme.colorScheme.onSurface,
      ChatAuthor.system => theme.colorScheme.onSurface,
    };

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: Border.all(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.8),
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                message.createdAt.toTimeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
