# Plan-Reminder-zh（提醒助手 中文版）

基于 [NnAsankaMadushan/Plan-Reminder](https://github.com/NnAsankaMadushan/Plan-Reminder) 改造的中文离线日程助手。

## 功能

- 📝 **中文 NLP 日程解析**：输入「明天下午3点在图书馆开会」自动拆出标题、日期、时间、地点
- 📅 **支持模式**：今天/明天/后天/大后天、下周三/这周五、6月15日、下午3点/上午9点半、下周/下个月/明年、下个月3号
- 🎤 **语音输入**：推荐使用手机输入法自带的语音输入（讯飞/Google 语音输入），在键盘上点麦克风按钮说话即可。**APP 内置的语音按钮需要手机已安装语音识别引擎才能工作**，否则点击无反应。
- 🔔 **本地提醒**：日程前发送通知
- 📴 **完全离线**：NLP 解析、数据存储、通知提醒全程本地，无需网络
- 🔗 **Google 日历同步**（可选）：需手动 OAuth 授权连接

## 🔒 隐私与安全

| 数据 | 存储位置 | 是否上传 |
|------|---------|---------|
| 日程内容 | 手机本地 Hive 数据库 | ❌ 不上传 |
| 短信/通知原文 | 手机本地 | ❌ 不上传（需在系统设置中手动开启通知监听） |
| NLP 解析 | 纯本地正则引擎 | ❌ 无网络调用 |
| 语音识别 | 系统语音引擎 | ⚠️ 取决于手机语音引擎（讯飞离线 / Google 云端） |
| Google 日历同步 | 用户主动 OAuth 授权后 | ⚠️ 日程标题+时间+地点上传到 Google |

- ✅ 无 Firebase Analytics / Crashlytics / 任何遥测 SDK
- ✅ 无硬编码 API 密钥
- ✅ Google 日历同步默认关闭
- ⚠️ Google Fonts 启动时从 CDN 下载字体（仅 IP 暴露，无用户数据）

## 安装

下载 [Releases](https://github.com/leoxyl1016/plan-reminder-zh/releases) 中的 APK 安装。

安装后：
1. 如需短信/通知自动识别：系统设置 → 无障碍 → 已安装的服务 → 开启「Reminder Buddy」
2. 语音输入：推荐使用手机输入法的语音功能，无需额外配置

## 技术栈

- Flutter / Dart
- Clean Architecture + BLoC
- speech_to_text（语音）
- Hive（本地存储）
- Google Calendar API（可选）

## License

MIT
