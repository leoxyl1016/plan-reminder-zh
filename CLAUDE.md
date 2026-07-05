# CLAUDE.md

> Codex 接手项目时优先阅读此文件。由 Hermes Agent 在 2026-07-05 整理。

## 项目概览

**Plan-Reminder-zh（提醒助手）** — 基于 Flutter 的中文离线日程助手。

- **原名**：Plan-Reminder（[NnAsankaMadushan/Plan-Reminder](https://github.com/NnAsankaMadushan/Plan-Reminder)，MIT License）
- **中文 Fork**：[leoxyl1016/plan-reminder-zh](https://github.com/leoxyl1016/plan-reminder-zh)
- **上游 remote**：`origin` → `github.com/NnAsankaMadushan/Plan-Reminder.git`
- **Fork remote**：`origin-zh` → `github.com/leoxyl1016/plan-reminder-zh.git`
- **当前分支**：`main`，10 个 commits，工作区干净
- **Flutter SDK**：3.38.5（见 `.github/workflows/build-apk.yml`），Dart SDK `^3.9.2`
- **本地服务器**：无 Flutter 环境，开发在本地 Codex Desktop（SSH 连此服务器），构建靠 GitHub Actions

## 核心功能

| 功能 | 说明 |
|------|------|
| 📝 中文 NLP 解析 | 正则引擎，纯本地，支持中英双语日期/时间/地点提取 |
| 📅 日程管理 | 今天/明天/后天/大后天、周X、下周三、6月15日、下个月3号等 |
| 🎤 语音输入 | `speech_to_text` 插件，需系统语音引擎；推荐用输入法语音代替 |
| 🔔 本地提醒 | `flutter_local_notifications`，日程前 5 分钟提醒 |
| 📴 完全离线 | NLP + 存储 + 通知全本地，无云依赖 |
| 🔗 Google 日历 | 可选 OAuth 同步（默认关闭，需手动授权） |
| 📩 通知拦截 | SMS/微信/Gmail 通知自动解析创建日程（Android） |

## 项目架构

```
lib/
├── main.dart                    # 入口，初始化 intl + ServiceRegistry
├── app.dart                     # MultiBlocProvider → MaterialApp，4 个 BLoC
├── core/
│   ├── constants/app_constants.dart    # appName='提醒助手', 提醒提前量 5min
│   ├── services/
│   │   ├── service_registry.dart        # DI 容器，singleton 初始化所有服务
│   │   ├── hive_service.dart            # Hive 本地 DB 初始化
│   │   ├── notification_service.dart    # flutter_local_notifications 封装
│   │   ├── notification_bridge_service.dart  # 短信/通知拦截 → NLP → 自动保存
│   │   └── voice_input_service.dart     # speech_to_text 封装
│   ├── theme/app_theme.dart             # Material 3 主题
│   └── utils/date_time_extensions.dart  # 日期工具扩展
├── features/
│   ├── app/presentation/pages/app_shell.dart       # 底部导航 + FAB
│   ├── chat/                          # 首页：输入框 + 解析卡片
│   │   ├── presentation/
│   │   │   ├── bloc/chat_bloc.dart    # 核心：接收文本 → 调用 parser → 显示结果
│   │   │   ├── pages/home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── chat_bubble.dart
│   │   │       └── parse_preview_card.dart  # 解析结果卡片（确认/编辑/忽略）
│   │   └── domain/
│   │       ├── entities/chat_message.dart
│   │       └── repositories/chat_repository.dart
│   ├── parser/                        # NLP 解析引擎（核心）
│   │   ├── data/services/local_event_parser_service.dart  # 1132 行，全部解析逻辑
│   │   ├── domain/entities/parsed_event.dart
│   │   └── domain/services/event_parser_service.dart     # 接口定义
│   ├── reminder/                      # 日程 CRUD
│   │   ├── presentation/pages/
│   │   │   ├── add_edit_event_screen.dart
│   │   │   ├── event_detail_screen.dart
│   │   │   └── notification_screen.dart
│   │   ├── data/
│   │   │   ├── datasources/reminder_local_datasource.dart  # Hive 读写
│   │   │   ├── models/reminder_event_model.dart
│   │   │   └── repositories/reminder_repository_impl.dart
│   │   └── domain/entities/reminder_event.dart
│   ├── calendar/                      # 日历视图
│   │   └── presentation/
│   │       ├── bloc/calendar_bloc.dart
│   │       └── pages/calendar_screen.dart
│   ├── google_calendar/               # Google 日历集成
│   │   ├── data/services/google_calendar_service.dart
│   │   └── presentation/
│   └── settings/                      # 设置页
│       └── presentation/pages/settings_screen.dart
```

**架构模式**：Clean Architecture + BLoC 状态管理
- `domain/` → 接口 + 实体
- `data/` → 实现
- `presentation/` → UI + BLoC

## 中文 NLP 解析器详解

入口：`LocalEventParserService.parse(text, reference: DateTime.now())`
返回：`ParsedEvent(title, dateTime, location)`

### 支持的日期模式

| 模式 | 示例 | 实现 |
|------|------|------|
| 相对日 | 今天/明天/后天/大后天/昨天/前天 | `_resolveRelativeDay()` |
| 中文星期 | 周三/下周五/这周六/上周一 | `_weekdayMapZh` + `_weekOffsetZh` + `_resolveWeekday()` |
| 数字月日 | 6月15日、3月5号 | `_dateZhRegex` |
| 年月日 | 2026年8月1日 | `_dateZhRegex` G1-G3 |
| 中文数字月日 | 六月十五日 | `_dateZhCnRegex` |
| 下个月N号 | 下个月3号、明年5月 | `_resolveNextMonthDay()` |
| 下周 | 下周 → 下一个周一 | `_resolveNextWeek()` |
| 下个月/明年 | 不加日期 → 第一个工作日 | `_resolveNextMonth()` / `_resolveNextYear()` |

**关键逻辑：`_resolveNextWeekday()`（「下周X」的正确处理）**
```dart
// rawDiff = targetWeekday - today.weekday
// 如果 rawDiff <= 0，加 7 → 始终指向未来日历周
// 如果 rawDiff > 0 → 直接使用
// 同理「上周X」：rawDiff >= 0 时减 7
```

### 支持的时间模式

| 模式 | 示例 | 实现 |
|------|------|------|
| 12小时制+时段 | 下午3点、上午9点半、晚上8点30分 | `_timeZhRegex` |
| 中文数字时间 | 下午三点半 | `_timeZhCnRegex` |
| 24小时制 | 14时、14时30分 | `_time24ZhRegex` |
| 相对时间 | 半小时后 | `_relativeTimeZhRegex` |
| 无时段点 | "3点" → 默认下午 | `_tryParseTime()` 中的 fallback |

### 支持的地点模式

匹配 "在/于/去/到 + {地点名词} + {地点后缀}" 的模式。
地点后缀包括：教室、教学楼、图书馆、会议室、实验室、食堂、宿舍等 30+ 种。

### 标题提取

去除所有已匹配的日期/时间/地点片段，首句作标题（<= 30 字符）。

## 已修复的关键 Bug

查看 `git log --oneline` 的完整历史。重点：

1. **Dart 正则 `\uXXXX` 兼容性**（`dc13ffc`）：Dart 引擎对 `\uXXXX` 转义序列支持不一致，改为 `\S` 通配符
2. **LocaleDataException**（`4395c9c`）：`main.dart` 需调用 `initializeDateFormatting('zh', null)` 初始化中文 locale
3. **语音静默失败**（`149ffd2`/`14821a1`）：`startListening` 不抛异常但返回错误，需检测 `listen()` 耗时 < 500ms
4. **下周判断错误**（`50c16e2`）：`_resolveNextWeekday()` 修复了「下周X」指向本周的 bug

## 构建与部署

### 本地开发（macOS/Windows）

```bash
git clone https://github.com/leoxyl1016/plan-reminder-zh.git
cd plan-reminder-zh
flutter pub get
flutter run  # 需要 Android 模拟器或真机
```

### CI 构建

推送 `main` 分支自动触发 GitHub Actions（`.github/workflows/build-apk.yml`）：
- `flutter build apk --release --split-per-abi`
- 生成 armeabi-v7a、arm64-v8a、x86_64 三个 APK

### 发布

APK 在 [GitHub Releases](https://github.com/leoxyl1016/plan-reminder-zh/releases) 手动发布。

## 测试

- `test_chinese_nlp.py`：Python 版的 NLP 解析器验证脚本，将 Dart 正则逻辑翻译为 Python 测试，含 28 个测试用例。运行时：`python3 test_chinese_nlp.py`
- Flutter 单元测试：当前无（计划添加 `test/features/parser/` 下的测试）

## 关键依赖

| 包 | 版本 | 用途 |
|---|------|------|
| `flutter_bloc` | ^8.1.6 | 状态管理 |
| `table_calendar` | ^3.1.2 | 日历视图 |
| `flutter_local_notifications` | ^19.4.2 | 本地提醒 |
| `speech_to_text` | ^7.0.0 | 语音识别 |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | 本地数据库 |
| `googleapis` / `google_sign_in` | ^13.2.0 / ^6.2.1 | Google 日历 OAuth |

## 环境约束

- **此服务器**（43.157.55.250）未安装 Flutter SDK，不能本地构建
- 开发在本地 Flutter 环境，代码修改在此服务器上
- **Codex Desktop** 通过 Remote SSH 连接此服务器进行开发
- `_installed_base.apk` 是已知可用的基础版本 APK（gitignored）

## 可能的改进方向（供 Codex 参考）

1. **NLP 增强**：用 ML 模型替代正则引擎（如 TFLite 中文 NER）
2. **通知拦截稳定性**：Android `NotificationListenerService` 在不同厂商 ROM 上的兼容性
3. **UI 优化**：暗色模式自适应、Material You 动态配色
4. **测试覆盖**：添加 Flutter 单元测试、集成测试
5. **iOS 支持**：测试和修复 iOS 平台特定问题（通知权限、语音引擎）
6. **Web 部署**：评估 `flutter build web` 可行性
