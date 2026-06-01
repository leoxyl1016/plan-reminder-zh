import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isEnabled = true;
  VoidCallback? _activeOnDone;

  String _localeId = '';
  List<LocaleName> availableLocales = [];

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _isEnabled;
  String get localeId => _localeId;

  Future<void> setLocale(String localeId) async {
    _localeId = localeId;
    _isInitialized = false;
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) await cancelListening();
  }

  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isEnabled) {
      throw const VoiceInputException('语音输入已在设置中关闭');
    }

    // Check mic permission first (Android)
    final hasPermission = await _speechToText.hasPermission;
    if (!hasPermission) {
      throw const VoiceInputException(
        '没有麦克风权限。\n请在系统「设置 → 应用 → 权限」中允许麦克风。',
      );
    }

    await _initializeIfNeeded();
    _activeOnDone = onDone;

    // Use explicit locale if set, otherwise let device decide
    final effectiveLocale = _localeId.isNotEmpty ? _localeId : null;

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _completeSession();
        }
      },
      listenFor: const Duration(seconds: 30),
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
    if (_isInitialized) return;

    final available = await _speechToText.initialize(
      onStatus: (String status) {
        debugPrint('VoiceInput status: $status');
      },
      onError: (_) {
        debugPrint('VoiceInput error');
        _completeSession();
      },
    );

    if (!available) {
      throw const VoiceInputException(
        '语音识别不可用。\n'
        '1. 请确认已授予麦克风权限\n'
        '2. 手机需安装语音服务（Google 或讯飞）\n'
        '   （部分国产手机需在应用商店搜索"语音识别"安装）',
      );
    }

    // Fetch available locales for settings display
    try {
      availableLocales = await _speechToText.locales();
      debugPrint('VoiceInput: ${availableLocales.length} locales');
    } catch (_) {
      availableLocales = [];
    }

    _isInitialized = true;
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
