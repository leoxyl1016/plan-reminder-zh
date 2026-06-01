import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/entities/google_calendar_event.dart';
import '../bloc/google_calendar_bloc.dart';

class GoogleCalendarScreen extends StatefulWidget {
  const GoogleCalendarScreen({super.key});

  @override
  State<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends State<GoogleCalendarScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GoogleCalendarBloc>().add(const GoogleCalendarStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoogleCalendarBloc, GoogleCalendarState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (BuildContext context, GoogleCalendarState state) {
        final theme = Theme.of(context);
        final groupedEvents = _groupEventsByDate(state.events);
        final sortedDates = groupedEvents.keys.toList()
          ..sort((DateTime a, DateTime b) => a.compareTo(b));

        if (state.status == GoogleCalendarStatus.loading &&
            state.events.isEmpty &&
            !state.isConnected) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.isConnected) {
          return _DisconnectedView(
            onConnect: () {
              context
                  .read<GoogleCalendarBloc>()
                  .add(const GoogleCalendarConnectRequested());
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<GoogleCalendarBloc>()
                .add(const GoogleCalendarRefreshRequested());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: <Widget>[
              _ConnectedHeader(
                email: state.email ?? 'Connected',
                isLoading: state.status == GoogleCalendarStatus.loading,
                eventCount: state.events.length,
                onRefresh: () {
                  context
                      .read<GoogleCalendarBloc>()
                      .add(const GoogleCalendarRefreshRequested());
                },
                onDisconnect: () {
                  context
                      .read<GoogleCalendarBloc>()
                      .add(const GoogleCalendarDisconnectRequested());
                },
              ),
              const SizedBox(height: 12),
              Text(
                '近期日程',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (state.events.isEmpty)
                const _EmptyEventsCard()
              else
                ...<Widget>[
                  for (final date in sortedDates) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                      child: Text(
                        date.toDateLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    ...groupedEvents[date]!.map(
                      (GoogleCalendarEvent event) => _GoogleCalendarEventCard(
                        event: event,
                      ),
                    ),
                  ],
                ],
            ],
          ),
        );
      },
    );
  }

  Map<DateTime, List<GoogleCalendarEvent>> _groupEventsByDate(
    List<GoogleCalendarEvent> events,
  ) {
    final grouped = <DateTime, List<GoogleCalendarEvent>>{};

    for (final event in events) {
      final date = event.start.dateOnly;
      grouped.putIfAbsent(date, () => <GoogleCalendarEvent>[]).add(event);
    }

    for (final dateEvents in grouped.values) {
      dateEvents.sort(
        (GoogleCalendarEvent a, GoogleCalendarEvent b) =>
            a.start.compareTo(b.start),
      );
    }

    return grouped;
  }
}

class _GoogleCalendarEventCard extends StatelessWidget {
  const _GoogleCalendarEventCard({required this.event});

  final GoogleCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.tertiary.withValues(alpha: 0.14),
          ),
          child: Icon(
            event.isAllDay
                ? Icons.calendar_today_outlined
                : Icons.event_available_outlined,
            color: theme.colorScheme.tertiary,
            size: 18,
          ),
        ),
        title: Text(event.title),
        subtitle: Text(_timeLabel(event)),
        trailing: event.location?.trim().isNotEmpty == true
            ? SizedBox(
                width: 120,
                child: Text(
                  event.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              )
            : null,
      ),
    );
  }

  String _timeLabel(GoogleCalendarEvent event) {
    if (event.isAllDay) {
      return '全天';
    }

    if (event.end == null) {
      return event.start.toTimeLabel;
    }

    return '${event.start.toTimeLabel} - ${event.end!.toTimeLabel}';
  }
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: <Color>[
                  theme.colorScheme.tertiary.withValues(alpha: 0.12),
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.calendar_month_rounded,
                  size: 34,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  '连接 Google 日历',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '在此应用中直接查看 Google 日历的近期日程。',
                ),
                const SizedBox(height: 6),
                Text(
                  '本地日程解析保持离线运行。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onConnect,
                  icon: const Icon(Icons.link),
                  label: const Text('连接 Google 日历'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectedHeader extends StatelessWidget {
  const _ConnectedHeader({
    required this.email,
    required this.isLoading,
    required this.eventCount,
    required this.onRefresh,
    required this.onDisconnect,
  });

  final String email;
  final bool isLoading;
  final int eventCount;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.tertiary.withValues(alpha: 0.12),
            theme.colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('已连接', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(email, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '$eventCount 条日程已加载',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: isLoading ? null : onDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('断开连接'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: const Text('暂无 Google 日历日程'),
    );
  }
}
