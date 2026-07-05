import '../../domain/entities/reminder_event.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_datasource.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._localDatasource);

  final ReminderLocalDatasource _localDatasource;

  @override
  Future<void> deleteEvent(String eventId) {
    return _localDatasource.deleteEvent(eventId);
  }

  @override
  Future<List<ReminderEvent>> getEvents() {
    return _localDatasource.getEvents();
  }

  @override
  Future<void> saveEvent(ReminderEvent event) {
    return _localDatasource.saveEvent(event);
  }

  @override
  Stream<List<ReminderEvent>> watchEvents() {
    return _localDatasource.watchEvents();
  }
}
