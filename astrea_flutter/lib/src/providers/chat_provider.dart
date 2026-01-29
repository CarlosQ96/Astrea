import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'client_provider.dart';

/// Represents a chat message (user or AI).
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final bool actionParsed;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.actionParsed = false,
  });
}

/// Manages ephemeral chat messages.
class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addUserMessage(String text) {
    state = [
      ...state,
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void addAiMessage(ChatResponse response) {
    state = [
      ...state,
      ChatMessage(
        text: response.response,
        isUser: false,
        timestamp: DateTime.now(),
        intent: response.intent,
        actionParsed: response.actionParsed,
      ),
    ];
  }

  void clear() {
    state = [];
  }
}

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      ChatMessagesNotifier.new,
    );

/// Tracks loading state during API calls.
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// Sends a message to the chat endpoint.
Future<void> sendChatMessage(WidgetRef ref, String message) async {
  if (message.trim().isEmpty) return;

  final client = ref.read(clientProvider);

  // Add user message immediately
  ref.read(chatMessagesProvider.notifier).addUserMessage(message);
  ref.read(chatLoadingProvider.notifier).state = true;

  try {
    // Use IANA timezone format (e.g., "America/New_York") instead of abbreviation
    final timezone = await FlutterTimezone.getLocalTimezone();
    final response = await client.chat.send(message, timezone: timezone);
    ref.read(chatMessagesProvider.notifier).addAiMessage(response);
  } catch (e) {
    // Add error as AI message
    ref
        .read(chatMessagesProvider.notifier)
        .addAiMessage(
          ChatResponse(
            intent: 'error',
            response: 'Sorry, something went wrong. Please try again.',
            actionParsed: false,
          ),
        );
  } finally {
    ref.read(chatLoadingProvider.notifier).state = false;
  }
}
