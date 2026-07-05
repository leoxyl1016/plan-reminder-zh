part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, parsed, error, listening }

class ChatState extends Equatable {
  const ChatState({
    required this.messages,
    required this.status,
    required this.draftText,
    this.parsedEvent,
    this.errorMessage,
  });

  factory ChatState.initial() {
    return ChatState.fromMessages(const <ChatMessage>[]);
  }

  factory ChatState.fromMessages(List<ChatMessage> messages) {
    final initialMessages = messages.isEmpty
        ? <ChatMessage>[_welcomeMessage()]
        : messages;

    return ChatState(
      messages: initialMessages,
      status: ChatStatus.initial,
      draftText: '',
    );
  }

  static const Object _sentinel = Object();

  final List<ChatMessage> messages;
  final ChatStatus status;
  final ParsedEvent? parsedEvent;
  final String draftText;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    Object? parsedEvent = _sentinel,
    String? draftText,
    Object? errorMessage = _sentinel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      parsedEvent: parsedEvent == _sentinel
          ? this.parsedEvent
          : parsedEvent as ParsedEvent?,
      draftText: draftText ?? this.draftText,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messages,
    status,
    parsedEvent,
    draftText,
    errorMessage,
  ];

  static ChatMessage _welcomeMessage() {
    return ChatMessage(
      id: 'welcome',
      text: 'Type or speak your plan, and I will build the reminder offline.',
      author: ChatAuthor.assistant,
      createdAt: DateTime.now(),
    );
  }
}
