import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/voice_input_service.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../parser/domain/entities/parsed_event.dart';
import '../../../parser/domain/services/event_parser_service.dart';
import '../../../reminder/domain/entities/reminder_event.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEventAction, ChatState> {
  ChatBloc({
    required ChatRepository chatRepository,
    required EventParserService parserService,
    required VoiceInputService voiceInputService,
    Uuid? uuid,
  }) : _chatRepository = chatRepository,
       _parserService = parserService,
       _voiceInputService = voiceInputService,
       _uuid = uuid ?? const Uuid(),
       super(ChatState.fromMessages(chatRepository.loadMessages())) {
    on<ChatDraftUpdated>(_onDraftUpdated);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
    on<ChatVoiceInputStarted>(_onVoiceInputStarted);
    on<ChatVoiceInputStopped>(_onVoiceInputStopped);
    on<ChatVoiceTranscriptUpdated>(_onVoiceTranscriptUpdated);
    on<ChatParsedEventDismissed>(_onParsedEventDismissed);
    on<ChatReminderConfirmed>(_onReminderConfirmed);
  }

  final ChatRepository _chatRepository;
  final EventParserService _parserService;
  final VoiceInputService _voiceInputService;
  final Uuid _uuid;

  @override
  void onChange(Change<ChatState> change) {
    super.onChange(change);

    if (!listEquals(change.currentState.messages, change.nextState.messages)) {
      unawaited(_persistMessages(change.nextState.messages));
    }
  }

  void _onDraftUpdated(ChatDraftUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(draftText: event.text));
  }

  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message.trim();
    if (message.isEmpty) {
      return;
    }

    final userMessage = _buildMessage(message, ChatAuthor.user);
    final loadingTrail = <ChatMessage>[...state.messages, userMessage];

    emit(
      state.copyWith(
        status: ChatStatus.loading,
        messages: loadingTrail,
        errorMessage: null,
        parsedEvent: null,
        draftText: message,
      ),
    );

    try {
      final parsedEvent = _parserService.parse(message);
      final previewMessage = _buildMessage(
        'Parsed "${parsedEvent.title}" for ${parsedEvent.dateTime.toDateTimeLabel}.',
        ChatAuthor.assistant,
      );

      emit(
        state.copyWith(
          status: ChatStatus.parsed,
          messages: <ChatMessage>[...loadingTrail, previewMessage],
          parsedEvent: parsedEvent,
          errorMessage: null,
        ),
      );
    } catch (error) {
      final errorMessage = error is ParserException
          ? error.message
          : '解析失败: ${error.toString().length > 50 ? error.toString().substring(0, 50) + "..." : error}';
      final systemMessage = _buildMessage(errorMessage, ChatAuthor.system);

      emit(
        state.copyWith(
          status: ChatStatus.error,
          messages: <ChatMessage>[...loadingTrail, systemMessage],
          errorMessage: errorMessage,
        ),
      );
    }
  }

  Future<void> _onVoiceInputStarted(
    ChatVoiceInputStarted event,
    Emitter<ChatState> emit,
  ) async {
    if (state.status == ChatStatus.listening) {
      return;
    }

    emit(state.copyWith(status: ChatStatus.listening, errorMessage: null));

    try {
      await _voiceInputService.startListening(
        onResult: (String transcript, bool isFinal) {
          add(
            ChatVoiceTranscriptUpdated(
              transcript: transcript,
              isFinal: isFinal,
            ),
          );
        },
        onDone: () => add(const ChatVoiceInputStopped()),
      );
    } catch (error) {
      final message = error.toString();
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: message,
          messages: <ChatMessage>[
            ...state.messages,
            _buildMessage(message, ChatAuthor.system),
          ],
        ),
      );
    }
  }

  Future<void> _onVoiceInputStopped(
    ChatVoiceInputStopped event,
    Emitter<ChatState> emit,
  ) async {
    await _voiceInputService.stopListening();

    if (state.status == ChatStatus.listening) {
      emit(
        state.copyWith(
          status: state.parsedEvent == null
              ? ChatStatus.initial
              : ChatStatus.parsed,
        ),
      );
    }
  }

  Future<void> _onVoiceTranscriptUpdated(
    ChatVoiceTranscriptUpdated event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(draftText: event.transcript));

    if (event.isFinal) {
      final transcript = event.transcript.trim();
      if (transcript.isNotEmpty) {
        add(ChatMessageSubmitted(transcript));
      }
    }
  }

  void _onParsedEventDismissed(
    ChatParsedEventDismissed event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        status: ChatStatus.initial,
        parsedEvent: null,
        errorMessage: null,
      ),
    );
  }

  void _onReminderConfirmed(ChatReminderConfirmed _, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        status: ChatStatus.initial,
        parsedEvent: null,
        draftText: '',
        errorMessage: null,
      ),
    );
  }

  ChatMessage _buildMessage(String text, ChatAuthor author) {
    return ChatMessage(
      id: _uuid.v4(),
      text: text,
      author: author,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _persistMessages(List<ChatMessage> messages) async {
    try {
      await _chatRepository.saveMessages(messages);
    } catch (_) {}
  }
}
