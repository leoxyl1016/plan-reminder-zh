import '../entities/reminder_event.dart';

abstract class ReminderRepository {
  Stream<List<ReminderEvent>> watchEvents();

  Future<List<ReminderEvent>> getEvents();

  Future<void> saveEvent(ReminderEvent event);

  Future<void> deleteEvent(String eventId);
}
