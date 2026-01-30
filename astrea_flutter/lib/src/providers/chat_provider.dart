import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../services/notification_service.dart';
import 'client_provider.dart';
import 'reminders_provider.dart';

/// Represents a chat message (user or AI).
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final bool actionParsed;
  final bool isDissolving;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.actionParsed = false,
    this.isDissolving = false,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? intent,
    bool? actionParsed,
    bool? isDissolving,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      intent: intent ?? this.intent,
      actionParsed: actionParsed ?? this.actionParsed,
      isDissolving: isDissolving ?? this.isDissolving,
    );
  }
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

  /// Marks a message as dissolving (triggers particle effect).
  void markDissolving(String messageId) {
    state = [
      for (final msg in state)
        if (msg.id == messageId) msg.copyWith(isDissolving: true) else msg,
    ];
  }

  /// Marks multiple messages as dissolving.
  void markMultipleDissolving(Set<String> messageIds) {
    state = [
      for (final msg in state)
        if (messageIds.contains(msg.id))
          msg.copyWith(isDissolving: true)
        else
          msg,
    ];
  }

  /// Removes a message after dissolution completes.
  void removeMessage(String messageId) {
    state = state.where((msg) => msg.id != messageId).toList();
  }

  /// Triggers dissolution for all messages (on reminder creation).
  void dissolveAll() {
    state = [
      for (final msg in state) msg.copyWith(isDissolving: true),
    ];
  }

  /// Triggers dissolution for old messages, keeps the newest AI response visible.
  void dissolveOldMessages() {
    if (state.length <= 2) return; // Keep at least the last exchange

    // Keep the last 2 messages (user question + AI response), dissolve the rest
    final toKeep = state.length >= 2 ? state.sublist(state.length - 2) : state;
    final toDissolve = state.length > 2
        ? state.sublist(0, state.length - 2)
        : <ChatMessage>[];

    // Mark old messages for dissolution
    state = [
      for (final msg in toDissolve) msg.copyWith(isDissolving: true),
      ...toKeep,
    ];

    // Remove dissolved messages after animation
    Future.delayed(const Duration(milliseconds: 1300), () {
      state = state.where((msg) => !msg.isDissolving).toList();
    });
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

/// Builds conversation history from messages (last N messages as sliding window).
List<Map<String, String>> _buildConversationHistory(
  List<ChatMessage> messages, {
  int maxMessages = 10,
}) {
  // Take last N messages (excluding the current one being sent)
  final recentMessages = messages.length > maxMessages
      ? messages.sublist(messages.length - maxMessages)
      : messages;

  return recentMessages.map((msg) {
    return {
      'role': msg.isUser ? 'user' : 'assistant',
      'content': msg.text,
    };
  }).toList();
}

/// Sends a message to the chat endpoint.
Future<void> sendChatMessage(WidgetRef ref, String message) async {
  if (message.trim().isEmpty) return;

  final client = ref.read(clientProvider);
  final currentMessages = ref.read(chatMessagesProvider);

  // Build conversation history BEFORE adding new message
  final history = _buildConversationHistory(currentMessages);

  // Add user message immediately
  ref.read(chatMessagesProvider.notifier).addUserMessage(message);
  ref.read(chatLoadingProvider.notifier).state = true;

  try {
    // Use IANA timezone format (e.g., "America/New_York") instead of abbreviation
    final timezone = await FlutterTimezone.getLocalTimezone();
    final response = await client.chat.send(
      message,
      timezone: timezone,
      history: history,
    );
    ref.read(chatMessagesProvider.notifier).addAiMessage(response);

    // Schedule notification if a reminder was created
    // Note: sync provider also schedules, but this ensures immediate scheduling
    // if sync isn't connected yet. NotificationService replaces by ID.
    if (response.intent == 'create_reminder' &&
        response.actionReminderId != null &&
        response.actionDueAtUtc != null) {
      await NotificationService.scheduleReminder(
        reminderId: response.actionReminderId!,
        title: response.actionTitle ?? 'Reminder',
        body: response.actionDescription,
        scheduledTime: response.actionDueAtUtc!,
      );
    }

    // Refresh reminders list and clear chat if an action was performed
    if (response.actionParsed) {
      ref.invalidate(remindersProvider);
      // Trigger ephemeral dissolution for old messages (keep the new reminder)
      ref.read(chatMessagesProvider.notifier).dissolveOldMessages();
    }
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
