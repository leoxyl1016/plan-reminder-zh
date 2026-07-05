import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/core/services/voice_input_service.dart';
import 'package:reminder_app/features/chat/domain/entities/chat_message.dart';
import 'package:reminder_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:reminder_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:reminder_app/features/parser/domain/entities/parsed_event.dart';
import 'package:reminder_app/features/parser/domain/services/event_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeChatRepository chatRepository;
  late ChatBloc bloc;

  setUp(() {
    chatRepository = _FakeChatRepository();
  });

  tearDown(() async {
    await bloc.close();
  });

  test('restores saved messages when a new bloc is created', () {
    final savedMessages = <ChatMessage>[
      ChatMessage(
        id: 'welcome',
        text: 'Type or speak your plan, and I will build the reminder offline.',
        author: ChatAuthor.assistant,
        createdAt: DateTime(2026, 3, 3, 11, 55),
      ),
      ChatMessage(
        id: 'user-1',
        text: 'meeting 6th of March 1:00 p.m.',
        author: ChatAuthor.user,
        createdAt: DateTime(2026, 3, 3, 11, 55),
      ),
      ChatMessage(
        id: 'assistant-1',
        text: 'Parsed "meeting 6th of March" for Mon, Mar 1, 2027 at 1:00 PM.',
        author: ChatAuthor.assistant,
        createdAt: DateTime(2026, 3, 3, 11, 55),
      ),
    ];
    chatRepository = _FakeChatRepository(initialMessages: savedMessages);

    bloc = ChatBloc(
      chatRepository: chatRepository,
      parserService: _FakeParserService(),
      voiceInputService: _FakeVoiceInputService(),
    );

    expect(bloc.state.messages, savedMessages);
    expect(bloc.state.status, ChatStatus.initial);
  });

  test(
    'persists the updated conversation after submitting a message',
    () async {
      bloc = ChatBloc(
        chatRepository: chatRepository,
        parserService: _FakeParserService(),
        voiceInputService: _FakeVoiceInputService(),
      );

      bloc.add(const ChatMessageSubmitted('Meeting tomorrow at 10 am'));
      await bloc.stream.firstWhere(
        (ChatState state) => state.status == ChatStatus.parsed,
      );
      await Future<void>.delayed(Duration.zero);

      expect(chatRepository.savedSnapshots, hasLength(2));

      final latestSnapshot = chatRepository.savedSnapshots.last;
      expect(latestSnapshot, hasLength(3));
      expect(latestSnapshot[0].author, ChatAuthor.assistant);
      expect(latestSnapshot[1].author, ChatAuthor.user);
      expect(latestSnapshot[1].text, 'Meeting tomorrow at 10 am');
      expect(latestSnapshot[2].author, ChatAuthor.assistant);
      expect(latestSnapshot[2].text, contains('Parsed "Meeting"'));
    },
  );
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({List<ChatMessage>? initialMessages})
    : _storedMessages = List<ChatMessage>.from(
        initialMessages ?? const <ChatMessage>[],
      );

  List<ChatMessage> _storedMessages;
  final List<List<ChatMessage>> savedSnapshots = <List<ChatMessage>>[];

  @override
  List<ChatMessage> loadMessages() {
    return List<ChatMessage>.unmodifiable(_storedMessages);
  }

  @override
  Future<void> saveMessages(List<ChatMessage> messages) {
    final snapshot = List<ChatMessage>.unmodifiable(messages);
    _storedMessages = snapshot;
    savedSnapshots.add(snapshot);
    return Future<void>.value();
  }
}

class _FakeParserService implements EventParserService {
  @override
  ParsedEvent parse(String message, {DateTime? reference}) {
    return ParsedEvent(
      title: 'Meeting',
      dateTime: DateTime(2026, 3, 4, 10),
      hasExplicitDate: true,
      hasExplicitTime: true,
      sourceText: message,
    );
  }
}

class _FakeVoiceInputService extends VoiceInputService {
  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function() onDone,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}
