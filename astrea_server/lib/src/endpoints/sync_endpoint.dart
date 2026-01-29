import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/reminder.dart';
import '../generated/reminder_sync_event.dart';

/// Broadcast controller for real-time reminder sync across all connected clients.
/// Uses a broadcast stream so multiple listeners can subscribe.
class ReminderSyncBroadcaster {
  ReminderSyncBroadcaster._();

  static final _controller = StreamController<ReminderSyncEvent>.broadcast();

  /// Stream that all sync subscribers listen to.
  static Stream<ReminderSyncEvent> get stream => _controller.stream;

  /// Broadcast a sync event to all connected clients.
  static void broadcast(ReminderSyncEvent event) {
    _controller.add(event);
  }

  /// Broadcast a reminder creation event.
  static void notifyCreated(Reminder reminder) {
    broadcast(
      ReminderSyncEvent(
        eventType: 'created',
        reminderId: reminder.id!,
        userId: reminder.userId,
        reminder: reminder,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Broadcast a reminder update event.
  static void notifyUpdated(Reminder reminder) {
    broadcast(
      ReminderSyncEvent(
        eventType: 'updated',
        reminderId: reminder.id!,
        userId: reminder.userId,
        reminder: reminder,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Broadcast a reminder completion event.
  static void notifyCompleted(Reminder reminder) {
    broadcast(
      ReminderSyncEvent(
        eventType: 'completed',
        reminderId: reminder.id!,
        userId: reminder.userId,
        reminder: reminder,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Broadcast a reminder snooze event.
  static void notifySnoozed(Reminder reminder) {
    broadcast(
      ReminderSyncEvent(
        eventType: 'snoozed',
        reminderId: reminder.id!,
        userId: reminder.userId,
        reminder: reminder,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Broadcast a reminder deletion event.
  /// Requires userId since reminder is already deleted.
  static void notifyDeleted(int reminderId, UuidValue userId) {
    broadcast(
      ReminderSyncEvent(
        eventType: 'deleted',
        reminderId: reminderId,
        userId: userId,
        reminder: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }
}

/// Streaming endpoint for real-time reminder synchronization.
/// Clients subscribe to receive events when reminders change.
class SyncEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Subscribe to real-time reminder updates for the authenticated user.
  /// Returns a stream of ReminderSyncEvent that the client can listen to.
  ///
  /// Events are filtered to only include reminders owned by the current user.
  Stream<ReminderSyncEvent> subscribeToReminders(Session session) async* {
    final userId = UuidValue.fromString(session.authenticated!.userIdentifier);

    // Listen to the broadcast stream and yield events for this user's reminders
    await for (final event in ReminderSyncBroadcaster.stream) {
      // Only yield events for reminders owned by this user
      // Using event.userId which is always set (even for delete events)
      if (event.userId == userId) {
        yield event;
      }
    }
  }
}
