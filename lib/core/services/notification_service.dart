import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
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
  static const MethodChannel _settingsChannel =
      MethodChannel('com.company.reminderapp/settings');

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _reminderOffsetMinutes = AppConstants.reminderOffsetMinutes;
  NotificationPermissionStatus _permissionStatus =
      const NotificationPermissionStatus();

  int get reminderOffsetMinutes => _reminderOffsetMinutes;
  NotificationPermissionStatus get permissionStatus => _permissionStatus;

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

    await refreshPermissionStatus();
    _isInitialized = true;
  }

  Future<NotificationScheduleResult> scheduleReminder(ReminderEvent event) async {
    final triggerTime = event.dateTime.subtract(
      Duration(minutes: _reminderOffsetMinutes),
    );

    if (triggerTime.isBefore(DateTime.now())) {
      return const NotificationScheduleResult(
        scheduled: false,
        errorMessage: '提醒时间已过，未调度通知。',
      );
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

    await refreshPermissionStatus();

    final title = _reminderOffsetMinutes == 0 ? '日程开始' : '日程提醒';
    final body = _reminderOffsetMinutes == 0
        ? '${event.title} 现在开始'
        : '${event.title} 将在 $_reminderOffsetMinutes 分钟后开始';

    try {
      await _zonedSchedule(
        event: event,
        triggerTime: triggerTime,
        details: details,
        title: title,
        body: body,
        scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      return NotificationScheduleResult(
        scheduled: true,
        scheduledAt: triggerTime,
        usedExactAlarm: true,
        warningMessage: _permissionStatus.notificationsEnabled
            ? null
            : '通知权限未开启，日程已保存但系统可能不会显示提醒。',
      );
    } on PlatformException catch (error) {
      if (!_isExactAlarmError(error)) {
        return NotificationScheduleResult(
          scheduled: false,
          errorMessage: '通知调度失败: ${error.message ?? error.code}',
        );
      }

      await _zonedSchedule(
        event: event,
        triggerTime: triggerTime,
        details: details,
        title: title,
        body: body,
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      return NotificationScheduleResult(
        scheduled: true,
        scheduledAt: triggerTime,
        usedExactAlarm: false,
        warningMessage: '缺少精确提醒权限，已使用非精确通知调度。提醒可能略有延迟。',
      );
    } catch (error) {
      return NotificationScheduleResult(
        scheduled: false,
        errorMessage: '通知调度失败: $error',
      );
    }
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

  Future<NotificationPermissionStatus> refreshPermissionStatus() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    var notificationsEnabled = true;
    var exactAlarmsEnabled = true;

    if (android != null) {
      try {
        notificationsEnabled =
            await (android as dynamic).areNotificationsEnabled() as bool? ??
                true;
      } catch (_) {
        notificationsEnabled = true;
      }

      try {
        exactAlarmsEnabled =
            await (android as dynamic).canScheduleExactNotifications()
                    as bool? ??
                true;
      } catch (_) {
        exactAlarmsEnabled = true;
      }
    }

    _permissionStatus = NotificationPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
    return _permissionStatus;
  }

  Future<void> requestNotificationPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await refreshPermissionStatus();
  }

  Future<void> requestExactAlarmPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    try {
      await (android as dynamic).requestExactAlarmsPermission();
    } catch (_) {
      try {
        await _settingsChannel.invokeMethod<void>('openExactAlarmSettings');
      } catch (_) {
        // Some Android versions do not expose a dedicated settings panel.
      }
    }
    await refreshPermissionStatus();
  }

  Future<void> _zonedSchedule({
    required ReminderEvent event,
    required DateTime triggerTime,
    required NotificationDetails details,
    required String title,
    required String body,
    required AndroidScheduleMode scheduleMode,
  }) {
    return _notificationsPlugin.zonedSchedule(
      _notificationId(event.id),
      title,
      body,
      tz.TZDateTime.from(triggerTime, tz.local),
      details,
      androidScheduleMode: scheduleMode,
      payload: event.id,
    );
  }

  bool _isExactAlarmError(PlatformException error) {
    final message = '${error.code} ${error.message}'.toLowerCase();
    return message.contains('exact') ||
        message.contains('alarm') ||
        message.contains('schedule_exact_alarm');
  }
}

class NotificationPermissionStatus {
  const NotificationPermissionStatus({
    this.notificationsEnabled = true,
    this.exactAlarmsEnabled = true,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
}

class NotificationScheduleResult {
  const NotificationScheduleResult({
    required this.scheduled,
    this.scheduledAt,
    this.usedExactAlarm = false,
    this.warningMessage,
    this.errorMessage,
  });

  final bool scheduled;
  final DateTime? scheduledAt;
  final bool usedExactAlarm;
  final String? warningMessage;
  final String? errorMessage;
}
