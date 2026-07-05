import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get toDateLabel => DateFormat('M月d日 EEE, yyyy', 'zh').format(this);

  String get toTimeLabel => DateFormat('HH:mm').format(this);

  String get toDateTimeLabel => '$toDateLabel $toTimeLabel';

  DateTime get dateOnly => DateTime(year, month, day);
}
