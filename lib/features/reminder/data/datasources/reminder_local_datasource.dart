import 'package:hive/hive.dart';

import '../../domain/entities/reminder_event.dart';
import '../models/reminder_event_model.dart';

class ReminderLocalDatasource {
  ReminderLocalDatasource(this._box);

  final Box<ReminderEventModel> _box;

  Future<List<ReminderEvent>> getEvents() async {
    final events = _box.values.map((ReminderEventModel e) => e.toEntity()).toList();
    events.sort((ReminderEvent a, ReminderEvent b) => a.dateTime.compareTo(b.dateTime));
    return events;
  }

  Stream<List<ReminderEvent>> watchEvents() async* {
    yield await getEvents();
    await for (final _ in _box.watch()) {
      yield await getEvents();
    }
  }

  Future<void> saveEvent(ReminderEvent event) {
    final model = ReminderEventModel.fromEntity(event);
    return _box.put(event.id, model);
  }

  Future<void> deleteEvent(String eventId) {
    return _box.delete(eventId);
  }
}
