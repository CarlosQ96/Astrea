import 'dart:async';

import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'client_provider.dart';
import 'reminders_provider.dart';

/// Manages real-time sync subscription for reminder updates.
/// Subscribes to the server's streaming endpoint and refreshes
/// the reminders list when changes occur on other devices.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState());

  final Ref _ref;
  StreamSubscription<ReminderSyncEvent>? _subscription;

  /// Start listening to sync events from the server.
  void startSync() {
    if (state.isConnected) return;

    state = state.copyWith(isConnecting: true, error: null);

    try {
      final client = _ref.read(clientProvider);
      final stream = client.sync.subscribeToReminders();

      _subscription = stream.listen(
        _handleSyncEvent,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      state = state.copyWith(isConnected: true, isConnecting: false);
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Failed to connect: $e',
      );
    }
  }

  /// Stop listening to sync events.
  void stopSync() {
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isConnected: false, isConnecting: false);
  }

  void _handleSyncEvent(ReminderSyncEvent event) {
    // Update last event for debugging/UI feedback
    state = state.copyWith(
      lastEventType: event.eventType,
      lastEventTime: event.timestamp,
    );

    // Sync local notifications based on event type
    _syncNotification(event);

    // Invalidate reminders provider to refresh the list
    _ref.invalidate(remindersProvider);
  }

  /// Update local notification based on sync event from another device.
  Future<void> _syncNotification(ReminderSyncEvent event) async {
    final reminder = event.reminder;

    switch (event.eventType) {
      case 'created':
      case 'updated':
        if (reminder == null) break;
        // Cancel if completed, otherwise schedule/reschedule
        if (reminder.isCompleted) {
          await NotificationService.cancelReminder(event.reminderId);
        } else {
          final dueTime = reminder.snoozedUntilUtc ?? reminder.dueAtUtc;
          // Cancel existing before scheduling (handles past->future time changes)
          await NotificationService.cancelReminder(event.reminderId);
          // scheduleReminder already skips if time is in the past
          await NotificationService.scheduleReminder(
            reminderId: reminder.id!,
            title: reminder.title,
            body: reminder.description,
            scheduledTime: dueTime,
          );
        }
        break;
      case 'snoozed':
        if (reminder == null) break;
        // Cancel existing notification first, then reschedule
        await NotificationService.cancelReminder(event.reminderId);
        if (reminder.snoozedUntilUtc != null) {
          await NotificationService.scheduleReminder(
            reminderId: reminder.id!,
            title: reminder.title,
            body: reminder.description,
            scheduledTime: reminder.snoozedUntilUtc!,
          );
        }
        break;
      case 'completed':
      case 'deleted':
        // Cancel the notification
        await NotificationService.cancelReminder(event.reminderId);
        break;
    }
  }

  void _handleError(Object error) {
    state = state.copyWith(
      isConnected: false,
      error: 'Sync error: $error',
    );

    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        startSync();
      }
    });
  }

  void _handleDisconnect() {
    state = state.copyWith(isConnected: false);

    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        startSync();
      }
    });
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}

/// State for sync connection.
class SyncState {
  const SyncState({
    this.isConnected = false,
    this.isConnecting = false,
    this.error,
    this.lastEventType,
    this.lastEventTime,
  });

  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final String? lastEventType;
  final DateTime? lastEventTime;

  SyncState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    String? lastEventType,
    DateTime? lastEventTime,
  }) {
    return SyncState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
      lastEventType: lastEventType ?? this.lastEventType,
      lastEventTime: lastEventTime ?? this.lastEventTime,
    );
  }
}

/// Provider for sync state management.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
