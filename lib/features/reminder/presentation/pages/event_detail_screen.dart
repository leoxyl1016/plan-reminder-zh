import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../domain/entities/reminder_event.dart';
import 'add_edit_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  final ReminderEvent event;

  Future<void> _editEvent(BuildContext context) async {
    final updatedEvent = await Navigator.of(context).push<ReminderEvent>(
      MaterialPageRoute<ReminderEvent>(
        builder: (_) => AddEditEventScreen(initialEvent: event),
      ),
    );

    if (updatedEvent == null || !context.mounted) {
      return;
    }

    context.read<CalendarBloc>().add(CalendarEventSaved(updatedEvent));
    Navigator.of(context).pop();
  }

  Future<void> _deleteEvent(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除日程'),
          content: const Text('此日程及其提醒将被删除。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    context.read<CalendarBloc>().add(CalendarEventDeleted(event.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('日程详情')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: <Color>[
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                      theme.colorScheme.tertiary.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(event.title, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${event.dateTime.toDateLabel} ${event.dateTime.toTimeLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: '日期',
                value: event.dateTime.toDateLabel,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.access_time_outlined,
                label: '时间',
                value: event.dateTime.toTimeLabel,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: '地点',
                value: event.location ?? '未设置',
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.history_toggle_off_outlined,
                label: '创建时间',
                value: event.createdAt.toDateTimeLabel,
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _editEvent(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('编辑'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteEvent(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
