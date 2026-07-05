import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../features/reminder/data/models/reminder_event_model.dart';

class HiveService {
  const HiveService._();

  static late Box<ReminderEventModel> remindersBox;
  static late Box<String> chatBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ReminderEventModelAdapter.typeIdValue)) {
      Hive.registerAdapter(ReminderEventModelAdapter());
    }

    remindersBox = await Hive.openBox<ReminderEventModel>(
      AppConstants.remindersBoxName,
    );
    chatBox = await Hive.openBox<String>(AppConstants.chatBoxName);
  }

  static Future<void> dispose() async {
    await chatBox.close();
    await remindersBox.close();
    await Hive.close();
  }
}
