import 'package:flutter_test/flutter_test.dart';

import 'package:reminder_app/features/parser/data/services/local_event_parser_service.dart';

void main() {
  late LocalEventParserService parser;
  final reference = DateTime(2026, 2, 15, 9, 0); // Sunday

  setUp(() {
    parser = LocalEventParserService();
  });

  test('parses "Meeting tomorrow at 10 am"', () {
    final result = parser.parse(
      'Meeting tomorrow at 10 am',
      reference: reference,
    );

    expect(result.title, 'Meeting');
    expect(result.dateTime, DateTime(2026, 2, 16, 10, 0));
  });

  test('parses "Gym at 6"', () {
    final result = parser.parse('Gym at 6', reference: reference);

    expect(result.title, 'Gym');
    expect(result.dateTime, DateTime(2026, 2, 15, 18, 0));
  });

  test('parses "Dentist appointment next Monday 5 pm"', () {
    final result = parser.parse(
      'Dentist appointment next Monday 5 pm',
      reference: reference,
    );

    expect(result.title, 'Dentist appointment');
    expect(result.dateTime, DateTime(2026, 2, 16, 17, 0));
  });

  test('parses "Call mom tonight"', () {
    final result = parser.parse('Call mom tonight', reference: reference);

    expect(result.title, 'Call mom');
    expect(result.dateTime, DateTime(2026, 2, 15, 20, 0));
  });

  test('parses "Lunch with Alex on June 10 at 1 pm"', () {
    final result = parser.parse(
      'Lunch with Alex on June 10 at 1 pm',
      reference: reference,
    );

    expect(result.title, 'Lunch with Alex');
    expect(result.dateTime, DateTime(2026, 6, 10, 13, 0));
  });

  test('parses "Interview 17:30"', () {
    final result = parser.parse('Interview 17:30', reference: reference);

    expect(result.title, 'Interview');
    expect(result.dateTime, DateTime(2026, 2, 15, 17, 30));
  });

  test('parses "Party Saturday" with missing explicit time', () {
    final result = parser.parse('Party Saturday', reference: reference);

    expect(result.title, 'Party');
    expect(result.dateTime.year, 2026);
    expect(result.dateTime.month, 2);
    expect(result.dateTime.day, 21);
    expect(result.hasExplicitTime, isFalse);
  });

  test('keeps today when date is missing and time already passed', () {
    final afternoonReference = DateTime(2026, 2, 15, 14, 35);
    final result = parser.parse(
      'I have a meeting at 10 am',
      reference: afternoonReference,
    );

    expect(result.dateTime, DateTime(2026, 2, 15, 10, 0));
    expect(result.hasExplicitDate, isFalse);
  });

  test('parses dotted meridiem format', () {
    final result = parser.parse(
      'I have a class at 4 p.m',
      reference: reference,
    );

    expect(result.title, 'I have a class');
    expect(result.dateTime, DateTime(2026, 2, 15, 16, 0));
  });

  test('parses malformed pm token like "3p.pm."', () {
    final result = parser.parse(
      'interview at 3p.pm.',
      reference: reference,
    );

    expect(result.title, 'interview');
    expect(result.dateTime, DateTime(2026, 2, 15, 15, 0));
  });
}
