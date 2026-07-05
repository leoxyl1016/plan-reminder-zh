import 'package:flutter/material.dart';

import '../../../../core/services/service_registry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onOpenGoogleCalendar,
  });

  final VoidCallback? onOpenGoogleCalendar;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _reminderOffsetMinutes;
  late bool _voiceInputEnabled;
  late bool _autoSaveNotifications;
  late String _voiceLocale;
  late bool _smsInterceptorEnabled;

  @override
  void initState() {
    super.initState();
    _reminderOffsetMinutes = ServiceRegistry.notificationService.reminderOffsetMinutes;
    _voiceInputEnabled = ServiceRegistry.voiceInputService.isEnabled;
    _autoSaveNotifications = ServiceRegistry.notificationBridgeService.autoSave;
    _voiceLocale = ServiceRegistry.voiceInputService.localeId;
    _smsInterceptorEnabled = ServiceRegistry.notificationBridgeService.isInitialized;
  }

  /// Format reminder offset in human-readable Chinese.
  String _formatReminderOffset(int totalMinutes) {
    if (totalMinutes == 0) return '按时提醒';
    final days = totalMinutes ~/ 1440;
    final hours = (totalMinutes % 1440) ~/ 60;
    final mins = totalMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days 天');
    if (hours > 0) parts.add('$hours 小时');
    if (mins > 0) parts.add('$mins 分钟');
    return '提前 ${parts.join(' ')}';
  }

  Future<void> _changeReminderOffset() async {
    // Preset options in minutes, covering minute / hour / day ranges
    final presetOptions = <int>[
      0,     // 按时提醒
      5,     // 5 分钟
      10,    // 10 分钟
      15,    // 15 分钟
      30,    // 30 分钟
      60,    // 1 小时
      120,   // 2 小时
      360,   // 6 小时
      720,   // 12 小时
      1440,  // 1 天
      2880,  // 2 天
      4320,  // 3 天
      10080, // 1 周
    ];

    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('提醒提前量', style: theme.textTheme.titleMedium),
                subtitle: const Text('在日程开始前多久发送提醒'),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    ...presetOptions.map(
                      (int minutes) => RadioListTile<int>(
                        value: minutes,
                        groupValue: _reminderOffsetMinutes,
                        title: Text(_formatReminderOffset(minutes)),
                        onChanged: (int? value) {
                          Navigator.of(context).pop(value);
                        },
                      ),
                    ),
                    // Custom input option
                    RadioListTile<int>(
                      value: -1,
                      groupValue: _reminderOffsetMinutes,
                      title: const Text(
                        '自定义（输入分钟数）…',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      onChanged: (int? _) async {
                        Navigator.of(context).pop(); // dismiss picker first
                        final custom = await _showCustomOffsetDialog();
                        if (custom != null) {
                          ServiceRegistry.notificationService
                              .setReminderOffsetMinutes(custom);
                          if (!mounted) return;
                          setState(() {
                            _reminderOffsetMinutes = custom;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == -1) return;

    ServiceRegistry.notificationService.setReminderOffsetMinutes(selected);
    setState(() {
      _reminderOffsetMinutes = selected;
    });
  }

  /// Show a dialog for entering a custom offset in minutes.
  Future<int?> _showCustomOffsetDialog() async {
    final controller = TextEditingController(
      text: _reminderOffsetMinutes > 0
          ? _reminderOffsetMinutes.toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('自定义提醒提前量'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '分钟数',
                hintText: '例如：90（1.5 小时）、1440（1 天）',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入分钟数';
                }
                final v = int.tryParse(value.trim());
                if (v == null || v < 0) {
                  return '请输入有效的非负整数';
                }
                if (v > 43200) {
                  return '最多提前 30 天（43200 分钟）';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context)
                      .pop(int.parse(controller.text.trim()));
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _setVoiceInputEnabled(bool enabled) async {
    await ServiceRegistry.voiceInputService.setEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _voiceInputEnabled = enabled;
    });
  }

  Future<void> _setVoiceLocale(String locale) async {
    await ServiceRegistry.voiceInputService.setLocale(locale);
    if (!mounted) return;
    setState(() {
      _voiceLocale = locale;
    });
  }

  void _setAutoSaveNotifications(bool value) {
    ServiceRegistry.notificationBridgeService.autoSave = value;
    setState(() {
      _autoSaveNotifications = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        children: <Widget>[
          _HeaderCard(
            reminderOffsetText: _formatReminderOffset(_reminderOffsetMinutes),
            voiceInputEnabled: _voiceInputEnabled,
            notificationAutoSave: _autoSaveNotifications,
          ),
          const SizedBox(height: 12),
          Text('通用设置', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                _SettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: '提醒提前量',
                  subtitle: _formatReminderOffset(_reminderOffsetMinutes),
                  onTap: _changeReminderOffset,
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.mic_none_outlined,
                  title: '语音输入',
                  subtitle: _voiceInputEnabled ? '已启用' : '已禁用',
                  onTap: () => _setVoiceInputEnabled(!_voiceInputEnabled),
                  trailing: Switch(
                    value: _voiceInputEnabled,
                    onChanged: _setVoiceInputEnabled,
                  ),
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.language_outlined,
                  title: '语音识别语言',
                  subtitle: _voiceLocaleLabel(_voiceLocale),
                  onTap: () => _showVoiceLocalePicker(),
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.event_outlined,
                  title: 'Google 日历',
                  subtitle: '打开日历同步页面',
                  onTap: widget.onOpenGoogleCalendar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('智能通知识别', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                _SettingTile(
                  icon: Icons.auto_awesome_outlined,
                  title: '自动识别通知中的日程',
                  subtitle: _autoSaveNotifications
                      ? '收到短信/微信/邮件通知时自动解析并保存日程'
                      : '仅手动输入',
                  onTap: () => _setAutoSaveNotifications(!_autoSaveNotifications),
                  trailing: Switch(
                    value: _autoSaveNotifications,
                    onChanged: _setAutoSaveNotifications,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ 通知监听需要在系统「设置 → 无障碍 → 已安装的服务」中手动开启「Reminder Buddy」，'
                          '短信拦截需要授予短信权限。开启后会自动识别微信、短信、Gmail 等通知中的日程信息。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('关于', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Reminder Buddy (中文版)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    '离线 NLP + 本地通知 + 中文语音识别 + 短信/通知自动解析\n'
                    '可选 Google 日历同步。\n'
                    '原项目: NnAsankaMadushan/Plan-Reminder\n'
                    '中文适配: 支持中英文混合 NLP 解析',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _voiceLocaleLabel(String locale) {
    if (locale.isEmpty) return '跟随系统（自动检测）';
    // Show BCP-47 tag + friendly name
    final friendly = _friendlyLocaleName(locale);
    return friendly != locale ? '$friendly ($locale)' : locale;
  }

  String _friendlyLocaleName(String locale) {
    final lang = locale.split('-').first.split('_').first;
    switch (lang) {
      case 'zh': return '中文';
      case 'en': return 'English';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'es': return 'Español';
      default: return locale;
    }
  }

  void _showVoiceLocalePicker() {
    // Use available locales from the device, fall back to common ones
    final availableLocales = ServiceRegistry.voiceInputService.availableLocales;

    final Map<String, String> localeMap;

    if (availableLocales.isNotEmpty) {
      localeMap = {
        for (final l in availableLocales) l.localeId: _friendlyLocaleName(l.localeId),
      };
      // Always add "follow system"
      localeMap[''] = '跟随系统';
    } else {
      // Fallback: common Chinese locales
      localeMap = {
        'zh-CN': '中文（普通话）',
        'zh-TW': '中文（台湾）',
        'zh-HK': '中文（粤语）',
        'zh': '中文',
        'en-US': 'English (US)',
        '': '跟随系统',
      };
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('语音识别语言', style: theme.textTheme.titleMedium),
                subtitle: const Text('选择语音输入时使用的识别语言'),
              ),
              ...localeMap.entries.map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: _voiceLocale,
                  title: Text(entry.value),
                  onChanged: (String? value) {
                    Navigator.of(context).pop();
                    if (value != null) _setVoiceLocale(value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.reminderOffsetText,
    required this.voiceInputEnabled,
    required this.notificationAutoSave,
  });

  final String reminderOffsetText;
  final bool voiceInputEnabled;
  final bool notificationAutoSave;

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
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('应用偏好', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '当前提醒: $reminderOffsetText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              _Chip(
                label: voiceInputEnabled ? '语音已开启' : '语音已关闭',
                active: voiceInputEnabled,
                theme: theme,
              ),
              _Chip(
                label: notificationAutoSave ? '智能识别已开启' : '智能识别已关闭',
                active: notificationAutoSave,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.theme,
  });

  final String label;
  final bool active;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surface.withValues(alpha: 0.85),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: active ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
