import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  const testUserId = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';

  withServerpod('Given UserSettingsEndpoint', (sessionBuilder, endpoints) {
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

      group('get', () {
        test('should create default settings for new user', () async {
          final settings = await endpoints.userSettings.get(authSessionBuilder);

          expect(settings.id, isNotNull);
          expect(settings.defaultSnoozeMinutes, 15);
          expect(settings.voiceEnabled, true);
          expect(settings.timezone, 'UTC');
        });

        test('should return existing settings', () async {
          await endpoints.userSettings.update(
            authSessionBuilder,
            defaultSnoozeMinutes: 30,
          );

          final settings = await endpoints.userSettings.get(authSessionBuilder);

          expect(settings.defaultSnoozeMinutes, 30);
        });
      });

      group('update', () {
        test('should update snooze minutes', () async {
          final updated = await endpoints.userSettings.update(
            authSessionBuilder,
            defaultSnoozeMinutes: 20,
          );

          expect(updated.defaultSnoozeMinutes, 20);
        });

        test('should update quiet hours', () async {
          final updated = await endpoints.userSettings.update(
            authSessionBuilder,
            quietHoursStart: '22:00',
            quietHoursEnd: '07:00',
          );

          expect(updated.quietHoursStart, '22:00');
          expect(updated.quietHoursEnd, '07:00');
        });

        test('should update voice enabled', () async {
          final updated = await endpoints.userSettings.update(
            authSessionBuilder,
            voiceEnabled: false,
          );

          expect(updated.voiceEnabled, false);
        });

        test('should update timezone', () async {
          final updated = await endpoints.userSettings.update(
            authSessionBuilder,
            timezone: 'America/Los_Angeles',
          );

          expect(updated.timezone, 'America/Los_Angeles');
        });

        test('should update multiple fields at once', () async {
          final updated = await endpoints.userSettings.update(
            authSessionBuilder,
            defaultSnoozeMinutes: 10,
            voiceEnabled: false,
            timezone: 'Europe/London',
          );

          expect(updated.defaultSnoozeMinutes, 10);
          expect(updated.voiceEnabled, false);
          expect(updated.timezone, 'Europe/London');
        });
      });
    });

    group('when unauthenticated', () {
      late TestSessionBuilder unauthSessionBuilder;

      setUp(() {
        unauthSessionBuilder = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.unauthenticated(),
        );
      });

      test('get should throw ServerpodUnauthenticatedException', () async {
        final future = endpoints.userSettings.get(unauthSessionBuilder);

        await expectLater(
          future,
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('update should throw ServerpodUnauthenticatedException', () async {
        final future = endpoints.userSettings.update(
          unauthSessionBuilder,
          defaultSnoozeMinutes: 30,
        );

        await expectLater(
          future,
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });
    });
  });
}
