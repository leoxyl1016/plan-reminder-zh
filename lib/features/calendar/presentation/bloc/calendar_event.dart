part of 'calendar_bloc.dart';

abstract class CalendarEventAction extends Equatable {
  const CalendarEventAction();

  @override
  List<Object?> get props => <Object?>[];
}

class CalendarSubscriptionRequested extends CalendarEventAction {
  const CalendarSubscriptionRequested();
}

class CalendarEventsUpdated extends CalendarEventAction {
  const CalendarEventsUpdated(this.events);

  final List<ReminderEvent> events;

  @override
  List<Object?> get props => <Object?>[events];
}

class CalendarEventSaved extends CalendarEventAction {
  const CalendarEventSaved(this.event);

  final ReminderEvent event;

  @override
  List<Object?> get props => <Object?>[event];
}

class CalendarEventDeleted extends CalendarEventAction {
  const CalendarEventDeleted(this.eventId);

  final String eventId;

  @override
  List<Object?> get props => <Object?>[eventId];
}

class CalendarDaySelected extends CalendarEventAction {
  const CalendarDaySelected({
    required this.selectedDay,
    required this.focusedDay,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;

  @override
  List<Object?> get props => <Object?>[selectedDay, focusedDay];
}

class CalendarFailureOccurred extends CalendarEventAction {
  const CalendarFailureOccurred(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
