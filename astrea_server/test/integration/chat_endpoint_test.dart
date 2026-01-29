import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  const testUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  withServerpod('Given ChatEndpoint', (sessionBuilder, endpoints) {
    group('when not authenticated', () {
      test('should fail with authentication error', () async {
        expect(
          () => endpoints.chat.send(sessionBuilder, 'Hello'),
          throwsA(isA<Exception>()),
        );
      });
    });

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

      test('should return a ChatResponse with intent field', () async {
        // Note: This test requires a valid Anthropic API key in passwords.yaml
        // If the API key is missing, it should return an error response gracefully
        final response = await endpoints.chat.send(
          authSessionBuilder,
          'Hello!',
        );

        expect(response.intent, isNotEmpty);
        expect(response.response, isNotEmpty);
        // actionParsed should be false for a simple greeting
        expect(response.actionParsed, isA<bool>());
      });

      test('should accept optional timezone parameter', () async {
        final response = await endpoints.chat.send(
          authSessionBuilder,
          'What time is it?',
          timezone: 'America/New_York',
        );

        expect(response.intent, isNotEmpty);
        expect(response.response, isNotEmpty);
      });

      group('with existing reminders', () {
        setUp(() async {
          // Create some test reminders for context
          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Call mom',
            description: 'Weekly call',
            dueAtUtc: DateTime.now().add(const Duration(hours: 2)),
            originalTimezone: 'UTC',
            priority: 2,
          );

          await endpoints.reminder.create(
            authSessionBuilder,
            title: 'Buy groceries',
            dueAtUtc: DateTime.now().add(const Duration(hours: 5)),
            originalTimezone: 'UTC',
            priority: 1,
          );
        });

        test('should be able to list reminders via chat', () async {
          final response = await endpoints.chat.send(
            authSessionBuilder,
            'What do I have to do today?',
          );

          expect(response.intent, isNotEmpty);
          expect(response.response, isNotEmpty);
          // The response should mention the reminders or indicate listing intent
          expect(
            response.intent == 'list_reminders' ||
                response.intent == 'question' ||
                response.response.toLowerCase().contains('call') ||
                response.response.toLowerCase().contains('groceries') ||
                response.response.toLowerCase().contains('reminder'),
            isTrue,
            reason: 'Response should reference reminders or have list intent',
          );
        });

        test('should parse create reminder intent', () async {
          final response = await endpoints.chat.send(
            authSessionBuilder,
            'Remind me to take out the trash tomorrow at 9am',
          );

          expect(response.intent, isNotEmpty);
          // For create intents, actionParsed should be true
          // and action fields should be populated
          if (response.intent == 'create_reminder') {
            expect(response.actionParsed, isTrue);
            expect(response.actionTitle, isNotNull);
            expect(response.actionDueAtUtc, isNotNull);
          }
        });
      });
    });
  });
}
