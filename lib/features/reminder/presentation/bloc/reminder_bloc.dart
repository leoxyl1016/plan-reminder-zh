import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/reminder_scheduling_service.dart';
import '../../domain/entities/reminder_event.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEventAction, ReminderState> {
  ReminderBloc({
    required ReminderSchedulingService reminderSchedulingService,
  })  : _reminderSchedulingService = reminderSchedulingService,
        super(const ReminderState()) {
    on<ReminderScheduleRequested>(_onScheduleRequested);
    on<ReminderCancelRequested>(_onCancelRequested);
    on<ReminderRescheduleRequested>(_onRescheduleRequested);
    on<ReminderStatusResetRequested>(_onStatusResetRequested);
  }

  final ReminderSchedulingService _reminderSchedulingService;

  Future<void> _onScheduleRequested(
    ReminderScheduleRequested event,
    Emitter<ReminderState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReminderStatus.processing,
        errorMessage: null,
        eventId: event.event.id,
      ),
    );

    try {
      final result = await _reminderSchedulingService.createReminder(
        event.event,
      );
      emit(
        state.copyWith(
          status: result.notificationScheduled
              ? ReminderStatus.success
              : ReminderStatus.failure,
          errorMessage: result.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCancelRequested(
    ReminderCancelRequested event,
    Emitter<ReminderState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReminderStatus.processing,
        errorMessage: null,
        eventId: event.eventId,
      ),
    );

    try {
      await _reminderSchedulingService.cancelReminderNotification(event.eventId);
      emit(state.copyWith(status: ReminderStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRescheduleRequested(
    ReminderRescheduleRequested event,
    Emitter<ReminderState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReminderStatus.processing,
        errorMessage: null,
        eventId: event.event.id,
      ),
    );

    try {
      final result = await _reminderSchedulingService.updateReminder(
        event.event,
      );
      emit(
        state.copyWith(
          status: result.notificationScheduled
              ? ReminderStatus.success
              : ReminderStatus.failure,
          errorMessage: result.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReminderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onStatusResetRequested(
    ReminderStatusResetRequested event,
    Emitter<ReminderState> emit,
  ) {
    emit(state.copyWith(status: ReminderStatus.initial, errorMessage: null));
  }
}
