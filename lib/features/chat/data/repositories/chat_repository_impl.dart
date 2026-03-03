import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._box);

  static const String _messagesKey = 'messages';

  final Box<String> _box;

  @override
  List<ChatMessage> loadMessages() {
    final rawMessages = _box.get(_messagesKey);
    if (rawMessages == null || rawMessages.isEmpty) {
      return const <ChatMessage>[];
    }

    try {
      final decoded = jsonDecode(rawMessages);
      if (decoded is! List<dynamic>) {
        return const <ChatMessage>[];
      }

      final messages = <ChatMessage>[];
      for (final dynamic item in decoded) {
        final message = _messageFromJson(item);
        if (message != null) {
          messages.add(message);
        }
      }

      return List<ChatMessage>.unmodifiable(messages);
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  @override
  Future<void> saveMessages(List<ChatMessage> messages) {
    final payload = jsonEncode(
      messages
          .map(
            (ChatMessage message) => <String, String>{
              'id': message.id,
              'text': message.text,
              'author': message.author.name,
              'createdAt': message.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    );

    return _box.put(_messagesKey, payload);
  }

  ChatMessage? _messageFromJson(dynamic json) {
    if (json is! Map<dynamic, dynamic>) {
      return null;
    }

    final id = json['id'];
    final text = json['text'];
    final authorName = json['author'];
    final createdAtValue = json['createdAt'];
    if (id is! String ||
        text is! String ||
        authorName is! String ||
        createdAtValue is! String) {
      return null;
    }

    final createdAt = DateTime.tryParse(createdAtValue);
    final author = _authorFromName(authorName);
    if (createdAt == null || author == null) {
      return null;
    }

    return ChatMessage(
      id: id,
      text: text,
      author: author,
      createdAt: createdAt,
    );
  }

  ChatAuthor? _authorFromName(String name) {
    for (final author in ChatAuthor.values) {
      if (author.name == name) {
        return author;
      }
    }

    return null;
  }
}
