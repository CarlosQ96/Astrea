import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/reminders/reminder.dart';
import 'exceptions.dart';
import 'intent.dart';

/// Handles Claude AI interactions for intent classification and response generation.
class ClaudeService {
  static const String _model = 'claude-sonnet-4-20250514';
  static const int _maxTokens = 1024;
  static const Duration _timeout = Duration(seconds: 30);

  static ClaudeService? _instance;
  static ChatCapability? _provider;

  ClaudeService._();

  /// Lazy singleton that reads API key from Serverpod passwords config.
  static Future<ClaudeService> getInstance(Session session) async {
    if (_instance == null || _provider == null) {
      final apiKey = session.passwords['anthropicApiKey'];
      if (apiKey == null || apiKey.isEmpty) {
        throw const AiConfigurationException(
          message: 'Anthropic API key not configured',
          code: 'MISSING_API_KEY',
        );
      }

      _provider = await ai()
          .anthropic()
          .apiKey(apiKey)
          .model(_model)
          .maxTokens(_maxTokens)
          .timeout(_timeout)
          .build();

      _instance = ClaudeService._();
    }
    return _instance!;
  }

  /// Sends user message to Claude with reminder context, returns classified intent and action.
  Future<({String response, Intent intent, ParsedAction action})>
  processMessage({
    required String userMessage,
    required List<Reminder> reminders,
    required String timezone,
  }) async {
    if (_provider == null) {
      throw const AiConfigurationException(
        message: 'Claude service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    final systemPrompt = _buildSystemPrompt(
      reminders: reminders,
      timezone: timezone,
    );

    final messages = [
      ChatMessage.system(systemPrompt),
      ChatMessage.user(userMessage),
    ];

    try {
      final response = await _provider!.chat(messages);
      final text = response.text ?? '';

      return _parseResponse(text, reminders);
    } on AuthError catch (e) {
      throw AiApiException(
        message: 'Authentication failed: $e',
        code: 'AUTH_ERROR',
      );
    } on RateLimitError catch (e) {
      throw AiRateLimitException(
        message: 'Rate limit exceeded: $e',
        code: 'RATE_LIMIT',
      );
    } on ProviderError catch (e) {
      throw AiApiException(
        message: 'Claude API error: $e',
        code: 'PROVIDER_ERROR',
      );
    } on HttpError catch (e) {
      throw AiApiException(
        message: 'Network error: $e',
        code: 'HTTP_ERROR',
      );
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiApiException(
        message: 'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Builds the system prompt with user's reminders as context for Claude.
  String _buildSystemPrompt({
    required List<Reminder> reminders,
    required String timezone,
  }) {
    final now = DateTime.now().toUtc();
    final todayReminders = reminders.where(
      (r) => !r.isCompleted && _isToday(r.dueAtUtc, now),
    );
    final overdueReminders = reminders.where(
      (r) => !r.isCompleted && r.dueAtUtc.isBefore(now),
    );
    final upcomingReminders = reminders
        .where((r) => !r.isCompleted && r.dueAtUtc.isAfter(now))
        .take(10);

    final reminderContext = _buildReminderContext(reminders);

    return '''
You are Astrea, a friendly and helpful reminder assistant. Your personality is warm, concise, and efficient.

CURRENT CONTEXT:
Current UTC time: ${now.toIso8601String()}
User timezone: $timezone
Today's reminders: ${todayReminders.length}
Overdue reminders: ${overdueReminders.length}
Upcoming reminders: ${upcomingReminders.length}

USER'S REMINDERS:
$reminderContext

RESPONSE FORMAT:
You MUST respond with valid JSON in this exact format:
{
  "intent": "create_reminder|list_reminders|complete_reminder|delete_reminder|snooze_reminder|question|chat",
  "response": "Your natural, friendly response to show the user",
  "action": {
    "title": "string (required for create)",
    "description": "string or null",
    "dueAtUtc": "ISO 8601 UTC datetime (required for create)",
    "priority": 1-3 (1=low, 2=medium, 3=high, default 2),
    "repeatRule": "RRULE string or null",
    "reminderId": number (for complete/delete/snooze),
    "minutes": number (for snooze, default 15)
  }
}

INTENT CLASSIFICATION:
create_reminder: User wants to set/add/create a new reminder
list_reminders: User asks what they have to do, their schedule
complete_reminder: User says they finished/did/completed something
delete_reminder: User wants to remove/cancel a reminder
snooze_reminder: User wants to delay/postpone a reminder
question: User asks about reminders without wanting action
chat: Greeting, thanks, general conversation

DATE PARSING:
"tomorrow" = next day at 9:00 AM user timezone
"tomorrow at 3pm" = next day at 15:00 user timezone
"in 2 hours" = current time + 2 hours
"next Monday" = upcoming Monday at 9:00 AM
Always convert to UTC for dueAtUtc

SNOOZE MAPPING:
"5 minutes" = 5, "15 minutes" or "a bit" = 15, "30 minutes" = 30, "1 hour" = 60, "tomorrow" = 1440

When user refers to a reminder like "the mom one" or "groceries", match it to the most relevant reminder by title. If ambiguous, ask for clarification.

Be concise but friendly. Use natural language, not robotic responses.
''';
  }

  String _buildReminderContext(List<Reminder> reminders) {
    if (reminders.isEmpty) return 'No reminders set.';

    final buffer = StringBuffer();
    for (final r in reminders) {
      final status = r.isCompleted
          ? '✓'
          : (r.dueAtUtc.isBefore(DateTime.now().toUtc()) ? 'OVERDUE' : '○');
      final priority = switch (r.priority) {
        1 => 'low',
        3 => 'high',
        _ => 'medium',
      };
      buffer.writeln(
        '[ID:${r.id}] $status ${r.title} | Due: ${r.dueAtUtc.toIso8601String()} | Priority: $priority${r.description != null ? ' | Note: ${r.description}' : ''}',
      );
    }
    return buffer.toString();
  }

  bool _isToday(DateTime dt, DateTime now) {
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Extracts JSON from Claude's response, handling markdown code blocks.
  /// Falls back gracefully if parsing fails.
  ({String response, Intent intent, ParsedAction action}) _parseResponse(
    String text,
    List<Reminder> reminders,
  ) {
    try {
      // Strip markdown code blocks if present
      var jsonText = text.trim();
      if (jsonText.startsWith('```json')) jsonText = jsonText.substring(7);
      if (jsonText.startsWith('```')) jsonText = jsonText.substring(3);
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      final intent = Intent.fromString(json['intent'] as String?);
      final responseText =
          json['response'] as String? ?? 'I understood your request.';
      final actionData = json['action'] as Map<String, dynamic>?;
      final action = _parseAction(intent, actionData, reminders);

      return (response: responseText, intent: intent, action: action);
    } catch (e) {
      return (
        response: text.isNotEmpty
            ? text
            : 'I had trouble understanding that. Could you try rephrasing?',
        intent: Intent.unknown,
        action: const NoAction(),
      );
    }
  }

  /// Routes action parsing based on intent type using pattern matching.
  ParsedAction _parseAction(
    Intent intent,
    Map<String, dynamic>? actionData,
    List<Reminder> reminders,
  ) {
    if (actionData == null) return const NoAction();

    return switch (intent) {
      Intent.createReminder => _parseCreateAction(actionData),
      Intent.completeReminder => _parseCompleteAction(actionData, reminders),
      Intent.deleteReminder => _parseDeleteAction(actionData, reminders),
      Intent.snoozeReminder => _parseSnoozeAction(actionData, reminders),
      _ => const NoAction(),
    };
  }

  CreateReminderAction _parseCreateAction(Map<String, dynamic> data) {
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      throw const AiParseException(
        message: 'Missing title in create action',
        code: 'MISSING_TITLE',
      );
    }

    final dueAtStr = data['dueAtUtc'] as String?;
    if (dueAtStr == null) {
      throw const AiParseException(
        message: 'Missing dueAtUtc in create action',
        code: 'MISSING_DUE_DATE',
      );
    }

    final dueAtUtc = DateTime.tryParse(dueAtStr)?.toUtc();
    if (dueAtUtc == null) {
      throw AiParseException(
        message: 'Invalid dueAtUtc format: $dueAtStr',
        code: 'INVALID_DATE_FORMAT',
      );
    }

    return CreateReminderAction(
      title: title,
      description: data['description'] as String?,
      dueAtUtc: dueAtUtc,
      priority: (data['priority'] as int?) ?? 2,
      repeatRule: data['repeatRule'] as String?,
    );
  }

  CompleteReminderAction _parseCompleteAction(
    Map<String, dynamic> data,
    List<Reminder> reminders,
  ) {
    return CompleteReminderAction(
      reminderId: _extractReminderId(data, reminders),
    );
  }

  DeleteReminderAction _parseDeleteAction(
    Map<String, dynamic> data,
    List<Reminder> reminders,
  ) {
    return DeleteReminderAction(
      reminderId: _extractReminderId(data, reminders),
    );
  }

  SnoozeReminderAction _parseSnoozeAction(
    Map<String, dynamic> data,
    List<Reminder> reminders,
  ) {
    return SnoozeReminderAction(
      reminderId: _extractReminderId(data, reminders),
      minutes: (data['minutes'] as int?) ?? 15,
    );
  }

  /// Extracts reminder ID, handling both int and string types from JSON.
  int _extractReminderId(Map<String, dynamic> data, List<Reminder> reminders) {
    final reminderId = data['reminderId'];
    if (reminderId is int) return reminderId;
    if (reminderId is String) {
      final parsed = int.tryParse(reminderId);
      if (parsed != null) return parsed;
    }
    throw const AiParseException(
      message: 'Missing or invalid reminderId',
      code: 'MISSING_REMINDER_ID',
    );
  }
}
