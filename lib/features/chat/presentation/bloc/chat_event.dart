part of 'chat_bloc.dart';

abstract class ChatEventAction extends Equatable {
  const ChatEventAction();

  @override
  List<Object?> get props => <Object?>[];
}

class ChatDraftUpdated extends ChatEventAction {
  const ChatDraftUpdated(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

class ChatMessageSubmitted extends ChatEventAction {
  const ChatMessageSubmitted(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ChatVoiceInputStarted extends ChatEventAction {
  const ChatVoiceInputStarted();
}

class ChatVoiceInputStopped extends ChatEventAction {
  const ChatVoiceInputStopped();
}

class ChatVoiceTranscriptUpdated extends ChatEventAction {
  const ChatVoiceTranscriptUpdated({
    required this.transcript,
    required this.isFinal,
  });

  final String transcript;
  final bool isFinal;

  @override
  List<Object?> get props => <Object?>[transcript, isFinal];
}

class ChatParsedEventDismissed extends ChatEventAction {
  const ChatParsedEventDismissed();
}

class ChatReminderConfirmed extends ChatEventAction {
  const ChatReminderConfirmed(this.event);

  final ReminderEvent event;

  @override
  List<Object?> get props => <Object?>[event];
}
