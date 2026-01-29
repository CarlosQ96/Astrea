import 'package:serverpod/serverpod.dart';

import '../generated/reminder.dart';

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

    return await Reminder.db.insertRow(session, reminder);
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

    return await Reminder.db.updateRow(session, updated);
  }

  Future<bool> delete(Session session, int id) async {
    final userId = _getUserId(session);

    final existing = await Reminder.db.findById(session, id);
    if (existing == null || existing.userId != userId) {
      return false;
    }

    await Reminder.db.deleteRow(session, existing);
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

    return await Reminder.db.updateRow(session, updated);
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

    return await Reminder.db.updateRow(session, updated);
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
}
