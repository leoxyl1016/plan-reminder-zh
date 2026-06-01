import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/entities/parsed_event.dart';
import '../../domain/services/event_parser_service.dart';

class LocalEventParserService implements EventParserService {
  LocalEventParserService();

  // ── English weekday / month maps (unchanged) ──

  static const Map<String, int> _weekdayMapEn = <String, int>{
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  static const Map<String, int> _monthMapEn = <String, int>{
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  // ── Chinese mappings ──

  /// 周一 → DateTime.monday, etc.
  static const Map<String, int> _weekdayMapZh = <String, int>{
    '周一': DateTime.monday, '星期一': DateTime.monday,
    '周二': DateTime.tuesday, '星期二': DateTime.tuesday,
    '周三': DateTime.wednesday, '星期三': DateTime.wednesday,
    '周四': DateTime.thursday, '星期四': DateTime.thursday,
    '周五': DateTime.friday, '星期五': DateTime.friday,
    '周六': DateTime.saturday, '星期六': DateTime.saturday,
    '周日': DateTime.sunday, '星期天': DateTime.sunday, '周天': DateTime.sunday,
  };

  /// Prefixes for "next/this/last" week
  static const Map<String, int> _weekOffsetZh = <String, int>{
    '下': 1, '下个': 1,
    '这': 0, '这个': 0, '本': 0,
    '上': -1, '上个': -1,
  };

  // ── English regexes (unchanged) ──

  static final RegExp _nextWeekdayRegexEn = RegExp(
    r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  static final RegExp _weekdayRegexEn = RegExp(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  static final RegExp _dayMonthRegexEn = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s+'
    r'(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|'
    r'august|aug|september|sep|sept|october|oct|november|nov|december|dec)'
    r'(?:\s+(\d{4}))?\b',
    caseSensitive: false,
  );

  static final RegExp _monthDayRegexEn = RegExp(
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

  // ── Chinese date regexes ──

  /// 下周三 / 这周五 / 上周一  etc.
  static final RegExp _weekdayZhRegex = RegExp(
    r'(下|下个|这|这个|本|上|上个)?\s*(周[一二三四五六日天]|星期[一二三四五六日天])',
  );

  /// X年X月X日 / X年X月X号 / X月X日 / X月X号
  static final RegExp _dateZhRegex = RegExp(
    r'(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]|'
    r'(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]',
  );

  /// 中文数字日期：二〇二六年六月一日 / 二零二六年六月一日
  static final RegExp _dateZhCnRegex = RegExp(
    r'(二[〇零一二三四五六七八九]{3})\s*年\s*'
    r'([一二三四五六七八九十]{1,2})\s*月\s*'
    r'([一二三四五六七八九十廿卅]{1,3})\s*[日号]|'
    r'([一二三四五六七八九十]{1,2})\s*月\s*'
    r'([一二三四五六七八九十廿卅]{1,3})\s*[日号]',
  );

  // ── Chinese time regexes ──

  /// 上午10点 / 下午3点半 / 晚上7点20分 / 中午12点 / 凌晨2点
  static final RegExp _timeZhRegex = RegExp(
    r'(上午|下午|晚上|中午|凌晨|早晨|傍晚|夜里)?\s*'
    r'(\d{1,2})\s*[点時]\s*'
    r'(?:(\d{1,2})\s*分)?'
    r'(半)?',
  );

  /// 中文数字时间：三点半 / 十点二十分
  static final RegExp _timeZhCnRegex = RegExp(
    r'(上午|下午|晚上|中午|凌晨|早晨|傍晚|夜里)?\s*'
    r'([一二三四五六七八九十]{1,2})\s*[点時]\s*'
    r'(?:([一二三四五六七八九十]{1,2})\s*分)?'
    r'(半)?',
  );

  /// 数字+时/小时 如 "下午3时" "14时"
  static final RegExp _timeZh24Regex = RegExp(
    r'(\d{1,2})\s*[时時]'
    r'(?:(\d{1,2})\s*分)?',
  );

  /// Relative time: 半小时后 / 1小时后 / 15分钟后
  static final RegExp _relativeTimeZhRegex = RegExp(
    r'(\d+|半)\s*(?:个?\s*)?'
    r'(小时|分钟|分钟|分|钟头)\s*[后内以]',
  );

  // ── Chinese location regex ──

  /// 在XXX（教室/楼/会议室/办公室/大厅/广场/餐厅/图书馆/实验室/中心/厅/堂/馆/室/所/处/部/店/院/园）
  /// After the location suffix, only allows digits, letters, and location modifiers (层/栋/号/etc).
  static final RegExp _locationZhRegex = RegExp(
    r'(?:在|于|地点[：:]?\s*|位置[：:]?\s*)'
    r'([\u4e00-\u9fff_a-zA-Z0-9（）()\-.·]{2,}'
    r'(?:教室|教学楼|实验楼|办公楼|会议室|办公室|大厅|广场|餐厅|食堂|图书馆|体育馆|'
    r'实验室|中心|报告厅|礼堂|场馆|房间|大楼|大厦|公寓|宿舍|校区|学院|'
    r'银行|医院|酒店|饭店|商场|超市|公园|地铁站|车站|机场|'
    r'厅|堂|馆|室|所|处|部|店|院|园|楼|层)'
    r'[\dA-Za-z\-·层栋号座楼单元\d]{0,6})',
  );

  /// Simpler fallback: 在 XXXX （中文名詞後面）
  static final RegExp _locationZhSimpleRegex = RegExp(
    r'(?:在|于)\s*([\u4e00-\u9fff_a-zA-Z0-9]{2,20})',
  );

  // ── Chinese relative date keywords ──

  static final Map<String, int> _relativeDayZh = <String, int>{
    '今天': 0,
    '今日': 0,
    '明天': 1,
    '明日': 1,
    '后天': 2,
    '後天': 2,
    '大后天': 3,
    '大後天': 3,
    '昨天': -1,
    '昨日': -1,
    '前天': -2,
  };

  // ── Chinese number conversion ──

  static const Map<String, int> _cnDigitMap = <String, int>{
    '零': 0, '〇': 0,
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
  };

  /// Convert Chinese numeral string to int. Handles 二十, 十五, 三十, etc.
  static int? _cnNumToInt(String s) {
    if (s.isEmpty) return null;
    // Try arabic first
    final arabic = int.tryParse(s);
    if (arabic != null) return arabic;

    if (s == '十') return 10;
    if (s == '廿' || s == '卅') {
      // 廿=20, 卅=30
      if (s == '廿') return 20;
      if (s == '卅') return 30;
    }

    // Pattern: X十Y (e.g. 二十五=25, 十二=12)
    final tensMatch = RegExp(r'^([一二三四五六七八九])?十([一二三四五六七八九])?$').firstMatch(s);
    if (tensMatch != null) {
      final tens = tensMatch.group(1);
      final ones = tensMatch.group(2);
      var result = 0;
      if (tens != null && tens.isNotEmpty) {
        result += (_cnDigitMap[tens] ?? 0) * 10;
      } else {
        result += 10; // 十X = 1X
      }
      if (ones != null && ones.isNotEmpty) {
        result += _cnDigitMap[ones] ?? 0;
      }
      return result;
    }

    // Single digit
    return _cnDigitMap[s];
  }

  // ─────────────────────────────────────────────────────────────
  // Main parse() entry point
  // ─────────────────────────────────────────────────────────────

  @override
  ParsedEvent parse(String message, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final normalized = _normalize(message);
    if (normalized.isEmpty) {
      throw const ParserException('请输入提醒内容。');
    }

    // Detect if input is primarily Chinese
    final isChinese = _isChineseInput(normalized);

    final dateExtraction = _extractDate(normalized, now, isChinese: isChinese);
    final timeExtraction = _extractTime(normalized, now, isChinese: isChinese);
    final locationExtraction = _extractLocation(normalized, isChinese: isChinese);

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
      isChinese: isChinese,
    );

    if (title.isEmpty) {
      throw const ParserException(
        isChinese
            ? '无法识别事件标题，请尝试："明天下午3点开会" 或 "Meeting tomorrow at 3pm"。'
            : 'Could not infer an event title. Try: "Meeting tomorrow at 10 am" or "明天下午3点开会"。',
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

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _normalize(String message) {
    // Normalize full-width chars to half-width for numbers but keep Chinese
    return message
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('：', ':')
        .replaceAll('，', ',')
        .replaceAll('。', '.')
        .trim();
  }

  /// Detect if input is primarily Chinese (contains CJK characters)
  bool _isChineseInput(String text) {
    final cjkCount = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').allMatches(text).length;
    return cjkCount >= 2 || text.codeUnits.any((c) => c >= 0x4e00 && c <= 0x9fff);
  }

  // ─────────────────────────────────────────────────────────────
  // Date extraction
  // ─────────────────────────────────────────────────────────────

  _DateExtraction _extractDate(String input, DateTime now, {bool isChinese = false}) {
    final lower = input.toLowerCase();
    final today = now.dateOnly;

    // ── Chinese relative days (sorted longest first to avoid partial matches) ──
    if (isChinese) {
      // Sort by key length descending so "大后天" matches before "后天"
      final sortedKeys = _relativeDayZh.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final key in sortedKeys) {
        if (input.contains(key)) {
          final offset = _relativeDayZh[key]!;
          return _DateExtraction(
            date: today.add(Duration(days: offset)),
            matchedPhrases: <String>[key],
            hasExplicitDate: true,
          );
        }
      }
    }

    // ── English relative days ──
    if (lower.contains('day after tomorrow')) {
      return _DateExtraction(
        date: today.add(const Duration(days: 2)),
        matchedPhrases: const <String>['day after tomorrow'],
        hasExplicitDate: true,
      );
    }

    final tomorrowMatch = RegExp(r'\btomorrow\b', caseSensitive: false).firstMatch(input);
    if (tomorrowMatch != null) {
      return _DateExtraction(
        date: today.add(const Duration(days: 1)),
        matchedPhrases: <String>[tomorrowMatch.group(0)!],
        hasExplicitDate: true,
      );
    }

    final todayMatch = RegExp(r'\btoday\b', caseSensitive: false).firstMatch(input);
    if (todayMatch != null) {
      return _DateExtraction(
        date: today,
        matchedPhrases: <String>[todayMatch.group(0)!],
        hasExplicitDate: true,
      );
    }

    // ── Chinese weekday (下周三 / 这周五 / 上周一) ──
    if (isChinese) {
      final weekdayZhMatch = _weekdayZhRegex.firstMatch(input);
      if (weekdayZhMatch != null) {
        final prefix = weekdayZhMatch.group(1) ?? '';
        final dayWord = weekdayZhMatch.group(2) ?? '';
        final weekday = _weekdayMapZh[dayWord];
        if (weekday != null) {
          final weekOffset = _weekOffsetZh[prefix] ?? 0;
          final target = _resolveOffsetWeekday(today, weekday, weekOffset);
          return _DateExtraction(
            date: target,
            matchedPhrases: <String>[weekdayZhMatch.group(0)!],
            hasExplicitDate: true,
          );
        }
      }
    }

    // ── English next weekday ──
    final nextWeekdayMatch = _nextWeekdayRegexEn.firstMatch(input);
    if (nextWeekdayMatch != null) {
      final dayName = nextWeekdayMatch.group(1)!.toLowerCase();
      final day = _weekdayMapEn[dayName];
      if (day != null) {
        return _DateExtraction(
          date: _resolveUpcomingWeekday(today, day),
          matchedPhrases: <String>[nextWeekdayMatch.group(0)!],
          hasExplicitDate: true,
        );
      }
    }

    // ── English plain weekday ──
    final weekdayMatch = _weekdayRegexEn.firstMatch(input);
    if (weekdayMatch != null) {
      final dayName = weekdayMatch.group(1)!.toLowerCase();
      final day = _weekdayMapEn[dayName];
      if (day != null) {
        return _DateExtraction(
          date: _resolveUpcomingWeekday(today, day),
          matchedPhrases: <String>[weekdayMatch.group(0)!],
          hasExplicitDate: true,
        );
      }
    }

    // ── Chinese numeric date: X年X月X日 / X月X日 ──
    if (isChinese) {
      final dateZhMatch = _dateZhRegex.firstMatch(input);
      if (dateZhMatch != null) {
        if (dateZhMatch.group(1) != null) {
          // X年X月X日
          final year = int.parse(dateZhMatch.group(1)!);
          final month = int.parse(dateZhMatch.group(2)!);
          final day = int.parse(dateZhMatch.group(3)!);
          final rawDate = _safeDate(year, month, day);
          if (rawDate != null) {
            return _DateExtraction(
              date: rawDate,
              matchedPhrases: <String>[dateZhMatch.group(0)!],
              hasExplicitDate: true,
            );
          }
        } else if (dateZhMatch.group(4) != null) {
          // X月X日 (no year)
          final month = int.parse(dateZhMatch.group(4)!);
          final day = int.parse(dateZhMatch.group(5)!);
          final rawDate = _safeDate(now.year, month, day);
          if (rawDate != null) {
            final adjusted = rawDate.isBefore(today)
                ? _safeDate(now.year + 1, month, day)
                : rawDate;
            if (adjusted != null) {
              return _DateExtraction(
                date: adjusted,
                matchedPhrases: <String>[dateZhMatch.group(0)!],
                hasExplicitDate: true,
              );
            }
          }
        }
      }

      // ── Chinese character date: 二〇二六年六月一日 ──
      final dateZhCnMatch = _dateZhCnRegex.firstMatch(input);
      if (dateZhCnMatch != null) {
        if (dateZhCnMatch.group(1) != null) {
          final yearStr = dateZhCnMatch.group(1)!;
          final monthStr = dateZhCnMatch.group(2)!;
          final dayStr = dateZhCnMatch.group(3)!;
          final year = _cnNumToInt(yearStr);
          final month = _cnNumToInt(monthStr);
          final day = _cnNumToInt(dayStr);
          if (year != null && month != null && day != null) {
            final rawDate = _safeDate(year, month, day);
            if (rawDate != null) {
              return _DateExtraction(
                date: rawDate,
                matchedPhrases: <String>[dateZhCnMatch.group(0)!],
                hasExplicitDate: true,
              );
            }
          }
        } else if (dateZhCnMatch.group(4) != null) {
          final monthStr = dateZhCnMatch.group(4)!;
          final dayStr = dateZhCnMatch.group(5)!;
          final month = _cnNumToInt(monthStr);
          final day = _cnNumToInt(dayStr);
          if (month != null && day != null) {
            final rawDate = _safeDate(now.year, month, day);
            if (rawDate != null) {
              final adjusted = rawDate.isBefore(today)
                  ? _safeDate(now.year + 1, month, day)
                  : rawDate;
              if (adjusted != null) {
                return _DateExtraction(
                  date: adjusted,
                  matchedPhrases: <String>[dateZhCnMatch.group(0)!],
                  hasExplicitDate: true,
                );
              }
            }
          }
        }
      }
    }

    // ── English day-month ──
    final dayMonthMatch = _dayMonthRegexEn.firstMatch(input);
    if (dayMonthMatch != null) {
      final day = int.parse(dayMonthMatch.group(1)!);
      final month = _monthMapEn[dayMonthMatch.group(2)!.toLowerCase()];
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

    // ── English month-day ──
    final monthDayMatch = _monthDayRegexEn.firstMatch(input);
    if (monthDayMatch != null) {
      final month = _monthMapEn[monthDayMatch.group(1)!.toLowerCase()];
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

    // ── Numeric: M/D ──
    final numericDateMatch = _numericDateRegex.firstMatch(input);
    if (numericDateMatch != null) {
      final month = int.parse(numericDateMatch.group(1)!);
      final day = int.parse(numericDateMatch.group(2)!);
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

  // ─────────────────────────────────────────────────────────────
  // Time extraction
  // ─────────────────────────────────────────────────────────────

  _TimeExtraction _extractTime(String input, DateTime now, {bool isChinese = false}) {
    final lower = input.toLowerCase();

    // ── Chinese time ──
    if (isChinese) {
      final timeZhMatch = _timeZhRegex.firstMatch(input);
      if (timeZhMatch != null) {
        final period = timeZhMatch.group(1) ?? ''; // 上午/下午/晚上/中午
        final hourRaw = int.tryParse(timeZhMatch.group(2) ?? '');
        final minuteRaw = timeZhMatch.group(3); // optional 分
        final isHalf = timeZhMatch.group(4) != null; // 半

        if (hourRaw != null && hourRaw >= 0 && hourRaw <= 23) {
          var hour = hourRaw;
          final minute = isHalf ? 30 : (minuteRaw != null ? int.tryParse(minuteRaw) ?? 0 : 0);

          // Adjust hour by period
          if (period.contains('下午') || period.contains('傍晚') || period.contains('晚上') || period.contains('夜里')) {
            if (hour < 12) hour += 12;
            if (hour == 12 && period.contains('下午')) hour = 12; // 下午12点 = noon
            if (hour == 12 && (period.contains('晚上') || period.contains('夜里'))) hour = 0; // 晚上12点 = midnight
          } else if (period.contains('中午')) {
            hour = hour == 12 ? 12 : hour + 12; // 中午1点 = 13:00
            if (hour >= 1 && hour <= 11) hour = 12; // 中午 = 12:00 approximation
          } else if (period.contains('凌晨') || period.contains('早晨')) {
            // 凌晨 keeps hours as-is (0-11), 凌晨12点 = 0
            if (hour == 12) hour = 0;
          }
          // 上午: keep as-is (0-11), 上午12点 = 0

          return _TimeExtraction(
            time: _ClockTime(hour: hour % 24, minute: minute),
            matchedPhrases: <String>[timeZhMatch.group(0)!],
          );
        }
      }

      // ── Chinese character time: 三点半 / 十点 ──
      final timeZhCnMatch = _timeZhCnRegex.firstMatch(input);
      if (timeZhCnMatch != null) {
        final period = timeZhCnMatch.group(1) ?? '';
        final hourStr = timeZhCnMatch.group(2) ?? '';
        final minuteStr = timeZhCnMatch.group(3);
        final isHalf = timeZhCnMatch.group(4) != null;

        final hour = _cnNumToInt(hourStr);
        if (hour != null && hour >= 0 && hour <= 23) {
          final minute = isHalf ? 30 : (minuteStr != null ? (_cnNumToInt(minuteStr) ?? 0) : 0);

          var adjustedHour = hour;
          if (period.contains('下午') || period.contains('傍晚') || period.contains('晚上') || period.contains('夜里')) {
            if (adjustedHour < 12) adjustedHour += 12;
            if (adjustedHour == 12 && period.contains('下午')) adjustedHour = 12;
            if (adjustedHour == 12 && (period.contains('晚上') || period.contains('夜里'))) adjustedHour = 0;
          } else if (period.contains('中午')) {
            if (adjustedHour >= 1 && adjustedHour <= 11) adjustedHour = 12;
          } else if (period.contains('凌晨') || period.contains('早晨')) {
            if (adjustedHour == 12) adjustedHour = 0;
          }

          return _TimeExtraction(
            time: _ClockTime(hour: adjustedHour % 24, minute: minute),
            matchedPhrases: <String>[timeZhCnMatch.group(0)!],
          );
        }
      }

      // ── Chinese 24h: 14时 / 14时30分 ──
      final timeZh24Match = _timeZh24Regex.firstMatch(input);
      if (timeZh24Match != null && !input.contains(RegExp(r'[上下中午凌晨早傍]'))) {
        final hour = int.tryParse(timeZh24Match.group(1) ?? '');
        final minuteRaw = timeZh24Match.group(2);
        if (hour != null && hour >= 0 && hour <= 23) {
          final minute = minuteRaw != null ? int.tryParse(minuteRaw) ?? 0 : 0;
          return _TimeExtraction(
            time: _ClockTime(hour: hour, minute: minute),
            matchedPhrases: <String>[timeZh24Match.group(0)!],
          );
        }
      }

      // ── Chinese relative time: 半小时后 / 1小时后 ──
      final relativeTimeMatch = _relativeTimeZhRegex.firstMatch(input);
      if (relativeTimeMatch != null) {
        final amountStr = relativeTimeMatch.group(1)!;
        final unit = relativeTimeMatch.group(2)!;
        var amount = amountStr == '半' ? 0.5 : (int.tryParse(amountStr) ?? 1).toDouble();

        if (unit.contains('分')) {
          // minutes
          final future = now.add(Duration(minutes: amount.round()));
          return _TimeExtraction(
            time: _ClockTime(hour: future.hour, minute: future.minute),
            matchedPhrases: <String>[relativeTimeMatch.group(0)!],
          );
        } else {
          // hours
          final future = now.add(Duration(minutes: (amount * 60).round()));
          return _TimeExtraction(
            time: _ClockTime(hour: future.hour, minute: future.minute),
            matchedPhrases: <String>[relativeTimeMatch.group(0)!],
          );
        }
      }
    }

    // ── English noon / midnight ──
    final noonMatch = RegExp(r'\bnoon\b', caseSensitive: false).firstMatch(input);
    if (noonMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 12, minute: 0),
        matchedPhrases: <String>[noonMatch.group(0)!],
      );
    }

    final midnightMatch = RegExp(r'\bmidnight\b', caseSensitive: false).firstMatch(input);
    if (midnightMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 0, minute: 0),
        matchedPhrases: <String>[midnightMatch.group(0)!],
      );
    }

    // ── English 12h ──
    final twelveHourMatch = _twelveHourRegex.firstMatch(input);
    if (twelveHourMatch != null) {
      var hour = int.parse(twelveHourMatch.group(1)!);
      final minuteText = twelveHourMatch.group(2);
      final minute = minuteText == null ? 0 : int.parse(minuteText);
      final marker = _normalizeAmPm(twelveHourMatch.group(3)!);
      if (hour < 1 || hour > 12) return const _TimeExtraction();

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

    // ── English 24h ──
    final twentyFourMatch = _twentyFourHourRegex.firstMatch(input);
    if (twentyFourMatch != null) {
      final hour = int.parse(twentyFourMatch.group(1)!);
      final minute = int.parse(twentyFourMatch.group(2)!);
      return _TimeExtraction(
        time: _ClockTime(hour: hour, minute: minute),
        matchedPhrases: <String>[twentyFourMatch.group(0)!],
      );
    }

    // ── English "at X" ──
    final atHourMatch = _atHourRegex.firstMatch(input);
    if (atHourMatch != null) {
      var hour = int.parse(atHourMatch.group(1)!);
      final minuteText = atHourMatch.group(2);
      final minute = minuteText == null ? 0 : int.parse(minuteText);
      final markerText = atHourMatch.group(3);
      if (hour > 23 || minute > 59) return const _TimeExtraction();

      if (markerText != null) {
        final marker = _normalizeAmPm(markerText);
        if (hour < 1 || hour > 12) return const _TimeExtraction();
        if (hour == 12) {
          hour = marker == 'am' ? 0 : 12;
        } else if (marker == 'pm') {
          hour += 12;
        }
      } else {
        final hasNightContext = RegExp(r'\b(tonight|evening|night)\b', caseSensitive: false).hasMatch(lower);
        final hasMorningContext = RegExp(r'\bmorning\b', caseSensitive: false).hasMatch(lower);
        if (hour <= 12) {
          if (hasNightContext || hour <= 7) {
            if (hour < 12) hour += 12;
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

    final tonightMatch = RegExp(r'\btonight\b', caseSensitive: false).firstMatch(input);
    if (tonightMatch != null) {
      return _TimeExtraction(
        time: const _ClockTime(hour: 20, minute: 0),
        matchedPhrases: <String>[tonightMatch.group(0)!],
      );
    }

    return const _TimeExtraction();
  }

  // ─────────────────────────────────────────────────────────────
  // Location extraction
  // ─────────────────────────────────────────────────────────────

  _LocationExtraction? _extractLocation(String input, {bool isChinese = false}) {
    if (isChinese) {
      // Try structured location first
      final locZhMatch = _locationZhRegex.firstMatch(input);
      if (locZhMatch != null) {
        final candidate = locZhMatch.group(1)?.trim() ?? '';
        if (candidate.isNotEmpty && !_containsDateOrTimeZh(candidate)) {
          return _LocationExtraction(
            rawPhrase: locZhMatch.group(0)!,
            location: candidate,
          );
        }
      }
      // Fallback: simple "在XXX"
      final locSimpleMatch = _locationZhSimpleRegex.firstMatch(input);
      if (locSimpleMatch != null) {
        final candidate = locSimpleMatch.group(1)?.trim() ?? '';
        if (candidate.isNotEmpty &&
            !_containsDateOrTimeZh(candidate) &&
            !_isTimeOnlyZh(candidate)) {
          return _LocationExtraction(
            rawPhrase: locSimpleMatch.group(0)!,
            location: candidate,
          );
        }
      }
    }

    // English location
    final locationMatch = RegExp(
      r'\b(?:at|in)\s+([A-Za-z][A-Za-z0-9\s,.-]{2,})$',
      caseSensitive: false,
    ).firstMatch(input);

    if (locationMatch == null) return null;

    final candidate = locationMatch.group(1)?.trim() ?? '';
    if (candidate.isEmpty || _containsDateOrTime(candidate)) return null;

    return _LocationExtraction(
      rawPhrase: locationMatch.group(0)!,
      location: candidate.replaceAll(RegExp(r'[,.!]+$'), ''),
    );
  }

  bool _containsDateOrTimeZh(String text) {
    return RegExp(
      r'[今天明日後后大前昨周一二三四五六日天点時分秒半上中下晚早凌晨里]'
      r'|\d{1,2}[点時分秒]',
    ).hasMatch(text);
  }

  bool _isTimeOnlyZh(String text) {
    return RegExp(r'^[\d一二三四五六七八九十点時分半秒上中下午晚凌晨早]+$').hasMatch(text);
  }

  bool _containsDateOrTime(String text) {
    return RegExp(
      r'\b(today|tomorrow|next|monday|tuesday|wednesday|thursday|friday|'
      r'saturday|sunday|noon|midnight|tonight|am|pm)\b|\d{1,2}(:\d{2})?',
      caseSensitive: false,
    ).hasMatch(text);
  }

  // ─────────────────────────────────────────────────────────────
  // Title extraction
  // ─────────────────────────────────────────────────────────────

  String _extractTitle({
    required String original,
    required List<String> removablePhrases,
    bool isChinese = false,
  }) {
    var title = ' $original ';
    final ordered = removablePhrases
        .where((String phrase) => phrase.trim().isNotEmpty)
        .toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));

    for (final phrase in ordered) {
      // For Chinese, use a simpler substring removal since word boundaries differ
      if (isChinese) {
        // Escape for regex and replace
        final escaped = RegExp.escape(phrase);
        title = title.replaceAll(RegExp(escaped), ' ');
      } else {
        final pattern = _phraseRegex(phrase);
        title = title.replaceAll(pattern, ' ');
      }
    }

    if (!isChinese) {
      title = title.replaceAll(
        RegExp(r'\b(on|at)\b', caseSensitive: false),
        ' ',
      );
    }

    // Common Chinese stop words in event context
    if (isChinese) {
      // Remove 【】bracketed text (notification source headers)
      title = title.replaceAll(RegExp(r'【[^】]*】'), ' ');
      // Remove common notification noise prefixes
      title = title.replaceAll(RegExp(r'(?:顺丰|中通|圆通|韵达|EMS|京东)?快递[：:]?\s*'), ' ');
      title = title.replaceAll(RegExp(r'(?:招商|工商|建设|农业|中国|交通|浦发|中信)?银行[：:]?\s*'), ' ');
      title = title.replaceAll(RegExp(r'(?:教务|学生|后勤|财务|信息)处[：:]?\s*'), ' ');
      // Remove common stop words (but NOT 去/到 — they're meaningful verbs)
      title = title.replaceAll(RegExp(r'[在了的您请]'), ' ');
      // Remove 将/定于/于/将于 etc.
      title = title.replaceAll(RegExp(r'(?:将|定|拟)\s*[于於在]'), ' ');
    }

    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceAll(RegExp(r'^[\-,.:;，。：；！？、\s]+|[\-,.:;，。：；！？、\s]+$'), '');

    // Capitalize first letter for English titles
    if (!isChinese && title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title;
  }

  RegExp _phraseRegex(String phrase) {
    final escaped = RegExp.escape(phrase.trim()).replaceAll(r'\ ', r'\s+');
    return RegExp('\\b$escaped\\b', caseSensitive: false);
  }

  // ─────────────────────────────────────────────────────────────
  // Date math
  // ─────────────────────────────────────────────────────────────

  DateTime _resolveUpcomingWeekday(DateTime fromDate, int targetWeekday) {
    var diff = (targetWeekday - fromDate.weekday + DateTime.daysPerWeek) % 7;
    if (diff == 0) diff = 7;
    return fromDate.add(Duration(days: diff));
  }

  /// Resolve weekday with week offset: 下周三=next Wed, 这周一=this Mon, 上周五=last Fri
  DateTime _resolveOffsetWeekday(DateTime fromDate, int targetWeekday, int weekOffset) {
    final rawDiff = targetWeekday - fromDate.weekday;
    // For 下 week: always the NEXT occurrence
    // For 这/本 week: if same day or later this week OK, otherwise it's in the past (this week's already-passed day)
    // For 上 week: the PAST occurrence
    int diff;
    if (weekOffset >= 1) {
      // 下周: next occurrence (at least 1 day away)
      diff = rawDiff <= 0 ? rawDiff + 7 : rawDiff;
    } else if (weekOffset <= -1) {
      // 上周: most recent past occurrence
      diff = rawDiff >= 0 ? rawDiff - 7 : rawDiff;
    } else {
      // 本周: this week's occurrence (can be past, today, or future)
      diff = rawDiff;
    }
    return fromDate.add(Duration(days: diff));
  }

  _ClockTime _defaultTime(DateTime now) {
    final nextHour = now.add(const Duration(hours: 1));
    return _ClockTime(hour: nextHour.hour, minute: 0);
  }

  String _normalizeAmPm(String marker) {
    final lettersOnly = marker.toLowerCase().replaceAll(RegExp(r'[^ap]'), '');
    if (lettersOnly.isEmpty) return 'am';
    return lettersOnly.endsWith('p') ? 'pm' : 'am';
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }
}

// ─────────────────────────────────────────────────────────────
// Internal data classes (unchanged)
// ─────────────────────────────────────────────────────────────

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
