import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stream of customer info updates from RevenueCat.
/// Silently returns empty stream if RevenueCat isn't initialized.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  final controller = StreamController<CustomerInfo>();

  try {
    Purchases.getCustomerInfo().then((info) {
      if (!controller.isClosed) controller.add(info);
    }).catchError((e) {
      debugPrint('RevenueCat getCustomerInfo failed: $e');
    });

    void onUpdate(CustomerInfo info) {
      if (!controller.isClosed) controller.add(info);
    }

    Purchases.addCustomerInfoUpdateListener(onUpdate);

    ref.onDispose(() {
      Purchases.removeCustomerInfoUpdateListener(onUpdate);
      controller.close();
    });
  } catch (e) {
    debugPrint('RevenueCat customerInfoProvider failed: $e');
    ref.onDispose(() => controller.close());
  }

  return controller.stream;
});

/// Whether the current user has the "Astrea Pro" entitlement.
final isProProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo.whenOrNull(
    data: (info) => info.entitlements.active.containsKey('Astrea Pro'),
  ) ??
      false;
});

/// Get current offerings (available packages to purchase).
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    debugPrint('RevenueCat getOfferings failed: $e');
    return Offerings({});
  }
});

/// Daily message counter for free users.
const int freeMessageLimit = 25;
const String _messageCountKey = 'daily_message_count';
const String _messageDateKey = 'daily_message_date';

/// Tracks daily message usage. Resets each day.
class DailyMessageNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_messageDateKey);

    if (savedDate != today) {
      // New day — reset counter
      await prefs.setInt(_messageCountKey, 0);
      await prefs.setString(_messageDateKey, today);
      return 0;
    }

    return prefs.getInt(_messageCountKey) ?? 0;
  }

  /// Increment counter. Returns true if message is allowed.
  Future<bool> tryUseMessage(bool isPro) async {
    if (isPro) return true; // Pro users have no limit

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_messageDateKey);

    int count;
    if (savedDate != today) {
      count = 0;
      await prefs.setString(_messageDateKey, today);
    } else {
      count = prefs.getInt(_messageCountKey) ?? 0;
    }

    if (count >= freeMessageLimit) return false;

    count++;
    await prefs.setInt(_messageCountKey, count);
    state = AsyncData(count);
    return true;
  }
}

final dailyMessageProvider =
    AsyncNotifierProvider<DailyMessageNotifier, int>(DailyMessageNotifier.new);

/// Remaining messages for today (free users).
final remainingMessagesProvider = Provider<int>((ref) {
  final isPro = ref.watch(isProProvider);
  if (isPro) return -1; // Unlimited

  final count = ref.watch(dailyMessageProvider);
  return count.whenOrNull(data: (c) => freeMessageLimit - c) ??
      freeMessageLimit;
});
