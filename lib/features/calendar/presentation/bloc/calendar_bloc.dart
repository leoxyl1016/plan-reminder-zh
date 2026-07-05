import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/reminder_scheduling_service.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../reminder/domain/entities/reminder_event.dart';
import '../../../reminder/domain/repositories/reminder_repository.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEventAction, CalendarState> {
  CalendarBloc({
    required ReminderRepository reminderRepository,
    required ReminderSchedulingService reminderSchedulingService,
  })  : _reminderRepository = reminderRepository,
        _reminderSchedulingService = reminderSchedulingService,
        super(
          CalendarState(
            selectedDay: DateTime.now().dateOnly,
            focusedDay: DateTime.now().dateOnly,
          ),
        ) {
    on<CalendarSubscriptionRequested>(_onSubscriptionRequested);
    on<CalendarEventsUpdated>(_onEventsUpdated);
    on<CalendarEventSaved>(_onEventSaved);
    on<CalendarEventDeleted>(_onEventDeleted);
    on<CalendarDaySelected>(_onDaySelected);
    on<CalendarFailureOccurred>(_onFailureOccurred);

    add(const CalendarSubscriptionRequested());
  }

  final ReminderRepository _reminderRepository;
  final ReminderSchedulingService _reminderSchedulingService;
  StreamSubscription<List<ReminderEvent>>? _eventsSubscription;

  Future<void> _onSubscriptionRequested(
    CalendarSubscriptionRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading, errorMessage: null));
    await _eventsSubscription?.cancel();

    _eventsSubscription = _reminderRepository.watchEvents().listen(
      (List<ReminderEvent> events) {
        add(CalendarEventsUpdated(events));
      },
      onError: (Object error) {
        add(CalendarFailureOccurred(error.toString()));
      },
    );
  }

  void _onEventsUpdated(
    CalendarEventsUpdated event,
    Emitter<CalendarState> emit,
  ) {
    emit(
      state.copyWith(
        status: CalendarStatus.loaded,
        events: event.events,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onEventSaved(
    CalendarEventSaved event,
    Emitter<CalendarState> emit,
  ) async {
    final isNewEvent = !state.events.any(
      (ReminderEvent existing) => existing.id == event.event.id,
    );

    try {
      final result = isNewEvent
          ? await _reminderSchedulingService.createReminder(event.event)
          : await _reminderSchedulingService.updateReminder(event.event);
      if (result.message != null) {
        add(CalendarFailureOccurred(result.message!));
      }
    } catch (error) {
      add(CalendarFailureOccurred(error.toString()));
    }
  }

  Future<void> _onEventDeleted(
    CalendarEventDeleted event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _reminderSchedulingService.deleteReminder(event.eventId);
    } catch (error) {
      add(CalendarFailureOccurred(error.toString()));
    }
  }

  void _onDaySelected(
    CalendarDaySelected event,
    Emitter<CalendarState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDay: event.selectedDay.dateOnly,
        focusedDay: event.focusedDay.dateOnly,
      ),
    );
  }

  void _onFailureOccurred(
    CalendarFailureOccurred event,
    Emitter<CalendarState> emit,
  ) {
    emit(
      state.copyWith(
        status: CalendarStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _eventsSubscription?.cancel();
    return super.close();
  }
}
