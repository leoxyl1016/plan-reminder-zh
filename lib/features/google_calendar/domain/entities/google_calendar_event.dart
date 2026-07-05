import 'package:equatable/equatable.dart';

class GoogleCalendarEvent extends Equatable {
  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.location,
    this.description,
    this.isAllDay = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final String? description;
  final bool isAllDay;

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        start,
        end,
        location,
        description,
        isAllDay,
      ];
}
