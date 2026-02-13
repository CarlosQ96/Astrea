import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astrea_flutter/src/providers/subscription_provider.dart';

void main() {
  group('DailyMessageNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with 0 on first launch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(dailyMessageProvider.future);
      expect(count, 0);
    });

    test('resumes count from same day', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'daily_message_count': 5,
        'daily_message_date': today,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(dailyMessageProvider.future);
      expect(count, 5);
    });

    test('resets count on new day', () async {
      SharedPreferences.setMockInitialValues({
        'daily_message_count': 8,
        'daily_message_date': '2020-01-01',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(dailyMessageProvider.future);
      expect(count, 0);
    });

    test('tryUseMessage always returns true for pro users', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      final allowed = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(true);
      expect(allowed, true);
    });

    test('tryUseMessage does not increment count for pro users', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(true);

      // Pro users bypass entirely — count stays at 0
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('daily_message_count'), 0);
    });

    test('tryUseMessage increments count for free users', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      final allowed = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(false);
      expect(allowed, true);

      final count = await container.read(dailyMessageProvider.future);
      expect(count, 1);
    });

    test('tryUseMessage blocks after reaching limit', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'daily_message_count': freeMessageLimit,
        'daily_message_date': today,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      final allowed = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(false);
      expect(allowed, false);
    });

    test('tryUseMessage allows exactly freeMessageLimit messages', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      for (int i = 0; i < freeMessageLimit; i++) {
        final allowed = await container
            .read(dailyMessageProvider.notifier)
            .tryUseMessage(false);
        expect(allowed, true, reason: 'Message ${i + 1} should be allowed');
      }

      // The next message should be blocked
      final blocked = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(false);
      expect(blocked, false);
    });

    test('tryUseMessage resets on new day even mid-session', () async {
      SharedPreferences.setMockInitialValues({
        'daily_message_count': freeMessageLimit,
        'daily_message_date': '2020-01-01',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      // Should allow because the saved date is old
      final allowed = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(false);
      expect(allowed, true);
    });

    test('pro users bypass even when count is at limit', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'daily_message_count': freeMessageLimit,
        'daily_message_date': today,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      final allowed = await container
          .read(dailyMessageProvider.notifier)
          .tryUseMessage(true);
      expect(allowed, true);
    });
  });

  group('freeMessageLimit', () {
    test('is 5', () {
      expect(freeMessageLimit, 5);
    });
  });

  group('remainingMessagesProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns -1 for pro users (unlimited)', () {
      final container = ProviderContainer(
        overrides: [isProProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      expect(container.read(remainingMessagesProvider), -1);
    });

    test('returns freeMessageLimit when no messages sent', () async {
      final container = ProviderContainer(
        overrides: [isProProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);
      // Allow Riverpod state to propagate
      await Future.delayed(Duration.zero);

      expect(container.read(remainingMessagesProvider), freeMessageLimit);
    });

    test('decreases as messages are sent', () async {
      final container = ProviderContainer(
        overrides: [isProProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      for (int i = 0; i < 3; i++) {
        await container
            .read(dailyMessageProvider.notifier)
            .tryUseMessage(false);
      }

      await Future.delayed(Duration.zero);

      expect(
        container.read(remainingMessagesProvider),
        freeMessageLimit - 3,
      );
    });

    test('reaches 0 when limit is exhausted', () async {
      final container = ProviderContainer(
        overrides: [isProProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      await container.read(dailyMessageProvider.future);

      for (int i = 0; i < freeMessageLimit; i++) {
        await container
            .read(dailyMessageProvider.notifier)
            .tryUseMessage(false);
      }

      await Future.delayed(Duration.zero);

      expect(container.read(remainingMessagesProvider), 0);
    });
  });
}
