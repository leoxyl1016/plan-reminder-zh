import '../entities/parsed_event.dart';

abstract class EventParserService {
  ParsedEvent parse(String message, {DateTime? reference});
}

class ParserException implements Exception {
  const ParserException(this.message);

  final String message;

  @override
  String toString() => message;
}
