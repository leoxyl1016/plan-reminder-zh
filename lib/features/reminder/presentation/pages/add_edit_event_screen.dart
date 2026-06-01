import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../parser/domain/entities/parsed_event.dart';
import '../../domain/entities/reminder_event.dart';

class AddEditEventScreen extends StatefulWidget {
  const AddEditEventScreen({
    super.key,
    this.initialEvent,
    this.parsedEvent,
  });

  final ReminderEvent? initialEvent;
  final ParsedEvent? parsedEvent;

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final Uuid _uuid = const Uuid();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool get _isEditMode => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();

    final baseDateTime = widget.initialEvent?.dateTime ??
        widget.parsedEvent?.dateTime ??
        DateTime.now().add(const Duration(hours: 1));

    _selectedDate = baseDateTime.dateOnly;
    _selectedTime = TimeOfDay.fromDateTime(baseDateTime);

    _titleController.text =
        widget.initialEvent?.title ?? widget.parsedEvent?.title ?? '';
    _locationController.text =
        widget.initialEvent?.location ?? widget.parsedEvent?.location ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate.dateOnly;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final location = _locationController.text.trim();
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = ReminderEvent(
      id: widget.initialEvent?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      dateTime: dateTime,
      location: location.isEmpty ? null : location,
      createdAt: widget.initialEvent?.createdAt ?? DateTime.now(),
      sourceText: widget.initialEvent?.sourceText ?? widget.parsedEvent?.sourceText,
    );

    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑日程' : '添加日程'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DateTimeHeader(
                  dateLabel: _selectedDate.toDateLabel,
                  timeLabel: _selectedTime.format(context),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('详细信息', style: textTheme.titleMedium),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '标题',
                            hintText: '与 Sarah 的会议',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return '标题为必填项。';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: '地点（可选）',
                            hintText: '办公室、Zoom、咖啡馆',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SelectionTile(
                        icon: Icons.calendar_today_outlined,
                        label: '日期',
                        value: _selectedDate.toDateLabel,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SelectionTile(
                        icon: Icons.access_time_outlined,
                        label: '时间',
                        value: _selectedTime.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                if (widget.parsedEvent != null && !widget.parsedEvent!.hasExplicitTime)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '未能从消息中检测到时间，请在保存前确认。',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(_isEditMode ? '保存更改' : '创建日程'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeHeader extends StatelessWidget {
  const _DateTimeHeader({
    required this.dateLabel,
    required this.timeLabel,
  });

  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
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
          Text('日程安排', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '$dateLabel $timeLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: theme.textTheme.labelLarge),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
