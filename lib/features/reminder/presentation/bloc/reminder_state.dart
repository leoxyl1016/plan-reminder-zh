part of 'reminder_bloc.dart';

enum ReminderStatus {
  initial,
  processing,
  success,
  failure,
}

class ReminderState extends Equatable {
  const ReminderState({
    this.status = ReminderStatus.initial,
    this.eventId,
    this.errorMessage,
  });

  final ReminderStatus status;
  final String? eventId;
  final String? errorMessage;

  ReminderState copyWith({
    ReminderStatus? status,
    String? eventId,
    String? errorMessage,
  }) {
    return ReminderState(
      status: status ?? this.status,
      eventId: eventId ?? this.eventId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, eventId, errorMessage];
}
