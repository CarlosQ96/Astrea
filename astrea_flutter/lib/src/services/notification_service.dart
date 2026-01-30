import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

import '../theme/astrea_colors.dart';

/// Service for managing local notifications using awesome_notifications.
class NotificationService {
  static const String _channelKey = 'reminder_channel';
  static const String _channelGroupKey = 'reminder_group';

  /// Initialize the notification system. Call in main() before runApp().
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/res_notification_icon',
      [
        NotificationChannel(
          channelGroupKey: _channelGroupKey,
          channelKey: _channelKey,
          channelName: 'Reminders',
          channelDescription: 'Notification channel for reminder alerts',
          defaultColor: AstreaColors.starlightCyan,
          ledColor: AstreaColors.starlightCyan,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          criticalAlerts: true,
          icon: 'resource://drawable/res_notification_icon',
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _channelGroupKey,
          channelGroupName: 'Reminder Notifications',
        ),
      ],
      debug: true,
    );
  }

  /// Set up notification action listeners. Call in app's initState.
  static void setListeners({
    required Future<void> Function(ReceivedAction) onActionReceived,
  }) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
    _onActionCallback = onActionReceived;
  }

  static Future<void> Function(ReceivedAction)? _onActionCallback;

  /// Request notification permissions from the user.
  static Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
    return true;
  }

  /// Schedule a notification for a reminder.
  ///
  /// [reminderId] - The database ID of the reminder (used as notification ID).
  /// [title] - The reminder title.
  /// [body] - Optional description.
  /// [scheduledTime] - When to show the notification (in UTC).
  static Future<void> scheduleReminder({
    required int reminderId,
    required String title,
    String? body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    final localScheduledTime = scheduledTime.toLocal();
    final secondsUntil = localScheduledTime.difference(now).inSeconds;

    // Don't schedule if time is in the past
    if (secondsUntil <= 0) {
      return;
    }

    // Use interval for short durations (under 60 seconds) for better precision
    // Use calendar for longer durations
    final NotificationSchedule schedule;
    if (secondsUntil < 60) {
      schedule = NotificationInterval(
        interval: Duration(seconds: secondsUntil),
        allowWhileIdle: true,
        preciseAlarm: true,
        repeats: false,
      );
    } else {
      schedule = NotificationCalendar.fromDate(
        date: localScheduledTime,
        allowWhileIdle: true,
        preciseAlarm: true,
      );
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminderId,
        channelKey: _channelKey,
        title: title,
        body: body ?? 'Tap to view details',
        icon: 'resource://drawable/res_notification_icon',
        largeIcon: 'resource://mipmap/ic_launcher',
        color: AstreaColors.starlightCyan,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
        displayOnForeground: true,
        displayOnBackground: true,
        payload: {
          'reminderId': reminderId.toString(),
        },
      ),
      schedule: schedule,
      actionButtons: [
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Snooze 15m',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'COMPLETE',
          label: 'Complete',
          autoDismissible: true,
          color: AstreaColors.success,
        ),
      ],
    );
  }

  /// Show an immediate test notification.
  static Future<void> showTestNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 99999,
        channelKey: _channelKey,
        title: 'Test Notification ✨',
        body: 'This is a test notification from Astrea!',
        icon: 'resource://drawable/res_notification_icon',
        largeIcon: 'resource://mipmap/ic_launcher',
        color: AstreaColors.starlightCyan,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
    );
  }

  /// Cancel a scheduled notification.
  static Future<void> cancelReminder(int reminderId) async {
    await AwesomeNotifications().cancel(reminderId);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Reschedule a notification (for snooze).
  static Future<void> snoozeReminder({
    required int reminderId,
    required String title,
    String? body,
    required int snoozeMinutes,
  }) async {
    final newTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    await scheduleReminder(
      reminderId: reminderId,
      title: title,
      body: body,
      scheduledTime: newTime.toUtc(),
    );
  }

  // Static callback methods required by awesome_notifications

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('Notification created: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Action received: ${receivedAction.buttonKeyPressed}');
    if (_onActionCallback != null) {
      await _onActionCallback!(receivedAction);
    }
  }
}
