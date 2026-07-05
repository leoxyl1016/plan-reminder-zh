import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../google_calendar/domain/entities/google_calendar_event.dart';
import '../../../google_calendar/presentation/bloc/google_calendar_bloc.dart';
import '../../../reminder/domain/entities/reminder_event.dart';
import '../bloc/calendar_bloc.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.onEventTap,
  });

  final ValueChanged<ReminderEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listenWhen: (CalendarState previous, CalendarState current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (BuildContext context, CalendarState state) {
        if (state.errorMessage == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      },
      builder: (BuildContext context, CalendarState state) {
        return BlocBuilder<GoogleCalendarBloc, GoogleCalendarState>(
          builder:
              (BuildContext context, GoogleCalendarState googleCalendarState) {
            final theme = Theme.of(context);
            final googleEvents = googleCalendarState.isConnected
                ? googleCalendarState.events
                : const <GoogleCalendarEvent>[];
            final selectedItems = _selectedItemsForDay(
              selectedDay: state.selectedDay,
              reminderEvents: state.events,
              googleEvents: googleEvents,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                        child: TableCalendar<Object>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: state.focusedDay,
                          eventLoader: (DateTime day) => <Object>[
                            ..._eventsForDay(day, state.events),
                            ..._googleEventsForDay(day, googleEvents),
                          ],
                          selectedDayPredicate: (DateTime day) =>
                              day.dateOnly == state.selectedDay.dateOnly,
                          onDaySelected:
                              (DateTime selectedDay, DateTime focusedDay) {
                            context.read<CalendarBloc>().add(
                                  CalendarDaySelected(
                                    selectedDay: selectedDay,
                                    focusedDay: focusedDay,
                                  ),
                                );
                          },
                          calendarFormat: CalendarFormat.month,
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: theme.colorScheme.primary,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.primary,
                            ),
                            titleTextStyle: theme.textTheme.titleMedium!,
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            selectedDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                            todayDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                            ),
                            markersMaxCount: 3,
                            markerDecoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: theme.textTheme.labelLarge!,
                            weekendStyle: theme.textTheme.labelLarge!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Text(
                          '日程',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          ),
                          child: Text('${selectedItems.length}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: selectedItems.isEmpty
                            ? const Center(
                                key: ValueKey<String>('empty'),
                                child: Text('当天无日程'),
                              )
                            : ListView.separated(
                                key: ValueKey<String>(
                                  'events_${state.selectedDay.toIso8601String()}',
                                ),
                                padding: const EdgeInsets.only(bottom: 6),
                                itemCount: selectedItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (BuildContext context, int index) {
                                  final item = selectedItems[index];
                                  return _CalendarEventCard(
                                    item: item,
                                    onTap: item.reminderEvent == null
                                        ? null
                                        : () => onEventTap(item.reminderEvent!),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<ReminderEvent> _eventsForDay(
    DateTime day,
    List<ReminderEvent> allEvents,
  ) {
    return allEvents
        .where((ReminderEvent event) => event.dateTime.dateOnly == day.dateOnly)
        .toList();
  }

  List<GoogleCalendarEvent> _googleEventsForDay(
    DateTime day,
    List<GoogleCalendarEvent> allEvents,
  ) {
    return allEvents
        .where((GoogleCalendarEvent event) => event.start.dateOnly == day.dateOnly)
        .toList();
  }

  List<_CalendarEventItem> _selectedItemsForDay({
    required DateTime selectedDay,
    required List<ReminderEvent> reminderEvents,
    required List<GoogleCalendarEvent> googleEvents,
  }) {
    final items = <_CalendarEventItem>[
      ..._eventsForDay(selectedDay, reminderEvents).map(
        (ReminderEvent event) => _CalendarEventItem.reminder(event),
      ),
      ..._googleEventsForDay(selectedDay, googleEvents).map(
        (GoogleCalendarEvent event) => _CalendarEventItem.google(event),
      ),
    ];

    items.sort(
      (_CalendarEventItem a, _CalendarEventItem b) {
        if (a.isAllDay != b.isAllDay) {
          return a.isAllDay ? -1 : 1;
        }
        return a.start.compareTo(b.start);
      },
    );

    return items;
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.item,
    required this.onTap,
  });

  final _CalendarEventItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoogle = item.source == _CalendarEventSource.google;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface.withValues(alpha: 0.93),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (isGoogle
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.14),
                ),
                child: Icon(
                  isGoogle
                      ? Icons.event_available_outlined
                      : Icons.event_note_outlined,
                  color: isGoogle
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      item.timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (item.location?.trim().isNotEmpty == true)
                      Text(
                        item.location!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  item.sourceLabel,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CalendarEventSource { reminder, google }

class _CalendarEventItem {
  const _CalendarEventItem._({
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.isAllDay,
    required this.source,
    this.reminderEvent,
  });

  factory _CalendarEventItem.reminder(ReminderEvent event) {
    return _CalendarEventItem._(
      title: event.title,
      start: event.dateTime,
      end: null,
      location: event.location,
      isAllDay: false,
      source: _CalendarEventSource.reminder,
      reminderEvent: event,
    );
  }

  factory _CalendarEventItem.google(GoogleCalendarEvent event) {
    return _CalendarEventItem._(
      title: event.title,
      start: event.start,
      end: event.end,
      location: event.location,
      isAllDay: event.isAllDay,
      source: _CalendarEventSource.google,
    );
  }

  final String title;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final bool isAllDay;
  final _CalendarEventSource source;
  final ReminderEvent? reminderEvent;

  String get timeLabel {
    if (isAllDay) {
      return '全天';
    }

    if (end == null) {
      return start.toTimeLabel;
    }

    return '${start.toTimeLabel} - ${end!.toTimeLabel}';
  }

  String get sourceLabel =>
      source == _CalendarEventSource.google ? 'Google 日历' : '本地提醒';
}
