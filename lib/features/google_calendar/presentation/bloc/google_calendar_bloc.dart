import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/google_calendar_service.dart';
import '../../domain/entities/google_calendar_event.dart';

part 'google_calendar_event.dart';
part 'google_calendar_state.dart';

class GoogleCalendarBloc
    extends Bloc<GoogleCalendarAction, GoogleCalendarState> {
  GoogleCalendarBloc({
    required GoogleCalendarService calendarService,
  })  : _calendarService = calendarService,
        super(const GoogleCalendarState()) {
    on<GoogleCalendarStarted>(_onStarted);
    on<GoogleCalendarConnectRequested>(_onConnectRequested);
    on<GoogleCalendarDisconnectRequested>(_onDisconnectRequested);
    on<GoogleCalendarRefreshRequested>(_onRefreshRequested);
  }

  final GoogleCalendarService _calendarService;

  Future<void> _onStarted(
    GoogleCalendarStarted event,
    Emitter<GoogleCalendarState> emit,
  ) async {
    emit(state.copyWith(status: GoogleCalendarStatus.loading, errorMessage: null));

    try {
      final connected = await _calendarService.isSignedIn();
      if (!connected) {
        emit(
          state.copyWith(
            status: GoogleCalendarStatus.disconnected,
            isConnected: false,
            events: const <GoogleCalendarEvent>[],
            email: null,
          ),
        );
        return;
      }

      final email = await _calendarService.currentUserEmail();
      final events = await _calendarService.getUpcomingEvents();
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.connected,
          isConnected: true,
          email: email,
          events: events,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.error,
          isConnected: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onConnectRequested(
    GoogleCalendarConnectRequested event,
    Emitter<GoogleCalendarState> emit,
  ) async {
    emit(state.copyWith(status: GoogleCalendarStatus.loading, errorMessage: null));

    try {
      final email = await _calendarService.connect();
      final events = await _calendarService.getUpcomingEvents();
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.connected,
          isConnected: true,
          email: email,
          events: events,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.error,
          isConnected: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDisconnectRequested(
    GoogleCalendarDisconnectRequested event,
    Emitter<GoogleCalendarState> emit,
  ) async {
    emit(state.copyWith(status: GoogleCalendarStatus.loading, errorMessage: null));

    try {
      await _calendarService.disconnect();
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.disconnected,
          isConnected: false,
          email: null,
          events: const <GoogleCalendarEvent>[],
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    GoogleCalendarRefreshRequested event,
    Emitter<GoogleCalendarState> emit,
  ) async {
    if (!state.isConnected) {
      add(const GoogleCalendarStarted());
      return;
    }

    emit(state.copyWith(status: GoogleCalendarStatus.loading, errorMessage: null));

    try {
      final events = await _calendarService.getUpcomingEvents();
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.connected,
          events: events,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GoogleCalendarStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
