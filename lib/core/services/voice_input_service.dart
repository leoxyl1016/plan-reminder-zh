import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isEnabled = true;
  VoidCallback? _activeOnDone;

  /// Currently active locale. Defaults to device locale, configurable.
  String _localeId = '';

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _isEnabled;
  String get localeId => _localeId;

  /// Set the speech recognition locale.
  /// Common values: 'zh_CN' (Mandarin), 'en_US' (English), '' (device default)
  Future<void> setLocale(String localeId) async {
    _localeId = localeId;
    // Re-initialize if already initialized
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
      throw const VoiceInputException(
        '语音输入已在设置中关闭',
      );
    }

    await _initializeIfNeeded();
    _activeOnDone = onDone;

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _completeSession();
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      localeId: _localeId.isNotEmpty ? _localeId : null,
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
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _completeSession();
        }
      },
      onError: (_) => _completeSession(),
    );

    if (!available) {
      throw const VoiceInputException(
        '此设备不支持语音识别',
      );
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
