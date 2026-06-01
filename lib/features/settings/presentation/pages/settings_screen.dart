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

  Future<void> _changeReminderOffset() async {
    final options = <int>[0, 5, 10, 15, 30, 60];
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
              ...options.map(
                (int minutes) => RadioListTile<int>(
                  value: minutes,
                  groupValue: _reminderOffsetMinutes,
                  title: Text(
                    minutes == 0 ? '按时提醒' : '提前 $minutes 分钟',
                  ),
                  onChanged: (int? value) {
                    Navigator.of(context).pop(value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    ServiceRegistry.notificationService.setReminderOffsetMinutes(selected);
    setState(() {
      _reminderOffsetMinutes = selected;
    });
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
            reminderOffsetMinutes: _reminderOffsetMinutes,
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
                  subtitle: _reminderOffsetMinutes == 0
                      ? '按时提醒（当前）'
                      : '提前 $_reminderOffsetMinutes 分钟（当前）',
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
    switch (locale) {
      case 'zh_CN':
        return '中文（普通话）';
      case 'zh_TW':
        return '中文（台湾）';
      case 'zh_HK':
        return '中文（粤语）';
      case 'en_US':
        return 'English (US)';
      case 'ja_JP':
        return '日本語';
      case '':
        return '跟随系统';
      default:
        return locale;
    }
  }

  void _showVoiceLocalePicker() {
    final locales = <String, String>{
      'zh_CN': '中文（普通话）',
      'zh_TW': '中文（台湾）',
      'zh_HK': '中文（粤语）',
      'en_US': 'English (US)',
      'ja_JP': '日本語',
      '': '跟随系统',
    };

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
              ...locales.entries.map(
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
    required this.reminderOffsetMinutes,
    required this.voiceInputEnabled,
    required this.notificationAutoSave,
  });

  final int reminderOffsetMinutes;
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
            '当前提醒: ${reminderOffsetMinutes == 0 ? '按时提醒' : '提前 $reminderOffsetMinutes 分钟'}',
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
