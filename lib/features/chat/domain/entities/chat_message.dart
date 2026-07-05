import 'package:equatable/equatable.dart';

enum ChatAuthor {
  user,
  assistant,
  system,
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String text;
  final ChatAuthor author;
  final DateTime createdAt;

  bool get isUser => author == ChatAuthor.user;

  @override
  List<Object?> get props => <Object?>[id, text, author, createdAt];
}
