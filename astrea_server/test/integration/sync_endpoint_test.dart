import 'dart:async';

import 'package:astrea_server/src/endpoints/sync_endpoint.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  const testUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  withServerpod('Given SyncEndpoint', (sessionBuilder, endpoints) {
    group('ReminderSyncBroadcaster', () {
      test('should broadcast created event when reminder is created', () async {
        final authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );

        // Set up a listener for broadcast events
        final receivedEvents = <String>[];
        final subscription = ReminderSyncBroadcaster.stream.listen((event) {
          receivedEvents.add(event.eventType);
        });

        // Create a reminder which should trigger a broadcast
        await endpoints.reminder.create(
          authSessionBuilder,
          title: 'Sync Test Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        // Wait a bit for the async event to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedEvents, contains('created'));

        await subscription.cancel();
      });

      test('should broadcast updated event when reminder is updated', () async {
        final authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );

        // Create a reminder first
        final reminder = await endpoints.reminder.create(
          authSessionBuilder,
          title: 'Update Test',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        // Set up a listener
        final receivedEvents = <String>[];
        final subscription = ReminderSyncBroadcaster.stream.listen((event) {
          receivedEvents.add(event.eventType);
        });

        // Update the reminder
        await endpoints.reminder.update(
          authSessionBuilder,
          reminder.id!,
          title: 'Updated Title',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedEvents, contains('updated'));

        await subscription.cancel();
      });

      test(
        'should broadcast completed event when reminder is completed',
        () async {
          final authSessionBuilder = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              testUserId,
              {},
            ),
          );

          final reminder = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Complete Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final receivedEvents = <String>[];
          final subscription = ReminderSyncBroadcaster.stream.listen((event) {
            receivedEvents.add(event.eventType);
          });

          await endpoints.reminder.complete(
            authSessionBuilder,
            reminder.id!,
          );

          await Future.delayed(const Duration(milliseconds: 100));

          expect(receivedEvents, contains('completed'));

          await subscription.cancel();
        },
      );

      test('should broadcast snoozed event when reminder is snoozed', () async {
        final authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );

        final reminder = await endpoints.reminder.create(
          authSessionBuilder,
          title: 'Snooze Test',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final receivedEvents = <String>[];
        final subscription = ReminderSyncBroadcaster.stream.listen((event) {
          receivedEvents.add(event.eventType);
        });

        await endpoints.reminder.snooze(
          authSessionBuilder,
          reminder.id!,
          15,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedEvents, contains('snoozed'));

        await subscription.cancel();
      });

      test('should broadcast deleted event when reminder is deleted', () async {
        final authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );

        final reminder = await endpoints.reminder.create(
          authSessionBuilder,
          title: 'Delete Test',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final receivedEvents = <String>[];
        final subscription = ReminderSyncBroadcaster.stream.listen((event) {
          receivedEvents.add(event.eventType);
        });

        await endpoints.reminder.delete(
          authSessionBuilder,
          reminder.id!,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedEvents, contains('deleted'));

        await subscription.cancel();
      });

      test('should include reminder data in event', () async {
        final authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );

        final completer = Completer<void>();
        int? receivedReminderId;
        String? receivedTitle;

        final subscription = ReminderSyncBroadcaster.stream.listen((event) {
          if (event.eventType == 'created' && event.reminder != null) {
            receivedReminderId = event.reminderId;
            receivedTitle = event.reminder!.title;
            completer.complete();
          }
        });

        final reminder = await endpoints.reminder.create(
          authSessionBuilder,
          title: 'Data Test Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        await completer.future.timeout(const Duration(seconds: 1));

        expect(receivedReminderId, reminder.id);
        expect(receivedTitle, 'Data Test Reminder');

        await subscription.cancel();
      });
    });
  });
}
