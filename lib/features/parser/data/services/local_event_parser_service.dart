import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/entities/parsed_event.dart';
import '../../domain/services/event_parser_service.dart';

class LocalEventParserService implements EventParserService {
  LocalEventParserService();

  static const Map<String, int> _weekdayMap = <String, int>{
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  static const Map<String, int> _monthMap = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static final RegExp _nextWeekdayRegex = RegExp(
    r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  static final RegExp _weekdayRegex = RegExp(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  static final RegExp _dayMonthRegex = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s+'
    r'(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|'
    r'august|aug|september|sep|sept|october|oct|november|nov|december|dec)'
    r'(?:\s+(\d{4}))?\b',
    caseSensitive: false,
  );

  static final RegExp _monthDayRegex = RegExp(
    r'\b(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|'
    r'august|aug|september|sep|sept|october|oct|november|nov|december|dec)'
    r'\s+(\d{1,2})(?:st|nd|rd|th)?(?:,\s*(\d{4}))?\b',
    caseSensitive: false,
  );

  static final RegExp _numericDateRegex = RegExp(
    r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b',
  );

  static final RegExp _twelveHourRegex = RegExp(
    r'\b(\d{1,2})(?::([0-5]\d))?\s*'
    r'(a(?:\s*\.?\s*a)?\s*\.?\s*m\.?|p(?:\s*\.?\s*p)?\s*\.?\s*m\.?)\b',
    caseSensitive: false,
  );

  static final RegExp _twentyFourHourRegex = RegExp(
    r'\b([01]?\d|2[0-3]):([0-5]\d)\b',
    caseSensitive: false,
  );

  static final RegExp _atHourRegex = RegExp(
    r'\bat\s+(\d{1,2})(?::([0-5]\d))?\s*'
    r'(a(?:\s*\.?\s*a)?\s*\.?\s*m\.?|p(?:\s*\.?\s*p)?\s*\.?\s*m\.?)?\b',
    caseSensitive: false,
  );

  @override
  ParsedEvent parse(String message, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final normalized = _normalize(message);
    if (normalized.isEmpty) {
      throw const ParserException('Please enter a reminder message.');
    }

    final dateExtraction = _extractDate(normalized, now);
    final timeExtraction = _extractTime(normalized);
    final locationExtraction = _extractLocation(normalized);

    final baseDate = dateExtraction.date ?? now.dateOnly;
    final hasExplicitTime = timeExtraction.time != null;

    DateTime dateTime;
    if (hasExplicitTime) {
      final time = timeExtraction.time!;
      dateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );
    } else {
      final fallback = _defaultTime(now);
      dateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        fallback.hour,
        fallback.minute,
      );
    }

    final removablePhrases = <String>{
      ...dateExtraction.matchedPhrases,
      ...timeExtraction.matchedPhrases,
      if (locationExtraction != null) locationExtraction.rawPhrase,
    };

    final title = _extractTitle(
      original: message,
      removablePhrases: removablePhrases.toList(),
    );

    if (title.isEmpty) {
      throw const ParserException(
        'Could not infer an event title. Try: "Meeting tomorrow at 10 am".',
      );
    }

    return ParsedEvent(
      title: title,
      dateTime: dateTime,
      location: locationExtraction?.location,
      hasExplicitDate: dateExtraction.hasExplicitDate,
      hasExplicitTime: hasExplicitTime,
      sourceText: normalized,
    );
  }

