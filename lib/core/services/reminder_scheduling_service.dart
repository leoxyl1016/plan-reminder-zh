import '../../features/google_calendar/data/services/google_calendar_service.dart';
import '../../features/reminder/domain/entities/reminder_event.dart';
import '../../features/reminder/domain/repositories/reminder_repository.dart';
import 'notification_service.dart';

class ReminderSchedulingService {
  ReminderSchedulingService({
    required ReminderRepository reminderRepository,
    required NotificationService notificationService,
    required GoogleCalendarService googleCalendarService,
  })  : _reminderRepository = reminderRepository,
        _notificationService = notificationService,
        _googleCalendarService = googleCalendarService;

  final ReminderRepository _reminderRepository;
  final NotificationService _notificationService;
  final GoogleCalendarService _googleCalendarService;

  Future<ReminderSchedulingResult> createReminder(
    ReminderEvent event, {
    ReminderSourceType? sourceType,
    bool syncGoogleCalendar = true,
  }) async {
    return _saveAndSchedule(
      event.copyWith(sourceType: sourceType ?? event.sourceType),
      syncGoogleCalendar: syncGoogleCalendar,
      syncAsNewGoogleEvent: true,
    );
  }

  Future<ReminderSchedulingResult> updateReminder(
    ReminderEvent event, {
    bool syncGoogleCalendar = false,
  }) async {
    await _notificationService.cancelReminder(event.id);
    return _saveAndSchedule(
      event,
      syncGoogleCalendar: syncGoogleCalendar,
      syncAsNewGoogleEvent: false,
    );
  }

  Future<void> deleteReminder(String eventId) async {
    await _notificationService.cancelReminder(eventId);
    await _reminderRepository.deleteEvent(eventId);
  }

  Future<void> cancelReminderNotification(String eventId) async {
    await _notificationService.cancelReminder(eventId);
    final events = await _reminderRepository.getEvents();
    for (final event in events) {
      if (event.id != eventId) {
        continue;
      }
      await _reminderRepository.saveEvent(
        event.copyWith(
          notificationScheduledAt: null,
          notificationError: '提醒已取消。',
        ),
      );
      break;
    }
  }

  Future<ReminderRescheduleSummary> rescheduleAllFutureReminders() async {
    final events = await _reminderRepository.getEvents();
    var scheduled = 0;
    var failed = 0;

    for (final event in events) {
      if (event.dateTime.isBefore(DateTime.now()) || event.needsConfirmation) {
        continue;
      }

      final result = await updateReminder(event);
      if (result.notificationScheduled) {
        scheduled++;
      } else {
        failed++;
      }
    }

    return ReminderRescheduleSummary(scheduled: scheduled, failed: failed);
  }

  Future<ReminderSchedulingResult> _saveAndSchedule(
    ReminderEvent event, {
    required bool syncGoogleCalendar,
    required bool syncAsNewGoogleEvent,
  }) async {
    NotificationScheduleResult notificationResult =
        const NotificationScheduleResult(
      scheduled: false,
      errorMessage: '日程需要确认，未调度通知。',
    );

    if (!event.needsConfirmation) {
      notificationResult = await _notificationService.scheduleReminder(event);
    }

    final savedEvent = event.copyWith(
      notificationScheduledAt: notificationResult.scheduledAt,
      notificationError:
          notificationResult.errorMessage ?? notificationResult.warningMessage,
    );
    await _reminderRepository.saveEvent(savedEvent);

    String? googleCalendarWarning;
    if (syncGoogleCalendar && syncAsNewGoogleEvent) {
      googleCalendarWarning = await _trySyncCreatedEventToGoogleCalendar(
        savedEvent,
      );
    }

    return ReminderSchedulingResult(
      event: savedEvent,
      notificationScheduled: notificationResult.scheduled,
      notificationWarning: notificationResult.warningMessage,
      notificationError: notificationResult.errorMessage,
      googleCalendarWarning: googleCalendarWarning,
    );
  }

  Future<String?> _trySyncCreatedEventToGoogleCalendar(
    ReminderEvent event,
  ) async {
    try {
      final isConnected = await _googleCalendarService.isSignedIn();
      if (!isConnected) {
        return null;
      }

      await _googleCalendarService.createEvent(
        title: event.title,
        start: event.dateTime,
        location: event.location,
        description: event.sourceText,
      );
      return null;
    } catch (error) {
      return '已保存本地提醒，但 Google 日历同步失败: $error';
    }
  }
}

class ReminderSchedulingResult {
  const ReminderSchedulingResult({
    required this.event,
    required this.notificationScheduled,
    this.notificationWarning,
    this.notificationError,
    this.googleCalendarWarning,
  });

  final ReminderEvent event;
  final bool notificationScheduled;
  final String? notificationWarning;
  final String? notificationError;
  final String? googleCalendarWarning;

  String? get message =>
      notificationError ?? notificationWarning ?? googleCalendarWarning;
}

class ReminderRescheduleSummary {
  const ReminderRescheduleSummary({
    required this.scheduled,
    required this.failed,
  });

  final int scheduled;
  final int failed;
}
