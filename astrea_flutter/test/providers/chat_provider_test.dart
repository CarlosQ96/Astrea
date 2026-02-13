import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astrea_flutter/src/providers/chat_provider.dart';

void main() {
  group('ChatMessage', () {
    test('creates with auto-generated id', () {
      final msg = ChatMessage(
        text: 'Hello',
        isUser: true,
        timestamp: DateTime.now(),
      );
      expect(msg.id, isNotEmpty);
    });

    test('creates with custom id', () {
      final msg = ChatMessage(
        id: 'custom-id',
        text: 'Hello',
        isUser: true,
        timestamp: DateTime.now(),
      );
      expect(msg.id, 'custom-id');
    });

    test('defaults actionParsed to false', () {
      final msg = ChatMessage(
        text: 'Hello',
        isUser: true,
        timestamp: DateTime.now(),
      );
      expect(msg.actionParsed, false);
    });

    test('defaults isDissolving to false', () {
      final msg = ChatMessage(
        text: 'Hello',
        isUser: true,
        timestamp: DateTime.now(),
      );
      expect(msg.isDissolving, false);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ChatMessage(
        id: 'test-id',
        text: 'Hello',
        isUser: true,
        timestamp: DateTime(2024, 1, 1),
        intent: 'create_reminder',
        actionParsed: true,
      );

      final copy = original.copyWith(isDissolving: true);

      expect(copy.id, 'test-id');
      expect(copy.text, 'Hello');
      expect(copy.isUser, true);
      expect(copy.intent, 'create_reminder');
      expect(copy.actionParsed, true);
      expect(copy.isDissolving, true);
    });

    test('copyWith overrides specified fields', () {
      final original = ChatMessage(
        text: 'Hello',
        isUser: true,
        timestamp: DateTime(2024, 1, 1),
      );

      final copy = original.copyWith(text: 'Goodbye', isUser: false);

      expect(copy.text, 'Goodbye');
      expect(copy.isUser, false);
    });
  });

  group('MessageLimitExceededException', () {
    test('stores the limit value', () {
      const exception = MessageLimitExceededException(10);
      expect(exception.limit, 10);
    });

    test('implements Exception', () {
      const exception = MessageLimitExceededException(10);
      expect(exception, isA<Exception>());
    });
  });

  group('ChatMessagesNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with empty list', () {
      expect(container.read(chatMessagesProvider), isEmpty);
    });

    test('addUserMessage appends a user message', () {
      container.read(chatMessagesProvider.notifier).addUserMessage('Hello');

      final messages = container.read(chatMessagesProvider);
      expect(messages, hasLength(1));
      expect(messages.first.text, 'Hello');
      expect(messages.first.isUser, true);
    });

    test('addAiMessage appends an AI message', () {
      container.read(chatMessagesProvider.notifier).addAiMessage(
            ChatResponse(
              intent: 'create_reminder',
              response: 'Done!',
              actionParsed: true,
            ),
          );

      final messages = container.read(chatMessagesProvider);
      expect(messages, hasLength(1));
      expect(messages.first.text, 'Done!');
      expect(messages.first.isUser, false);
      expect(messages.first.intent, 'create_reminder');
      expect(messages.first.actionParsed, true);
    });

    test('messages maintain order', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('First');
      notifier.addAiMessage(
        ChatResponse(
          intent: 'general',
          response: 'Second',
          actionParsed: false,
        ),
      );
      notifier.addUserMessage('Third');

      final messages = container.read(chatMessagesProvider);
      expect(messages, hasLength(3));
      expect(messages[0].text, 'First');
      expect(messages[1].text, 'Second');
      expect(messages[2].text, 'Third');
    });

    test('markDissolving sets flag on correct message', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('Keep');
      notifier.addUserMessage('Dissolve');

      final messages = container.read(chatMessagesProvider);
      final dissolveId = messages[1].id;

      notifier.markDissolving(dissolveId);

      final updated = container.read(chatMessagesProvider);
      expect(updated[0].isDissolving, false);
      expect(updated[1].isDissolving, true);
    });

    test('markMultipleDissolving sets flag on all specified messages', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('A');
      notifier.addUserMessage('B');
      notifier.addUserMessage('C');

      final messages = container.read(chatMessagesProvider);
      final ids = {messages[0].id, messages[2].id};

      notifier.markMultipleDissolving(ids);

      final updated = container.read(chatMessagesProvider);
      expect(updated[0].isDissolving, true);
      expect(updated[1].isDissolving, false);
      expect(updated[2].isDissolving, true);
    });

    test('removeMessage removes the correct message', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('Keep');
      notifier.addUserMessage('Remove');

      final messages = container.read(chatMessagesProvider);
      final removeId = messages[1].id;

      notifier.removeMessage(removeId);

      final updated = container.read(chatMessagesProvider);
      expect(updated, hasLength(1));
      expect(updated.first.text, 'Keep');
    });

    test('dissolveAll marks every message as dissolving', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('A');
      notifier.addUserMessage('B');
      notifier.addUserMessage('C');

      notifier.dissolveAll();

      final updated = container.read(chatMessagesProvider);
      for (final msg in updated) {
        expect(msg.isDissolving, true);
      }
    });

    test('dissolveOldMessages keeps last 2 messages', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('Old 1');
      notifier.addUserMessage('Old 2');
      notifier.addUserMessage('Recent user');
      notifier.addAiMessage(
        ChatResponse(
          intent: 'general',
          response: 'Recent AI',
          actionParsed: false,
        ),
      );

      notifier.dissolveOldMessages();

      final updated = container.read(chatMessagesProvider);
      // First two should be dissolving
      expect(updated[0].isDissolving, true);
      expect(updated[1].isDissolving, true);
      // Last two should stay visible
      expect(updated[2].isDissolving, false);
      expect(updated[3].isDissolving, false);
      expect(updated[2].text, 'Recent user');
      expect(updated[3].text, 'Recent AI');
    });

    test('dissolveOldMessages does nothing with 2 or fewer messages', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('Only');
      notifier.addAiMessage(
        ChatResponse(
          intent: 'general',
          response: 'Response',
          actionParsed: false,
        ),
      );

      notifier.dissolveOldMessages();

      final updated = container.read(chatMessagesProvider);
      expect(updated, hasLength(2));
      expect(updated[0].isDissolving, false);
      expect(updated[1].isDissolving, false);
    });

    test('clear removes all messages', () {
      final notifier = container.read(chatMessagesProvider.notifier);
      notifier.addUserMessage('A');
      notifier.addUserMessage('B');

      notifier.clear();

      expect(container.read(chatMessagesProvider), isEmpty);
    });
  });

  group('chatLoadingProvider', () {
    test('starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chatLoadingProvider), false);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(chatLoadingProvider.notifier).state = true;
      expect(container.read(chatLoadingProvider), true);
    });
  });
}
