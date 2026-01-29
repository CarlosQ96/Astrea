import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';
import '../theme/astrea_colors.dart';
import 'voice_button.dart';

/// Text input field with send button for chat.
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    sendChatMessage(ref, message);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _onTranscription(String text) {
    if (text.isEmpty) return;
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(chatLoadingProvider);
    final voiceState = ref.watch(voiceServiceProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final voiceEnabled = settingsAsync.valueOrNull?.voiceEnabled ?? true;

    // Show error snackbar when voice error occurs
    ref.listen<VoiceState>(voiceServiceProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: ${next.error}'),
            backgroundColor: AstreaColors.error,
          ),
        );
      }
    });

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AstreaColors.deepVoid,
        border: Border(
          top: BorderSide(
            color: AstreaColors.mysticViolet,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show real-time transcription when listening
          if (voiceState.isListening && voiceState.transcription.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                voiceState.transcription,
                style: const TextStyle(
                  color: AstreaColors.mist,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isLoading && !voiceState.isListening,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: voiceState.isListening
                        ? 'Listening...'
                        : 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AstreaColors.astralPurple,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              if (voiceEnabled) ...[
                const SizedBox(width: 8),
                VoiceButton(
                  onTranscription: _onTranscription,
                  enabled: !isLoading,
                ),
              ],
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AstreaColors.starlightCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton.filled(
                  onPressed: isLoading ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AstreaColors.starlightCyan,
                    foregroundColor: AstreaColors.deepVoid,
                    disabledBackgroundColor: AstreaColors.mysticViolet,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
