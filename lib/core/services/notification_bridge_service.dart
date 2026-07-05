import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../features/parser/domain/entities/parsed_event.dart';
import '../../features/parser/domain/services/event_parser_service.dart';
import '../../features/reminder/domain/entities/reminder_event.dart';
import 'reminder_scheduling_service.dart';

/// Bridge between Android native notification/SMS listeners and Flutter.
/// Listens on MethodChannels for incoming SMS and notification data,
/// then parses them through the NLP parser and auto-creates events.
class NotificationBridgeService {
  NotificationBridgeService({
    required EventParserService parserService,
    required ReminderSchedulingService reminderSchedulingService,
  }) : _parserService = parserService,
       _reminderSchedulingService = reminderSchedulingService;

  final EventParserService _parserService;
  final ReminderSchedulingService _reminderSchedulingService;
  final Uuid _uuid = const Uuid();

  /// Callback when a notification is parsed into an event.
  /// Fires BEFORE auto-saving.
  void Function(ParsedEvent event, NotificationSource source)?
      onEventParsed;

  /// Whether to auto-save high-confidence parsed events.
  bool autoSave = true;

  static const _smsChannelName = 'com.company.reminderapp/sms';
  static const _notifChannelName = 'com.company.reminderapp/notifications';

  MethodChannel? _smsChannel;
  MethodChannel? _notifChannel;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Register MethodChannels to receive native events.
  void initialize() {
    if (_isInitialized) return;

    _smsChannel = const MethodChannel(_smsChannelName);
    _smsChannel!.setMethodCallHandler(_handleSmsMethodCall);

    _notifChannel = const MethodChannel(_notifChannelName);
    _notifChannel!.setMethodCallHandler(_handleNotifMethodCall);

    _isInitialized = true;
    debugPrint('NotificationBridgeService: initialized');
  }

  void dispose() {
    _smsChannel?.setMethodCallHandler(null);
    _notifChannel?.setMethodCallHandler(null);
    _isInitialized = false;
  }

  Future<dynamic> _handleSmsMethodCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      if (args == null) return;

      final body = args['body'] as String? ?? '';
      final sender = args['sender'] as String? ?? 'Unknown';

      if (body.isEmpty) return;

      await _processIncomingText(
        text: body,
        source: NotificationSource(
          type: NotificationSourceType.sms,
          sender: sender,
        ),
      );
    }
  }

  Future<dynamic> _handleNotifMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      if (args == null) return;

      final body = args['body'] as String? ?? '';
      final source = args['source'] as String? ?? 'Unknown';
      final packageName = args['packageName'] as String? ?? '';

      if (body.isEmpty) return;

      await _processIncomingText(
        text: body,
        source: NotificationSource(
          type: NotificationSourceType.notification,
          sender: source,
          packageName: packageName,
        ),
      );
    }
  }

  /// Process incoming text through NLP parser and auto-save if enabled.
  Future<void> _processIncomingText({
    required String text,
    required NotificationSource source,
  }) async {
    try {
      final parsedEvent = _parserService.parse(text, reference: DateTime.now());
      debugPrint(
        '📩 [${source.sourceLabel}] 解析成功: "${parsedEvent.title}" '
        '@ ${parsedEvent.dateTime}${parsedEvent.location != null ? " @ ${parsedEvent.location}" : ""}',
      );

      // Notify listeners
      onEventParsed?.call(parsedEvent, source);

      // Auto-save only when the parser found a concrete reminder time.
      if (autoSave && parsedEvent.hasExplicitTime) {
        final reminderEvent = ReminderEvent(
          id: _uuid.v4(),
          title: parsedEvent.title,
          dateTime: parsedEvent.dateTime,
          location: parsedEvent.location,
          createdAt: DateTime.now(),
          sourceText: '[${source.sourceLabel}] $text',
          sourceType: source.type == NotificationSourceType.sms
              ? ReminderSourceType.sms
              : ReminderSourceType.notification,
        );
        final result = await _reminderSchedulingService.createReminder(
          reminderEvent,
          sourceType: reminderEvent.sourceType,
        );
        debugPrint('📩 已自动保存提醒: ${result.event.title}');
        if (result.message != null) {
          debugPrint('NotificationBridge: ${result.message}');
        }
      } else if (autoSave) {
        debugPrint(
          'NotificationBridge: ignored parsed event without explicit time.',
        );
      }
    } on ParserException {
      // Text doesn't contain a recognizable event - silently ignore
    } catch (e) {
      debugPrint('NotificationBridge: error processing text: $e');
    }
  }
}

/// Source of the incoming notification
class NotificationSource {
  const NotificationSource({
    required this.type,
    this.sender = '',
    this.packageName = '',
  });

  final NotificationSourceType type;
  final String sender;
  final String packageName;

  String get sourceLabel {
    switch (type) {
      case NotificationSourceType.sms:
        return '短信 ($sender)';
      case NotificationSourceType.notification:
        return sender;
    }
  }
}

enum NotificationSourceType {
  sms,
  notification,
}
