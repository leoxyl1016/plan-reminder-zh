import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/services/service_registry.dart';
import 'core/theme/app_theme.dart';
import 'features/app/presentation/pages/app_shell.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/google_calendar/presentation/bloc/google_calendar_bloc.dart';
import 'features/reminder/presentation/bloc/reminder_bloc.dart';

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<CalendarBloc>(
          create: (_) => CalendarBloc(
            reminderRepository: ServiceRegistry.reminderRepository,
            reminderSchedulingService:
                ServiceRegistry.reminderSchedulingService,
          ),
        ),
        BlocProvider<ReminderBloc>(
          create: (_) => ReminderBloc(
            reminderSchedulingService:
                ServiceRegistry.reminderSchedulingService,
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(
            parserService: ServiceRegistry.parserService,
            chatRepository: ServiceRegistry.chatRepository,
            voiceInputService: ServiceRegistry.voiceInputService,
          ),
        ),
        BlocProvider<GoogleCalendarBloc>(
          create: (_) => GoogleCalendarBloc(
            calendarService: ServiceRegistry.googleCalendarService,
          )..add(const GoogleCalendarStarted()),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: const AppShell(),
      ),
    );
  }
}
