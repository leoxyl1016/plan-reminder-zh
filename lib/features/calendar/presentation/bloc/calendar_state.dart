part of 'calendar_bloc.dart';

enum CalendarStatus {
  initial,
  loading,
  loaded,
  failure,
}

class CalendarState extends Equatable {
  const CalendarState({
    required this.selectedDay,
    required this.focusedDay,
    this.status = CalendarStatus.initial,
    this.events = const <ReminderEvent>[],
    this.errorMessage,
  });

  final CalendarStatus status;
  final List<ReminderEvent> events;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final String? errorMessage;

  List<ReminderEvent> get selectedDayEvents {
    return events
        .where(
          (ReminderEvent event) => event.dateTime.dateOnly == selectedDay.dateOnly,
        )
        .toList()
      ..sort(
        (ReminderEvent a, ReminderEvent b) => a.dateTime.compareTo(b.dateTime),
      );
  }

  CalendarState copyWith({
    CalendarStatus? status,
    List<ReminderEvent>? events,
    DateTime? selectedDay,
    DateTime? focusedDay,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      events: events ?? this.events,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        events,
        selectedDay,
        focusedDay,
        errorMessage,
      ];
}
