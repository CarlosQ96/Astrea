import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  const testUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  withServerpod('Given ReminderEndpoint', (sessionBuilder, endpoints) {
    group('when authenticated', () {
      late TestSessionBuilder authSessionBuilder;

      setUp(() {
        authSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testUserId,
            {},
          ),
        );
      });

      group('create', () {
        test('should create a reminder and return it with id', () async {
          final reminder = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Test Reminder',
            description: 'Test description',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'America/New_York',
            priority: 2,
          );

          expect(reminder.id, isNotNull);
          expect(reminder.title, 'Test Reminder');
          expect(reminder.description, 'Test description');
          expect(reminder.priority, 2);
          expect(reminder.isCompleted, false);
        });
      });

      group('read', () {
        test(
          'should return reminder when it exists and belongs to user',
          () async {
            final created = await endpoints.reminder.create(
              authSessionBuilder,
              title: 'Read Test',
              dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
              originalTimezone: 'UTC',
            );

            final found = await endpoints.reminder.read(
              authSessionBuilder,
              created.id!,
            );

            expect(found, isNotNull);
            expect(found!.id, created.id);
            expect(found.title, 'Read Test');
          },
        );

        test('should return null when reminder does not exist', () async {
          final found = await endpoints.reminder.read(
            authSessionBuilder,
            99999,
          );

          expect(found, isNull);
        });
      });

      group('update', () {
        test('should update reminder fields', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Original Title',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final updated = await endpoints.reminder.update(
            authSessionBuilder,
            created.id!,
            title: 'Updated Title',
            priority: 3,
          );

          expect(updated, isNotNull);
          expect(updated!.title, 'Updated Title');
          expect(updated.priority, 3);
          expect(updated.revision, 2);
        });
      });

      group('delete', () {
        test('should delete reminder and return true', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Delete Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final deleted = await endpoints.reminder.delete(
            authSessionBuilder,
            created.id!,
          );

          expect(deleted, true);

          final found = await endpoints.reminder.read(
            authSessionBuilder,
            created.id!,
          );
          expect(found, isNull);
        });

        test('should return false when reminder does not exist', () async {
          final deleted = await endpoints.reminder.delete(
            authSessionBuilder,
            99999,
          );

          expect(deleted, false);
        });
      });

      group('list', () {
        test('should return only active reminders by default', () async {
          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Active Reminder',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final completedReminder = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Completed Reminder',
            dueAtUtc: DateTime.now().add(const Duration(hours: 2)),
            originalTimezone: 'UTC',
          );
          await endpoints.reminder.complete(
            authSessionBuilder,
            completedReminder.id!,
          );

          final reminders = await endpoints.reminder.list(authSessionBuilder);

          expect(reminders.length, 1);
          expect(reminders.first.title, 'Active Reminder');
        });

        test('should include completed reminders when requested', () async {
          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Active Reminder',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final completedReminder = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Completed Reminder',
            dueAtUtc: DateTime.now().add(const Duration(hours: 2)),
            originalTimezone: 'UTC',
          );
          await endpoints.reminder.complete(
            authSessionBuilder,
            completedReminder.id!,
          );

          final reminders = await endpoints.reminder.list(
            authSessionBuilder,
            includeCompleted: true,
          );

          expect(reminders.length, 2);
        });
      });

      group('complete', () {
        test('should mark reminder as completed', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Complete Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final completed = await endpoints.reminder.complete(
            authSessionBuilder,
            created.id!,
          );

          expect(completed, isNotNull);
          expect(completed!.isCompleted, true);
          expect(completed.revision, 2);
        });
      });

      group('snooze', () {
        test('should set snoozedUntilUtc', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Snooze Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final snoozed = await endpoints.reminder.snooze(
            authSessionBuilder,
            created.id!,
            15,
          );

          expect(snoozed, isNotNull);
          expect(snoozed!.snoozedUntilUtc, isNotNull);
          expect(snoozed.revision, 2);
        });

        test('should throw ArgumentError for zero minutes', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Snooze Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          expect(
            () => endpoints.reminder.snooze(authSessionBuilder, created.id!, 0),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('should throw ArgumentError for negative minutes', () async {
          final created = await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Snooze Test',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          expect(
            () =>
                endpoints.reminder.snooze(authSessionBuilder, created.id!, -5),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('listDue', () {
        test('should return reminders that are past due', () async {
          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Past Due',
            dueAtUtc: DateTime.now().subtract(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Future Due',
            dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
            originalTimezone: 'UTC',
          );

          final dueReminders = await endpoints.reminder.listDue(
            authSessionBuilder,
          );

          expect(dueReminders.length, 1);
          expect(dueReminders.first.title, 'Past Due');
        });
      });

      group('validation', () {
        test(
          'should throw ArgumentError for invalid priority in create',
          () async {
            expect(
              () => endpoints.reminder.create(
                authSessionBuilder,
                title: 'Test',
                dueAtUtc: DateTime.now(),
                originalTimezone: 'UTC',
                priority: 5,
              ),
              throwsA(isA<ArgumentError>()),
            );
          },
        );

        test('should throw ArgumentError for priority 0 in create', () async {
          expect(
            () => endpoints.reminder.create(
              authSessionBuilder,
              title: 'Test',
              dueAtUtc: DateTime.now(),
              originalTimezone: 'UTC',
              priority: 0,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });
    });

    group('ownership enforcement', () {
      const userAId = 'a1a1a1a1-a1a1-4a1a-8a1a-a1a1a1a1a1a1';
      const userBId = 'b2b2b2b2-b2b2-4b2b-8b2b-b2b2b2b2b2b2';

      late TestSessionBuilder userASession;
      late TestSessionBuilder userBSession;

      setUp(() {
        userASession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userAId,
            {},
          ),
        );
        userBSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userBId,
            {},
          ),
        );
      });

      test('user B cannot read user A reminder', () async {
        final created = await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final found = await endpoints.reminder.read(userBSession, created.id!);
        expect(found, isNull);
      });

      test('user B cannot update user A reminder', () async {
        final created = await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final updated = await endpoints.reminder.update(
          userBSession,
          created.id!,
          title: 'Hacked',
        );
        expect(updated, isNull);
      });

      test('user B cannot delete user A reminder', () async {
        final created = await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final deleted = await endpoints.reminder.delete(
          userBSession,
          created.id!,
        );
        expect(deleted, false);
      });

      test('user B cannot complete user A reminder', () async {
        final created = await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final completed = await endpoints.reminder.complete(
          userBSession,
          created.id!,
        );
        expect(completed, isNull);
      });

      test('user B cannot snooze user A reminder', () async {
        final created = await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final snoozed = await endpoints.reminder.snooze(
          userBSession,
          created.id!,
          15,
        );
        expect(snoozed, isNull);
      });

      test('user A list does not include user B reminders', () async {
        await endpoints.reminder.create(
          userASession,
          title: 'User A Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        await endpoints.reminder.create(
          userBSession,
          title: 'User B Reminder',
          dueAtUtc: DateTime.now().add(const Duration(hours: 1)),
          originalTimezone: 'UTC',
        );

        final userAReminders = await endpoints.reminder.list(userASession);
        expect(userAReminders.length, 1);
        expect(userAReminders.first.title, 'User A Reminder');
      });
    });

    group('when unauthenticated', () {
      late TestSessionBuilder unauthSessionBuilder;

      setUp(() {
        unauthSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.unauthenticated(),
        );
      });

      test('create should throw ServerpodUnauthenticatedException', () async {
        final future = endpoints.reminder.create(
          unauthSessionBuilder,
          title: 'Test',
          dueAtUtc: DateTime.now(),
          originalTimezone: 'UTC',
        );

        await expectLater(
          future,
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });
    });
  });
}