  String _normalize(String message) {
    return message.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  _DateExtraction _extractDate(String input, DateTime now) {
    final lower = input.toLowerCase();
    final today = now.dateOnly;

    if (lower.contains('day after tomorrow')) {
      return _DateExtraction(
        date: today.add(const Duration(days: 2)),
        matchedPhrases: const <String>['day after tomorrow'],
        hasExplicitDate: true,
      );
    }

    final tomorrowMatch = RegExp(r'\btomorrow\b', caseSensitive: false)
        .firstMatch(input);
    if (tomorrowMatch != null) {
      return _DateExtraction(
        date: today.add(const Duration(days: 1)),
        matchedPhrases: <String>[tomorrowMatch.group(0)!],
        hasExplicitDate: true,
      );
    }

    final todayMatch =
        RegExp(r'\btoday\b', caseSensitive: false).firstMatch(input);
    if (todayMatch != null) {
      return _DateExtraction(
        date: today,
        matchedPhrases: <String>[todayMatch.group(0)!],
        hasExplicitDate: true,
      );
    }

    final nextWeekdayMatch = _nextWeekdayRegex.firstMatch(input);
    if (nextWeekdayMatch != null) {
      final dayName = nextWeekdayMatch.group(1)!.toLowerCase();
      final day = _weekdayMap[dayName];
      if (day != null) {
        return _DateExtraction(
          date: _resolveUpcomingWeekday(today, day),
          matchedPhrases: <String>[nextWeekdayMatch.group(0)!],
          hasExplicitDate: true,
        );
      }
    }

    final weekdayMatch = _weekdayRegex.firstMatch(input);
    if (weekdayMatch != null) {
      final dayName = weekdayMatch.group(1)!.toLowerCase();
      final day = _weekdayMap[dayName];
      if (day != null) {
        return _DateExtraction(
          date: _resolveUpcomingWeekday(today, day),
          matchedPhrases: <String>[weekdayMatch.group(0)!],
          hasExplicitDate: true,
        );
      }
    }

    final dayMonthMatch = _dayMonthRegex.firstMatch(input);
    if (dayMonthMatch != null) {
      final day = int.parse(dayMonthMatch.group(1)!);
      final month = _monthMap[dayMonthMatch.group(2)!.toLowerCase()];
      final yearText = dayMonthMatch.group(3);
      if (month != null) {
        final year = yearText == null ? now.year : int.parse(yearText);
        final rawDate = _safeDate(year, month, day);
        if (rawDate != null) {
          final adjustedDate = yearText == null && rawDate.isBefore(today)
              ? _safeDate(year + 1, month, day)
              : rawDate;
          if (adjustedDate != null) {
            return _DateExtraction(
              date: adjustedDate,
              matchedPhrases: <String>[dayMonthMatch.group(0)!],
              hasExplicitDate: true,
            );
          }
        }
      }
    }

    final monthDayMatch = _monthDayRegex.firstMatch(input);
    if (monthDayMatch != null) {
      final month = _monthMap[monthDayMatch.group(1)!.toLowerCase()];
      final day = int.parse(monthDayMatch.group(2)!);
      final yearText = monthDayMatch.group(3);
      if (month != null) {
        final year = yearText == null ? now.year : int.parse(yearText);
        final rawDate = _safeDate(year, month, day);
        if (rawDate != null) {
          final adjustedDate = yearText == null && rawDate.isBefore(today)
              ? _safeDate(year + 1, month, day)
              : rawDate;
          if (adjustedDate != null) {
            return _DateExtraction(
              date: adjustedDate,
              matchedPhrases: <String>[monthDayMatch.group(0)!],
              hasExplicitDate: true,
            );
          }
        }
      }
    }

    final numericDateMatch = _numericDateRegex.firstMatch(input);
    if (numericDateMatch != null) {
      final day = int.parse(numericDateMatch.group(1)!);
      final month = int.parse(numericDateMatch.group(2)!);
      final yearText = numericDateMatch.group(3);
      var year = yearText == null ? now.year : int.parse(yearText);
      if (year < 100) {
        year += 2000;
      }
      final rawDate = _safeDate(year, month, day);
      if (rawDate != null) {
        final adjustedDate = yearText == null && rawDate.isBefore(today)
            ? _safeDate(year + 1, month, day)
            : rawDate;
        if (adjustedDate != null) {
          return _DateExtraction(
            date: adjustedDate,
            matchedPhrases: <String>[numericDateMatch.group(0)!],
            hasExplicitDate: true,
          );
        }
      }
    }

    return const _DateExtraction();
  }

  _TimeExtraction _extractTime(String input) {
    final lower = input.toLowerCase();

    final noonMatch =
        RegExp(r'\bnoon\b', caseSensitive: false).firstMatch(input);
    if (noonMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 12, minute: 0),
        matchedPhrases: <String>[noonMatch.group(0)!],
      );
    }

