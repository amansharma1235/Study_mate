import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final voiceStudyServiceProvider = Provider<VoiceStudyService>((ref) {
  return VoiceStudyService();
});

class VoiceStudyService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  String? _currentlySpeakingText;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String? get currentlySpeakingText => _currentlySpeakingText;

  VoiceStudyService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS notice: $msg');
        _isSpeaking = false;
        _currentlySpeakingText = null;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization notice: $e');
    }
  }

  /// Initialize Speech-to-Text on demand when user activates mic
  Future<bool> initStt() async {
    if (_isSttInitialized) return true;
    try {
      _isSttInitialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          debugPrint('STT notice: ${errorNotification.errorMsg}');
          _isListening = false;
        },
      );
      return _isSttInitialized;
    } catch (e) {
      debugPrint('Speech initialization notice: $e');
      return false;
    }
  }

  /// Clean markdown artifacts (e.g. **, ###, bullet points) for natural voice reading
  String cleanMarkdownForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*|\*|__|###|##|#|---'), ' ')
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), 'code snippet')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'[•\-\–]'), ', ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Read text aloud
  Future<void> speak(
    String rawText, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }

    if (_isSpeaking && _currentlySpeakingText == rawText) {
      // Toggle stop if already speaking this exact message
      await stopSpeaking();
      onComplete?.call();
      return;
    }

    await stopSpeaking();
    _currentlySpeakingText = rawText;
    final speechText = cleanMarkdownForSpeech(rawText);

    if (speechText.isEmpty) return;

    try {
      _tts.setStartHandler(() {
        _isSpeaking = true;
        onStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        onComplete?.call();
      });

      await _tts.speak(speechText);
    } catch (e) {
      debugPrint('TTS speak notice: $e');
      _isSpeaking = false;
      _currentlySpeakingText = null;
      onComplete?.call();
    }
  }

  /// Stop reading
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      _currentlySpeakingText = null;
    } catch (e) {
      debugPrint('TTS stop notice: $e');
    }
  }

  /// Start dictation listening
  Future<bool> startListening({
    required Function(String words) onResult,
    VoidCallback? onListeningStarted,
    VoidCallback? onListeningStopped,
  }) async {
    final available = await initStt();
    if (!available) return false;

    // If already speaking, pause speech first so mic doesn't catch own audio
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isListening = true;
      onListeningStarted?.call();

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Speech listen notice: $e');
      _isListening = false;
      onListeningStopped?.call();
      return false;
    }
  }

  /// Stop dictation listening
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('Speech stop notice: $e');
    }
  }

  void dispose() {
    stopSpeaking();
    stopListening();
  }
}
