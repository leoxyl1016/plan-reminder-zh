part of 'reminder_bloc.dart';

abstract class ReminderEventAction extends Equatable {
  const ReminderEventAction();

  @override
  List<Object?> get props => <Object?>[];
}

class ReminderScheduleRequested extends ReminderEventAction {
  const ReminderScheduleRequested(this.event);

  final ReminderEvent event;

  @override
  List<Object?> get props => <Object?>[event];
}

class ReminderCancelRequested extends ReminderEventAction {
  const ReminderCancelRequested(this.eventId);

  final String eventId;

  @override
  List<Object?> get props => <Object?>[eventId];
}

class ReminderRescheduleRequested extends ReminderEventAction {
  const ReminderRescheduleRequested(this.event);

  final ReminderEvent event;

  @override
  List<Object?> get props => <Object?>[event];
}

class ReminderStatusResetRequested extends ReminderEventAction {
  const ReminderStatusResetRequested();
}
