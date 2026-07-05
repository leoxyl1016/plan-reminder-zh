part of 'google_calendar_bloc.dart';

enum GoogleCalendarStatus {
  initial,
  loading,
  disconnected,
  connected,
  error,
}

class GoogleCalendarState extends Equatable {
  const GoogleCalendarState({
    this.status = GoogleCalendarStatus.initial,
    this.isConnected = false,
    this.email,
    this.events = const <GoogleCalendarEvent>[],
    this.errorMessage,
  });

  final GoogleCalendarStatus status;
  final bool isConnected;
  final String? email;
  final List<GoogleCalendarEvent> events;
  final String? errorMessage;

  GoogleCalendarState copyWith({
    GoogleCalendarStatus? status,
    bool? isConnected,
    Object? email = _marker,
    List<GoogleCalendarEvent>? events,
    Object? errorMessage = _marker,
  }) {
    return GoogleCalendarState(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      email: email == _marker ? this.email : email as String?,
      events: events ?? this.events,
      errorMessage:
          errorMessage == _marker ? this.errorMessage : errorMessage as String?,
    );
  }

  static const Object _marker = Object();

  @override
  List<Object?> get props => <Object?>[
        status,
        isConnected,
        email,
        events,
        errorMessage,
      ];
}
