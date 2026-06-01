import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isEnabled = true;
  VoidCallback? _activeOnDone;
  String? _lastError;

  String _localeId = '';
  List<LocaleName> availableLocales = [];

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _isEnabled;
  String get localeId => _localeId;
  String? get lastError => _lastError;

  Future<void> setLocale(String localeId) async {
    _localeId = localeId;
    _isInitialized = false;
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) await cancelListening();
  }

  /// Start listening and return any error that occurred (null = success).
  /// Errors are also stored in [lastError].
  Future<String?> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required VoidCallback onDone,
  }) async {
    _lastError = null;

    if (!_isEnabled) {
      _lastError = '语音输入已在设置中关闭';
      return _lastError;
    }

    // Check mic permission
    try {
      final hasPermission = await _speechToText.hasPermission;
      if (!hasPermission) {
        _lastError = '没有麦克风权限';
        return _lastError;
      }
    } catch (e) {
      _lastError = '无法检查麦克风权限: $e';
      return _lastError;
    }

    // Initialize
    try {
      await _initializeIfNeeded();
    } catch (e) {
      _lastError = e.toString();
      return _lastError;
    }

    _activeOnDone = onDone;

    // Determine locale
    final effectiveLocale = _localeId.isNotEmpty ? _localeId : null;
    debugPrint('VoiceInput: starting listen with locale=$effectiveLocale');

    try {
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
          cancelOnError: false, // Don't cancel on error — let us handle it
          listenMode: ListenMode.confirmation,
        ),
      );

      // listen() completed normally
      debugPrint('VoiceInput: listen completed normally');
      _completeSession();
      return null;

    } catch (e) {
      debugPrint('VoiceInput: listen() threw: $e');
      _lastError = '语音识别出错: $e';
      _completeSession();
      return _lastError;
    }
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

    debugPrint('VoiceInput: initializing...');

    final available = await _speechToText.initialize(
      onStatus: (String status) {
        debugPrint('VoiceInput status: $status');
      },
      onError: (error) {
        debugPrint('VoiceInput engine error: $error');
        _lastError = '语音引擎错误: $error';
      },
    );

    if (!available) {
      _lastError = '语音识别不可用';
      throw VoiceInputException(
        '语音识别不可用。\n'
        '1. 确认已授予麦克风权限\n'
        '2. 安装语音服务：华为/小米装"讯飞语音"，其他装 Google',
      );
    }

    debugPrint('VoiceInput: initialized OK');

    // Fetch available locales
    try {
      availableLocales = await _speechToText.locales();
      debugPrint('VoiceInput: ${availableLocales.length} locales: '
          '${availableLocales.map((l) => l.localeId).take(5).join(', ')}...');
    } catch (e) {
      debugPrint('VoiceInput: could not fetch locales: $e');
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
