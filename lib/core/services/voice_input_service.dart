import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isEnabled = true;
  VoidCallback? _activeOnDone;

  /// Currently active locale. Defaults to auto-detect.
  String _localeId = '';

  /// List of locales we prefer for Chinese recognition (in priority order)
  static const _chineseLocales = <String>[
    'zh-CN',   // BCP-47 for Android
    'zh_CN',   // iOS format
    'zh-Hans', // Simplified Chinese
    'zh-Hant', // Traditional Chinese
    'zh-TW',
    'zh_HK',
    'zh',      // Generic Chinese fallback
  ];

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _isEnabled;
  String get localeId => _localeId;

  /// List of available locales on this device (populated after initialization)
  List<LocaleName> availableLocales = [];

  /// Set the speech recognition locale.
  Future<void> setLocale(String localeId) async {
    _localeId = localeId;
    if (_isInitialized) {
      _isInitialized = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) {
      await cancelListening();
    }
  }

  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isEnabled) {
      throw const VoiceInputException('语音输入已在设置中关闭');
    }

    await _initializeIfNeeded();
    _activeOnDone = onDone;

    // Determine the best locale
    final effectiveLocale = _resolveBestLocale();

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _completeSession();
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      localeId: effectiveLocale,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  Future<void> stopListening() async {
    _activeOnDone = null;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<void> cancelListening() async {
    _activeOnDone = null;
    await _speechToText.cancel();
  }

  Future<void> _initializeIfNeeded() async {
    if (_isInitialized) {
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (String status) {
        debugPrint('VoiceInput status: $status');
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _completeSession();
        }
      },
      onError: (_) {
        debugPrint('VoiceInput error');
        _completeSession();
      },
    );

    if (!available) {
      throw const VoiceInputException(
        '语音识别不可用。请确认：\n'
        '1. 已授予麦克风权限\n'
        '2. 手机已安装 Google 或讯飞语音服务\n'
        '（部分国产手机需手动安装 Google 语音服务）',
      );
    }

    // Fetch available locales
    try {
      availableLocales = await _speechToText.locales();
      debugPrint(
        'VoiceInput: ${availableLocales.length} locales available',
      );
    } catch (_) {
      availableLocales = [];
    }

    _isInitialized = true;
  }

  /// Find the best Chinese locale available on this device.
  /// Falls back to device default if no Chinese locale found.
  String? _resolveBestLocale() {
    // If user explicitly set a locale, try it first
    if (_localeId.isNotEmpty) {
      // Try exact match
      if (availableLocales.isEmpty ||
          availableLocales.any((l) => l.localeId == _localeId)) {
        return _localeId;
      }
      // Try matching just the language part
      final langPart = _localeId.split('-').first.split('_').first;
      final match = _findLocaleByLanguage(langPart);
      if (match != null) return match;
    }

    // Auto-detect: try Chinese locales in priority order
    for (final locale in _chineseLocales) {
      if (_findLocaleByLanguage(locale.split('-').first.split('_').first) != null) {
        final match = availableLocales.firstWhere(
          (l) => l.localeId == locale,
          orElse: () => availableLocales.firstWhere(
            (l) => l.localeId.startsWith('${locale.split('-').first}_') ||
                l.localeId.startsWith('${locale.split('-').first}-'),
            orElse: () => LocaleName('', ''),
          ),
        );
        if (match.localeId.isNotEmpty) {
          debugPrint('VoiceInput: using locale ${match.localeId}');
          return match.localeId;
        }
      }
    }

    // No Chinese locale found — let platform decide
    debugPrint('VoiceInput: no Chinese locale found, using device default');
    return null;
  }

  String? _findLocaleByLanguage(String lang) {
    try {
      final match = availableLocales.firstWhere(
        (l) => l.localeId.startsWith('$lang-') || l.localeId.startsWith('${lang}_'),
      );
      return match.localeId;
    } catch (_) {
      return null;
    }
  }

  void _completeSession() {
    final onDone = _activeOnDone;
    _activeOnDone = null;
    onDone?.call();
  }
}

class VoiceInputException implements Exception {
  const VoiceInputException(this.message);

  final String message;

  @override
  String toString() => message;
}
