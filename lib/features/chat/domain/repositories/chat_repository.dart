import '../entities/chat_message.dart';

abstract class ChatRepository {
  List<ChatMessage> loadMessages();
  Future<void> saveMessages(List<ChatMessage> messages);
}
