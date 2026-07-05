import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/pages/calendar_screen.dart';
import '../../../chat/presentation/pages/home_screen.dart';
import '../../../google_calendar/presentation/pages/google_calendar_screen.dart';
import '../../../reminder/domain/entities/reminder_event.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../../../reminder/presentation/pages/add_edit_event_screen.dart';
import '../../../reminder/presentation/pages/event_detail_screen.dart';
import '../../../reminder/presentation/pages/notification_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Future<void> _addManualEvent() async {
    final reminderEvent = await Navigator.of(context).push<ReminderEvent>(
      MaterialPageRoute<ReminderEvent>(
        builder: (_) => const AddEditEventScreen(),
      ),
    );

    if (reminderEvent == null || !mounted) {
      return;
    }

    context.read<CalendarBloc>().add(CalendarEventSaved(reminderEvent));
  }

  void _openEventDetails(ReminderEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        title: '提醒助手',
        subtitle: '用自然语言创建日程提醒',
      ),
      const _ShellDestination(
        title: '日历',
        subtitle: '一览整日日程',
      ),
      const _ShellDestination(
        title: '通知',
        subtitle: '提醒活动记录',
      ),
      const _ShellDestination(
        title: 'Google 日历',
        subtitle: '已连接外部日历',
      ),
      const _ShellDestination(
        title: '设置',
        subtitle: '调整行为与集成',
      ),
    ];

    final page = switch (_selectedIndex) {
      0 => const HomeScreen(key: ValueKey<String>('home_page')),
      1 => CalendarScreen(
          key: const ValueKey<String>('calendar_page'),
          onEventTap: _openEventDetails,
        ),
      2 => NotificationScreen(
          key: const ValueKey<String>('notifications_page'),
          onEventTap: _openEventDetails,
        ),
      3 => const GoogleCalendarScreen(
          key: ValueKey<String>('google_calendar_page'),
        ),
      _ => SettingsScreen(
          key: const ValueKey<String>('settings_page'),
          onOpenGoogleCalendar: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
        ),
    };
    final destination = destinations[_selectedIndex];
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CalendarBloc, CalendarState>(
          listenWhen: (CalendarState previous, CalendarState current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (BuildContext context, CalendarState state) {
            if (_selectedIndex == 1) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          },
        ),
        BlocListener<ReminderBloc, ReminderState>(
          listenWhen: (ReminderState previous, ReminderState current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (BuildContext context, ReminderState state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          titleSpacing: 18,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(destination.title),
              const SizedBox(height: 1),
              Text(
                destination.subtitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFFEAF4FF),
                      theme.colorScheme.surface,
                      const Color(0xFFF8F7EF),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -86,
              right: -58,
              child: _GlowOrb(
                size: 220,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -70,
              child: _GlowOrb(
                size: 240,
                color: theme.colorScheme.secondary.withValues(alpha: 0.13),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: page,
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1
            ? TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (_, double value, Widget? child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: FloatingActionButton.extended(
                  onPressed: _addManualEvent,
                  label: const Text('添加日程'),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              )
            : null,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: '日历',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: '通知',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event),
                  label: 'Google',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0.04)],
          ),
        ),
      ),
    );
  }
}
