part of 'google_calendar_bloc.dart';

abstract class GoogleCalendarAction extends Equatable {
  const GoogleCalendarAction();

  @override
  List<Object?> get props => <Object?>[];
}

class GoogleCalendarStarted extends GoogleCalendarAction {
  const GoogleCalendarStarted();
}

class GoogleCalendarConnectRequested extends GoogleCalendarAction {
  const GoogleCalendarConnectRequested();
}

class GoogleCalendarDisconnectRequested extends GoogleCalendarAction {
  const GoogleCalendarDisconnectRequested();
}

class GoogleCalendarRefreshRequested extends GoogleCalendarAction {
  const GoogleCalendarRefreshRequested();
}
