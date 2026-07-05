import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../parser/domain/entities/parsed_event.dart';

class ParsePreviewCard extends StatelessWidget {
  const ParsePreviewCard({
    super.key,
    required this.parsedEvent,
    required this.onConfirm,
    required this.onEdit,
    required this.onDismiss,
  });

  final ParsedEvent parsedEvent;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('解析结果', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
                tooltip: '忽略',
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoChip(
                icon: Icons.title,
                label: parsedEvent.title,
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: parsedEvent.dateTime.toDateLabel,
              ),
              _InfoChip(
                icon: Icons.access_time,
                label: parsedEvent.dateTime.toTimeLabel,
              ),
              _InfoChip(
                icon: Icons.location_on_outlined,
                label: parsedEvent.location ?? '未设置地点',
              ),
            ],
          ),
          if (!parsedEvent.hasExplicitTime)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '时间不明确，请确认或编辑后保存',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: warningColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('确认'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
