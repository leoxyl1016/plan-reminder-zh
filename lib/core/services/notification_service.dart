import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../../features/reminder/domain/entities/reminder_event.dart';

class NotificationService {
  NotificationService();

  static const String _channelId = 'plan_reminder_channel';
  static const String _channelName = '提醒助手通知';
  static const String _channelDescription =
      '日程提醒';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _reminderOffsetMinutes = AppConstants.reminderOffsetMinutes;

  int get reminderOffsetMinutes => _reminderOffsetMinutes;

  void setReminderOffsetMinutes(int minutes) {
    _reminderOffsetMinutes = minutes < 0 ? 0 : minutes;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isInitialized = true;
  }

  Future<void> scheduleReminder(ReminderEvent event) async {
    final triggerTime = event.dateTime.subtract(
      Duration(minutes: _reminderOffsetMinutes),
    );

    if (triggerTime.isBefore(DateTime.now())) {
      return;
    }

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      _notificationId(event.id),
      '提醒',
      '${event.title} 将在 $_reminderOffsetMinutes 分钟后开始',
      tz.TZDateTime.from(triggerTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: event.id,
    );
  }

  Future<void> cancelReminder(String eventId) {
    return _notificationsPlugin.cancel(_notificationId(eventId));
  }

  Future<void> cancelAll() {
    return _notificationsPlugin.cancelAll();
  }

  int _notificationId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }
}
