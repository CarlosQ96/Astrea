import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../services/claude_service.dart';
import '../services/embedding_service.dart';
import '../services/fcm_service.dart';
import '../services/exceptions.dart';
import '../services/intent.dart';
import '../generated/chat_response.dart';
import '../generated/reminder.dart';
import '../generated/user_settings.dart';
import 'sync_endpoint.dart';

/// Handles natural language chat and executes reminder actions.
class ChatEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Main entry point: processes chat message, classifies intent, executes action.
  /// [history] - Optional conversation history for context (list of {role, content} maps).
  Future<ChatResponse> send(
    Session session,
    String message, {
    String? timezone,
    List<Map<String, String>>? history,
  }) async {
    final userId = _getUserId(session);
    final settings = await _getOrCreateSettings(session, userId);
    final userTimezone = timezone ?? settings.timezone;

    // Get relevant reminders using semantic search if embeddings available
    final reminders = await _getRelevantReminders(session, userId, message);

    try {
      final claudeService = await ClaudeService.getInstance(session);
      final result = await claudeService.processMessage(
        userMessage: message,
        reminders: reminders,
        timezone: userTimezone,
        conversationHistory: history,
      );

      final actionResult = await _executeAction(
        session,
        userId,
        result.action,
        userTimezone,
      );

      return ChatResponse(
        intent: result.intent.value,
        response: actionResult ?? result.response,
        actionParsed: result.action is! NoAction,
        actionTitle: result.action is CreateReminderAction
            ? (result.action as CreateReminderAction).title
            : null,
        actionDueAtUtc: result.action is CreateReminderAction
            ? (result.action as CreateReminderAction).dueAtUtc
            : null,
        actionPriority: result.action is CreateReminderAction
            ? (result.action as CreateReminderAction).priority
            : null,
        actionDescription: result.action is CreateReminderAction
            ? (result.action as CreateReminderAction).description
            : null,
        actionReminderId: _extractReminderId(result.action),
        actionSnoozeMinutes: result.action is SnoozeReminderAction
            ? (result.action as SnoozeReminderAction).minutes
            : null,
      );
    } on AiConfigurationException catch (e) {
      session.log(
        'AI configuration error: ${e.message}',
        level: LogLevel.error,
      );
      return ChatResponse(
        intent: Intent.unknown.value,
        response:
            'Sorry, the AI service is not properly configured. Please try again later.',
        actionParsed: false,
      );
    } on AiApiException catch (e) {
      session.log('AI API error: ${e.message}', level: LogLevel.error);
      return ChatResponse(
        intent: Intent.unknown.value,
        response:
            'Sorry, I had trouble processing your request. Please try again.',
        actionParsed: false,
      );
    } on AiRateLimitException catch (e) {
      session.log('AI rate limit: ${e.message}', level: LogLevel.warning);
      return ChatResponse(
        intent: Intent.unknown.value,
        response:
            'I\'m receiving too many requests right now. Please wait a moment and try again.',
        actionParsed: false,
      );
    }
  }

  /// Executes the parsed action, returns override response if action fails.
  Future<String?> _executeAction(
    Session session,
    UuidValue userId,
    ParsedAction action,
    String timezone,
  ) async {
    return switch (action) {
      CreateReminderAction(
        :final title,
        :final description,
        :final dueAtUtc,
        :final priority,
        :final repeatRule,
      ) =>
        await _createReminder(
          session,
          userId,
          title: title,
          description: description,
          dueAtUtc: dueAtUtc,
          timezone: timezone,
          priority: priority,
          repeatRule: repeatRule,
        ),
      CompleteReminderAction(:final reminderId) => await _completeReminder(
        session,
        userId,
        reminderId,
      ),
      DeleteReminderAction(:final reminderId) => await _deleteReminder(
        session,
        userId,
        reminderId,
      ),
      SnoozeReminderAction(:final reminderId, :final minutes) =>
        await _snoozeReminder(session, userId, reminderId, minutes),
      NoAction() => null,
    };
  }

  Future<String?> _createReminder(
    Session session,
    UuidValue userId, {
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String timezone,
    required int priority,
    String? repeatRule,
  }) async {
    final reminder = Reminder(
      userId: userId,
      title: title,
      description: description,
      dueAtUtc: dueAtUtc,
      originalTimezone: timezone,
      priority: priority,
      repeatRule: repeatRule,
    );
    final created = await Reminder.db.insertRow(session, reminder);
    ReminderSyncBroadcaster.notifyCreated(created);
    unawaited(_sendFcmNotification(session, userId, 'created', created.id!));
    return null;
  }

  /// Marks reminder complete after verifying ownership.
  Future<String?> _completeReminder(
    Session session,
    UuidValue userId,
    int reminderId,
  ) async {
    final reminder = await Reminder.db.findById(session, reminderId);
    if (reminder == null || reminder.userId != userId) {
      return 'I couldn\'t find that reminder. Could you be more specific?';
    }

    final updated = reminder.copyWith(
      isCompleted: true,
      revision: reminder.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    final result = await Reminder.db.updateRow(session, updated);
    ReminderSyncBroadcaster.notifyCompleted(result);
    unawaited(_sendFcmNotification(session, userId, 'completed', result.id!));
    return null;
  }

  Future<String?> _deleteReminder(
    Session session,
    UuidValue userId,
    int reminderId,
  ) async {
    final reminder = await Reminder.db.findById(session, reminderId);
    if (reminder == null || reminder.userId != userId) {
      return 'I couldn\'t find that reminder. Could you be more specific?';
    }

    await Reminder.db.deleteRow(session, reminder);
    ReminderSyncBroadcaster.notifyDeleted(reminderId, userId);
    unawaited(_sendFcmNotification(session, userId, 'deleted', reminderId));
    return null;
  }

  /// Delays reminder by given minutes after verifying ownership.
  Future<String?> _snoozeReminder(
    Session session,
    UuidValue userId,
    int reminderId,
    int minutes,
  ) async {
    final reminder = await Reminder.db.findById(session, reminderId);
    if (reminder == null || reminder.userId != userId) {
      return 'I couldn\'t find that reminder. Could you be more specific?';
    }

    final updated = reminder.copyWith(
      snoozedUntilUtc: DateTime.now().toUtc().add(Duration(minutes: minutes)),
      revision: reminder.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    final result = await Reminder.db.updateRow(session, updated);
    ReminderSyncBroadcaster.notifySnoozed(result);
    unawaited(_sendFcmNotification(session, userId, 'snoozed', result.id!));
    return null;
  }

  int? _extractReminderId(ParsedAction action) {
    return switch (action) {
      CompleteReminderAction(:final reminderId) => reminderId,
      DeleteReminderAction(:final reminderId) => reminderId,
      SnoozeReminderAction(:final reminderId) => reminderId,
      _ => null,
    };
  }

  UuidValue _getUserId(Session session) {
    return UuidValue.fromString(session.authenticated!.userIdentifier);
  }

  /// Fetches relevant reminders using semantic search + today's reminders.
  /// Falls back to basic query if embeddings are not available.
  Future<List<Reminder>> _getRelevantReminders(
    Session session,
    UuidValue userId,
    String userMessage,
  ) async {
    final embeddingService = await EmbeddingService.getInstance(session);
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Always get today's and overdue reminders (always relevant)
    final todayReminders = await Reminder.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.isCompleted.equals(false) &
          t.dueAtUtc.between(todayStart, todayEnd),
      limit: 20,
    );

    // Get overdue reminders (due before today start)
    // Use a very old date as lower bound since direct < comparison isn't supported
    final veryOldDate = DateTime.utc(2000, 1, 1);
    final overdueReminders = await Reminder.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.isCompleted.equals(false) &
          t.dueAtUtc.between(
            veryOldDate,
            todayStart.subtract(const Duration(seconds: 1)),
          ),
      limit: 10,
    );

    // Semantic search using embeddings (if available)
    // Note: Full pgvector search will be enabled after running serverpod generate
    List<Reminder> similarReminders = [];
    if (embeddingService != null) {
      try {
        final queryEmbedding = await embeddingService.generateEmbedding(
          userMessage,
        );
        if (queryEmbedding != null) {
          // TODO: Enable pgvector cosine distance query after migration
          // For now, embeddings are generated but search uses standard queries
          session.log(
            'Embedding generated for query (${queryEmbedding.length} dims)',
            level: LogLevel.debug,
          );
        }
      } catch (e) {
        session.log(
          'Embedding generation failed: $e',
          level: LogLevel.warning,
        );
      }
    }

    // Merge and dedupe by id
    final allIds = <int>{};
    final result = <Reminder>[];
    for (final r in [
      ...similarReminders,
      ...todayReminders,
      ...overdueReminders,
    ]) {
      if (allIds.add(r.id!)) result.add(r);
    }
    return result.take(25).toList();
  }

  /// Gets user settings or creates defaults if first time.
  Future<UserSettings> _getOrCreateSettings(
    Session session,
    UuidValue userId,
  ) async {
    final existing = await UserSettings.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (existing != null) return existing;

    final settings = UserSettings(userId: userId);
    return await UserSettings.db.insertRow(session, settings);
  }

  /// Sends FCM push notification for reminder sync (fire-and-forget).
  Future<void> _sendFcmNotification(
    Session session,
    UuidValue userId,
    String eventType,
    int reminderId,
  ) async {
    try {
      final fcmService = await FcmService.getInstance(session);
      if (fcmService != null) {
        await fcmService.sendSyncEvent(
          session,
          userId: userId,
          eventType: eventType,
          reminderId: reminderId,
        );
      }
    } catch (e) {
      session.log('FCM notification failed: $e', level: LogLevel.warning);
    }
  }
}