    final midnightMatch =
        RegExp(r'\bmidnight\b', caseSensitive: false).firstMatch(input);
    if (midnightMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 0, minute: 0),
        matchedPhrases: <String>[midnightMatch.group(0)!],
      );
    }

    final twelveHourMatch = _twelveHourRegex.firstMatch(input);
    if (twelveHourMatch != null) {
      var hour = int.parse(twelveHourMatch.group(1)!);
      final minuteText = twelveHourMatch.group(2);
      final minute = minuteText == null ? 0 : int.parse(minuteText);
      final marker = _normalizeAmPm(twelveHourMatch.group(3)!);
      if (hour < 1 || hour > 12) {
        return const _TimeExtraction();
      }

      if (hour == 12) {
        hour = marker == 'am' ? 0 : 12;
      } else if (marker == 'pm') {
        hour += 12;
      }

      return _TimeExtraction(
        time: _ClockTime(hour: hour, minute: minute),
        matchedPhrases: <String>[twelveHourMatch.group(0)!],
      );
    }

    final twentyFourMatch = _twentyFourHourRegex.firstMatch(input);
    if (twentyFourMatch != null) {
      final hour = int.parse(twentyFourMatch.group(1)!);
      final minute = int.parse(twentyFourMatch.group(2)!);
      return _TimeExtraction(
        time: _ClockTime(hour: hour, minute: minute),
        matchedPhrases: <String>[twentyFourMatch.group(0)!],
      );
    }

    final atHourMatch = _atHourRegex.firstMatch(input);
    if (atHourMatch != null) {
      var hour = int.parse(atHourMatch.group(1)!);
      final minuteText = atHourMatch.group(2);
      final minute = minuteText == null ? 0 : int.parse(minuteText);
      final markerText = atHourMatch.group(3);
      if (hour > 23 || minute > 59) {
        return const _TimeExtraction();
      }

      if (markerText != null) {
        final marker = _normalizeAmPm(markerText);
        if (hour < 1 || hour > 12) {
          return const _TimeExtraction();
        }

        if (hour == 12) {
          hour = marker == 'am' ? 0 : 12;
        } else if (marker == 'pm') {
          hour += 12;
        }
      } else {
        final hasNightContext = RegExp(
          r'\b(tonight|evening|night)\b',
          caseSensitive: false,
        ).hasMatch(lower);
        final hasMorningContext = RegExp(
          r'\bmorning\b',
          caseSensitive: false,
        ).hasMatch(lower);

        if (hour <= 12) {
          if (hasNightContext || hour <= 7) {
            if (hour < 12) {
              hour += 12;
            }
          } else if (hasMorningContext && hour == 12) {
            hour = 0;
          }
        }
      }

      return _TimeExtraction(
        time: _ClockTime(hour: hour, minute: minute),
        matchedPhrases: <String>[atHourMatch.group(0)!],
      );
    }

    final tonightMatch =
        RegExp(r'\btonight\b', caseSensitive: false).firstMatch(input);
    if (tonightMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 20, minute: 0),
        matchedPhrases: <String>[tonightMatch.group(0)!],
      );
    }

    return const _TimeExtraction();
  }

  _LocationExtraction? _extractLocation(String input) {
    final locationMatch = RegExp(
      r'\b(?:at|in)\s+([A-Za-z][A-Za-z0-9\s,.-]{2,})$',
      caseSensitive: false,
    ).firstMatch(input);

    if (locationMatch == null) {
      return null;
    }

    final candidate = locationMatch.group(1)?.trim() ?? '';
    if (candidate.isEmpty || _containsDateOrTime(candidate)) {
      return null;
    }

    return _LocationExtraction(
      rawPhrase: locationMatch.group(0)!,
      location: candidate.replaceAll(RegExp(r'[,.!]+$'), ''),
    );
  }

  bool _containsDateOrTime(String text) {
    return RegExp(
      r'\b(today|tomorrow|next|monday|tuesday|wednesday|thursday|friday|'
      r'saturday|sunday|noon|midnight|tonight|am|pm)\b|\d{1,2}(:\d{2})?',
      caseSensitive: false,
    ).hasMatch(text);
  }

  String _extractTitle({
    required String original,
    required List<String> removablePhrases,
  }) {
    var title = ' $original ';
    final ordered = removablePhrases
        .where((String phrase) => phrase.trim().isNotEmpty)
        .toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));

    for (final phrase in ordered) {
      final pattern = _phraseRegex(phrase);
      title = title.replaceAll(pattern, ' ');
    }

    title = title.replaceAll(
      RegExp(r'\b(on|at)\b', caseSensitive: false),
      ' ',
    );
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceAll(RegExp(r'^[,\-.:;\s]+|[,\-.:;\s]+$'), '');
    return title;
  }

  RegExp _phraseRegex(String phrase) {
    final escaped = RegExp.escape(phrase.trim()).replaceAll(r'\ ', r'\s+');
    return RegExp('\\b$escaped\\b', caseSensitive: false);
  }

  DateTime _resolveUpcomingWeekday(DateTime fromDate, int targetWeekday) {
    var diff =
        (targetWeekday - fromDate.weekday + DateTime.daysPerWeek) % 7;
    if (diff == 0) {
      diff = 7;
    }
    return fromDate.add(Duration(days: diff));
  }

  _ClockTime _defaultTime(DateTime now) {
    final nextHour = now.add(const Duration(hours: 1));
    return _ClockTime(hour: nextHour.hour, minute: 0);
  }

  String _normalizeAmPm(String marker) {
    final lettersOnly = marker.toLowerCase().replaceAll(RegExp(r'[^ap]'), '');
    if (lettersOnly.isEmpty) {
      return 'am';
    }
    return lettersOnly.endsWith('p') ? 'pm' : 'am';
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}

class _DateExtraction {
  const _DateExtraction({
    this.date,
    this.matchedPhrases = const <String>[],
    this.hasExplicitDate = false,
  });

  final DateTime? date;
  final List<String> matchedPhrases;
  final bool hasExplicitDate;
}

class _TimeExtraction {
  const _TimeExtraction({
    this.time,
    this.matchedPhrases = const <String>[],
  });

  final _ClockTime? time;
  final List<String> matchedPhrases;
}

class _LocationExtraction {
  const _LocationExtraction({
    required this.rawPhrase,
    required this.location,
  });

  final String rawPhrase;
  final String location;
}

class _ClockTime {
  const _ClockTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;
}
