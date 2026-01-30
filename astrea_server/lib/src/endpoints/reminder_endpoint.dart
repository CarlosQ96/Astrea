import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/reminder.dart';
import '../services/fcm_service.dart';
import 'sync_endpoint.dart';

class ReminderEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  UuidValue _getUserId(Session session) {
    return UuidValue.fromString(session.authenticated!.userIdentifier);
  }

  Future<Reminder> create(
    Session session, {
    required String title,
    String? description,
    required DateTime dueAtUtc,
    required String originalTimezone,
    String? repeatRule,
    int? priority,
  }) async {
    if (priority != null && (priority < 1 || priority > 3)) {
      throw ArgumentError('Priority must be 1 (low), 2 (medium), or 3 (high)');
    }

    final userId = _getUserId(session);

    final reminder = Reminder(
      userId: userId,
      title: title,
      description: description,
      dueAtUtc: dueAtUtc,
      originalTimezone: originalTimezone,
      repeatRule: repeatRule,
      priority: priority,
    );

    final created = await Reminder.db.insertRow(session, reminder);
    ReminderSyncBroadcaster.notifyCreated(created);
    unawaited(_sendFcmNotification(session, userId, 'created', created.id!));
    return created;
  }

  Future<Reminder?> read(Session session, int id) async {
    final userId = _getUserId(session);

    final reminder = await Reminder.db.findById(session, id);
    if (reminder == null || reminder.userId != userId) {
      return null;
    }
    return reminder;
  }

  Future<Reminder?> update(
    Session session,
    int id, {
    String? title,
    String? description,
    DateTime? dueAtUtc,
    String? originalTimezone,
    String? repeatRule,
    int? priority,
  }) async {
    if (priority != null && (priority < 1 || priority > 3)) {
      throw ArgumentError('Priority must be 1 (low), 2 (medium), or 3 (high)');
    }

    final userId = _getUserId(session);

    final existing = await Reminder.db.findById(session, id);
    if (existing == null || existing.userId != userId) {
      return null;
    }

    final updated = existing.copyWith(
      title: title,
      description: description,
      dueAtUtc: dueAtUtc,
      originalTimezone: originalTimezone,
      repeatRule: repeatRule,
      priority: priority,
      revision: existing.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await Reminder.db.updateRow(session, updated);
    ReminderSyncBroadcaster.notifyUpdated(result);
    unawaited(_sendFcmNotification(session, userId, 'updated', result.id!));
    return result;
  }

  Future<bool> delete(Session session, int id) async {
    final userId = _getUserId(session);

    final existing = await Reminder.db.findById(session, id);
    if (existing == null || existing.userId != userId) {
      return false;
    }

    final reminderId = existing.id!;
    final reminderUserId = existing.userId;
    await Reminder.db.deleteRow(session, existing);
    ReminderSyncBroadcaster.notifyDeleted(reminderId, reminderUserId);
    unawaited(_sendFcmNotification(session, userId, 'deleted', reminderId));
    return true;
  }

  Future<List<Reminder>> list(
    Session session, {
    bool? includeCompleted,
    int? limit,
    int? offset,
  }) async {
    final userId = _getUserId(session);

    return await Reminder.db.find(
      session,
      where: (t) {
        var condition = t.userId.equals(userId);
        if (includeCompleted != true) {
          condition = condition & t.isCompleted.equals(false);
        }
        return condition;
      },
      orderBy: (t) => t.dueAtUtc,
      limit: limit,
      offset: offset,
    );
  }

  Future<Reminder?> complete(Session session, int id) async {
    final userId = _getUserId(session);

    final existing = await Reminder.db.findById(session, id);
    if (existing == null || existing.userId != userId) {
      return null;
    }

    final updated = existing.copyWith(
      isCompleted: true,
      revision: existing.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await Reminder.db.updateRow(session, updated);
    ReminderSyncBroadcaster.notifyCompleted(result);
    unawaited(_sendFcmNotification(session, userId, 'completed', result.id!));
    return result;
  }

  Future<Reminder?> snooze(Session session, int id, int minutes) async {
    if (minutes <= 0) {
      throw ArgumentError('Snooze minutes must be positive');
    }

    final userId = _getUserId(session);

    final existing = await Reminder.db.findById(session, id);
    if (existing == null || existing.userId != userId) {
      return null;
    }

    final updated = existing.copyWith(
      snoozedUntilUtc: DateTime.now().toUtc().add(Duration(minutes: minutes)),
      revision: existing.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await Reminder.db.updateRow(session, updated);
    ReminderSyncBroadcaster.notifySnoozed(result);
    unawaited(_sendFcmNotification(session, userId, 'snoozed', result.id!));
    return result;
  }

  Future<List<Reminder>> listDue(Session session) async {
    final userId = _getUserId(session);
    final now = DateTime.now().toUtc();

    return await Reminder.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.isCompleted.equals(false) &
          (t.dueAtUtc <= now) &
          (t.snoozedUntilUtc.equals(null) | (t.snoozedUntilUtc <= now)),
      orderBy: (t) => t.dueAtUtc,
    );
  }

  /// Sends FCM push notification for reminder sync (fire-and-forget).
  /// Silently ignores errors if session is already closed.
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
      // Silently ignore - session may be closed since this runs fire-and-forget
    }
  }
}
