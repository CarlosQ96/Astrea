import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// State for voice input.
@immutable
class VoiceState {
  final bool isAvailable;
  final bool isListening;
  final String transcription;
  final String? error;

  const VoiceState({
    this.isAvailable = false,
    this.isListening = false,
    this.transcription = '',
    this.error,
  });

  VoiceState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? transcription,
    String? error,
  }) {
    return VoiceState(
      isAvailable: isAvailable ?? this.isAvailable,
      isListening: isListening ?? this.isListening,
      transcription: transcription ?? this.transcription,
      error: error,
    );
  }
}

/// Service for device-native speech-to-text recognition.
class VoiceService extends StateNotifier<VoiceState> {
  VoiceService() : super(const VoiceState());

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// Initialize the speech recognition service.
  /// Returns true if speech recognition is available on this device.
  Future<bool> initialize() async {
    if (_initialized) return state.isAvailable;

    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );
      _initialized = true;
      state = state.copyWith(isAvailable: available);
      return available;
    } catch (e) {
      debugPrint('VoiceService: Failed to initialize: $e');
      state = state.copyWith(isAvailable: false, error: e.toString());
      return false;
    }
  }

  /// Start listening for speech input.
  Future<void> startListening() async {
    if (!_initialized) {
      final available = await initialize();
      if (!available) {
        state = state.copyWith(
          error: 'Speech recognition not available on this device',
        );
        return;
      }
    }

    if (!state.isAvailable || state.isListening) return;

    state = state.copyWith(
      isListening: true,
      transcription: '',
      error: null,
    );

    await _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stop listening and finalize transcription.
  Future<String> stopListening() async {
    if (!state.isListening) return state.transcription;

    await _speech.stop();
    state = state.copyWith(isListening: false);
    return state.transcription;
  }

  /// Cancel listening without keeping the transcription.
  Future<void> cancelListening() async {
    if (!state.isListening) return;

    await _speech.cancel();
    state = state.copyWith(
      isListening: false,
      transcription: '',
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    state = state.copyWith(transcription: result.recognizedWords);
  }

  void _onStatus(String status) {
    debugPrint('VoiceService: Status: $status');
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(isListening: false);
    }
  }

  void _onError(dynamic error) {
    debugPrint('VoiceService: Error: $error');
    state = state.copyWith(
      isListening: false,
      error: error.toString(),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

/// Provider for the voice service.
final voiceServiceProvider = StateNotifierProvider<VoiceService, VoiceState>((
  ref,
) {
  return VoiceService();
});
