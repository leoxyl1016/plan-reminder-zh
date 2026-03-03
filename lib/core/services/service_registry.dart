import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/google_calendar/data/services/google_calendar_service.dart';
import '../../features/parser/data/services/local_event_parser_service.dart';
import '../../features/parser/domain/services/event_parser_service.dart';
import '../../features/reminder/data/datasources/reminder_local_datasource.dart';
import '../../features/reminder/data/repositories/reminder_repository_impl.dart';
import '../../features/reminder/domain/repositories/reminder_repository.dart';
import 'hive_service.dart';
import 'notification_service.dart';
import 'voice_input_service.dart';

class ServiceRegistry {
  const ServiceRegistry._();

  static late EventParserService parserService;
  static late ChatRepository chatRepository;
  static late ReminderRepository reminderRepository;
  static late NotificationService notificationService;
  static late VoiceInputService voiceInputService;
  static late GoogleCalendarService googleCalendarService;

  static Future<void> initialize() async {
    await HiveService.initialize();

    parserService = LocalEventParserService();
    chatRepository = ChatRepositoryImpl(HiveService.chatBox);
    reminderRepository = ReminderRepositoryImpl(
      ReminderLocalDatasource(HiveService.remindersBox),
    );

    notificationService = NotificationService();
    await notificationService.initialize();

    voiceInputService = VoiceInputService();
    googleCalendarService = GoogleCalendarService();
  }
}
