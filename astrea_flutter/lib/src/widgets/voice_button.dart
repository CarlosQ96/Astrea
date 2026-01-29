import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/voice_service.dart';
import '../theme/astrea_colors.dart';

/// Microphone button for voice input with long-press interaction.
/// Long press to start listening, release to stop and submit transcription.
class VoiceButton extends ConsumerStatefulWidget {
  const VoiceButton({
    super.key,
    required this.onTranscription,
    this.enabled = true,
  });

  /// Called when transcription is complete with the recognized text.
  final void Function(String text) onTranscription;

  /// Whether the button is enabled for interaction.
  final bool enabled;

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop listening when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final voiceState = ref.read(voiceServiceProvider);
      if (voiceState.isListening) {
        ref.read(voiceServiceProvider.notifier).cancelListening();
      }
    }
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    await ref.read(voiceServiceProvider.notifier).startListening();
  }

  Future<void> _stopListening() async {
    final transcription = await ref
        .read(voiceServiceProvider.notifier)
        .stopListening();
    if (transcription.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onTranscription(transcription);
    }
  }

  Future<void> _cancelListening() async {
    await ref.read(voiceServiceProvider.notifier).cancelListening();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceServiceProvider);
    final isListening = voiceState.isListening;

    // Tie pulse animation to actual listening state
    ref.listen<VoiceState>(voiceServiceProvider, (previous, next) {
      if (next.isListening && !(previous?.isListening ?? false)) {
        _pulseController.repeat(reverse: true);
      } else if (!next.isListening && (previous?.isListening ?? false)) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    return GestureDetector(
      onLongPressStart: widget.enabled ? (_) => _startListening() : null,
      onLongPressEnd: widget.enabled ? (_) => _stopListening() : null,
      onLongPressCancel: widget.enabled ? _cancelListening : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: AstreaColors.error.withValues(alpha: 0.4),
                        blurRadius: 16 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: Transform.scale(
              scale: isListening ? _pulseAnimation.value : 1.0,
              child: child,
            ),
          );
        },
        child: IconButton.filled(
          onPressed: null, // Interaction handled by GestureDetector
          icon: Icon(
            isListening ? Icons.mic : Icons.mic_none_rounded,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isListening
                ? AstreaColors.error
                : AstreaColors.mysticViolet,
            foregroundColor: isListening
                ? AstreaColors.deepVoid
                : AstreaColors.starlightCyan,
            disabledBackgroundColor: isListening
                ? AstreaColors.error
                : AstreaColors.mysticViolet,
            disabledForegroundColor: isListening
                ? AstreaColors.deepVoid
                : AstreaColors.starlightCyan,
          ),
        ),
      ),
    );
  }
}
