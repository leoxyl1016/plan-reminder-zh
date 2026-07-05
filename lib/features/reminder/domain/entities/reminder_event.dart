import 'package:equatable/equatable.dart';

const Object _unchanged = Object();

class ReminderEvent extends Equatable {
  const ReminderEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.createdAt,
    this.location,
    this.sourceText,
    this.notificationScheduledAt,
    this.notificationError,
    this.sourceType = ReminderSourceType.manual,
    this.needsConfirmation = false,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final String? location;
  final DateTime createdAt;
  final String? sourceText;
  final DateTime? notificationScheduledAt;
  final String? notificationError;
  final ReminderSourceType sourceType;
  final bool needsConfirmation;

  ReminderEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    DateTime? createdAt,
    String? sourceText,
    Object? notificationScheduledAt = _unchanged,
    Object? notificationError = _unchanged,
    ReminderSourceType? sourceType,
    bool? needsConfirmation,
  }) {
    return ReminderEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      sourceText: sourceText ?? this.sourceText,
      notificationScheduledAt: notificationScheduledAt == _unchanged
          ? this.notificationScheduledAt
          : notificationScheduledAt as DateTime?,
      notificationError: notificationError == _unchanged
          ? this.notificationError
          : notificationError as String?,
      sourceType: sourceType ?? this.sourceType,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        dateTime,
        location,
        createdAt,
        sourceText,
        notificationScheduledAt,
        notificationError,
        sourceType,
        needsConfirmation,
      ];
}

enum ReminderSourceType {
  manual,
  chat,
  notification,
  sms,
}
