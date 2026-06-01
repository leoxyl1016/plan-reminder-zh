import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../domain/entities/reminder_event.dart';
import '../bloc/reminder_bloc.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({
    super.key,
    required this.onEventTap,
  });

  final ValueChanged<ReminderEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (BuildContext context, CalendarState state) {
        final theme = Theme.of(context);
        final now = DateTime.now();
        final upcoming = <ReminderEvent>[];
        final history = <ReminderEvent>[];

        for (final event in state.events) {
          final reminderTime = event.dateTime.subtract(
            const Duration(minutes: AppConstants.reminderOffsetMinutes),
          );

          if (reminderTime.isAfter(now)) {
            upcoming.add(event);
          } else {
            history.add(event);
          }
        }

        upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        history.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: <Widget>[
              _NotificationSummary(
                nextReminder: upcoming.isEmpty ? null : upcoming.first,
                upcomingCount: upcoming.length,
                historyCount: history.length,
              ),
              const SizedBox(height: 12),
              _SectionHeader(
                title: '待通知日程',
                count: upcoming.length,
              ),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                const _EmptySection(
                  message: '暂无待提醒的日程',
                )
              else
                ...upcoming.map(
                  (event) => _NotificationCard(
                    event: event,
                    isHistory: false,
                    onTap: () => onEventTap(event),
                  ),
                ),
              const SizedBox(height: 14),
              _SectionHeader(
                title: '通知记录',
                count: history.length,
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const _EmptySection(
                  message: '提醒时间过后将显示历史记录',
                )
              else
                ...history.map(
                  (event) => _NotificationCard(
                    event: event,
                    isHistory: true,
                    onTap: () => onEventTap(event),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '默认在日程开始前 ${AppConstants.reminderOffsetMinutes} 分钟发送提醒。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.nextReminder,
    required this.upcomingCount,
    required this.historyCount,
  });

  final ReminderEvent? nextReminder;
  final int upcomingCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('提醒概览', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            nextReminder == null
                ? '暂无待通知'
                : '下一个: ${nextReminder!.title} @ ${nextReminder!.dateTime.toDateTimeLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _CountPill(label: '待通知', value: upcomingCount),
              const SizedBox(width: 8),
              _CountPill(label: '历史', value: historyCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('$count'),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(message),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.event,
    required this.isHistory,
    required this.onTap,
  });

  final ReminderEvent event;
  final bool isHistory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reminderTime = event.dateTime.subtract(
      const Duration(minutes: AppConstants.reminderOffsetMinutes),
    );
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.primary.withValues(alpha: isHistory ? 0.1 : 0.16),
          ),
          child: Icon(
            isHistory ? Icons.notifications_none : Icons.notifications_active_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(event.title),
        subtitle: Text(
          '提醒时间: ${reminderTime.toDateTimeLabel}\n'
          '日程时间: ${event.dateTime.toDateTimeLabel}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'cancel') {
              context
                  .read<ReminderBloc>()
                  .add(ReminderCancelRequested(event.id));
              return;
            }
            if (value == 'reschedule') {
              context
                  .read<ReminderBloc>()
                  .add(ReminderRescheduleRequested(event));
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'reschedule',
              child: Text('重新调度'),
            ),
            PopupMenuItem<String>(
              value: 'cancel',
              child: Text('取消提醒'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text('$label: $value', style: theme.textTheme.labelLarge),
    );
  }
}
