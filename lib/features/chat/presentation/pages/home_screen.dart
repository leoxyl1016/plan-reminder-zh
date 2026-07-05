import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../parser/domain/entities/parsed_event.dart';
import '../../../reminder/domain/entities/reminder_event.dart';
import '../../../reminder/presentation/pages/add_edit_event_screen.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/parse_preview_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest(animate: false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) {
        return;
      }

      final target = _chatScrollController.position.maxScrollExtent;
      if (animate) {
        _chatScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        _chatScrollController.jumpTo(target);
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    context.read<ChatBloc>().add(ChatMessageSubmitted(message));
    _messageController.clear();
    context.read<ChatBloc>().add(const ChatDraftUpdated(''));
  }

  Future<void> _confirmParsedEvent(ParsedEvent parsedEvent) async {
    var dateTime = parsedEvent.dateTime;

    if (!parsedEvent.hasExplicitTime) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(parsedEvent.dateTime),
      );

      if (selectedTime == null || !mounted) {
        return;
      }

      dateTime = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    }

    if (!mounted) {
      return;
    }

    final reminderEvent = ReminderEvent(
      id: _uuid.v4(),
      title: parsedEvent.title,
      dateTime: dateTime,
      location: parsedEvent.location,
      createdAt: DateTime.now(),
      sourceText: parsedEvent.sourceText,
      sourceType: ReminderSourceType.chat,
    );

    context.read<CalendarBloc>().add(CalendarEventSaved(reminderEvent));
    context.read<ChatBloc>().add(ChatReminderConfirmed(reminderEvent));
  }

  Future<void> _editParsedEvent(ParsedEvent parsedEvent) async {
    final reminderEvent = await Navigator.of(context).push<ReminderEvent>(
      MaterialPageRoute<ReminderEvent>(
        builder: (_) => AddEditEventScreen(parsedEvent: parsedEvent),
      ),
    );

    if (reminderEvent == null || !mounted) {
      return;
    }

    context.read<CalendarBloc>().add(CalendarEventSaved(reminderEvent));
    context.read<ChatBloc>().add(ChatReminderConfirmed(reminderEvent));
  }

  void _toggleVoice(ChatState state) {
    if (state.status == ChatStatus.listening) {
      context.read<ChatBloc>().add(const ChatVoiceInputStopped());
      return;
    }
    context.read<ChatBloc>().add(const ChatVoiceInputStarted());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (ChatState previous, ChatState current) =>
              previous.messages.length != current.messages.length,
          listener: (BuildContext context, ChatState state) {
            _scrollToLatest();
          },
        ),
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (ChatState previous, ChatState current) =>
              previous.draftText != current.draftText,
          listener: (BuildContext context, ChatState state) {
            if (_messageController.text == state.draftText) {
              return;
            }

            _messageController.value = TextEditingValue(
              text: state.draftText,
              selection: TextSelection.collapsed(
                offset: state.draftText.length,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (BuildContext context, ChatState chatState) {
          final theme = Theme.of(context);
          final surface = theme.colorScheme.surface.withValues(alpha: 0.92);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: <Widget>[
                  _AssistantBanner(state: chatState),
                  const SizedBox(height: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.9),
                        ),
                      ),
                      child: ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                        physics: const BouncingScrollPhysics(),
                        itemCount: chatState.messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final message = chatState.messages[index];
                          return ChatBubble(
                            key: ValueKey<String>(message.id),
                            message: message,
                          )
                              .animate()
                              .fadeIn(duration: 220.ms)
                              .slideY(begin: 0.12, end: 0);
                        },
                      ),
                    ),
                  ),
                  if (chatState.parsedEvent != null) ...<Widget>[
                    const SizedBox(height: 10),
                    ParsePreviewCard(
                      parsedEvent: chatState.parsedEvent!,
                      onConfirm: () => _confirmParsedEvent(chatState.parsedEvent!),
                      onEdit: () => _editParsedEvent(chatState.parsedEvent!),
                      onDismiss: () {
                        context.read<ChatBloc>().add(
                              const ChatParsedEventDismissed(),
                            );
                      },
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.15, end: 0),
                  ],
                  const SizedBox(height: 10),
                  _Composer(
                    controller: _messageController,
                    isListening: chatState.status == ChatStatus.listening,
                    onVoiceTap: () => _toggleVoice(chatState),
                    onSendTap: _sendMessage,
                    onChanged: (String value) {
                      context.read<ChatBloc>().add(ChatDraftUpdated(value));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isListening,
    required this.onVoiceTap,
    required this.onSendTap,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onVoiceTap;
  final VoidCallback onSendTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.95)),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onChanged: onChanged,
              onSubmitted: (_) => onSendTap(),
              decoration: InputDecoration(
                hintText: '输入日程内容...',
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isListening ? 1.1 : 1,
            child: IconButton.filledTonal(
              onPressed: onVoiceTap,
              icon: Icon(isListening ? Icons.stop : Icons.mic_none),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onSendTap,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '提醒助手',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  state.status == ChatStatus.listening
                      ? '正在聆听，请自然地说出您的日程安排。'
                      : '输入或说出日程，我会解析日期、时间和地点。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
