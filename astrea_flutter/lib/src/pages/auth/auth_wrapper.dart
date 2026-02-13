import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/fcm_service.dart';
import '../chat/chat_page.dart';
import 'login_page.dart';

/// Routes to login or main app based on auth status.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authInfo = ref.watch(authInfoProvider);

    // Listen to auth changes and start/stop sync (side effect, not in build)
    ref.listen(authInfoProvider, (previous, next) {
      next.whenData((info) async {
        if (info != null) {
          // Identify user to RevenueCat (may fail with test key in release)
          try {
            await Purchases.logIn(info.authUserId.toString());
          } catch (e) {
            debugPrint('RevenueCat logIn failed: $e');
          }

          ref.read(syncProvider.notifier).startSync();
          // Register FCM token for push notifications
          FcmService.registerToken();
        } else {
          // Log out of RevenueCat on sign out
          try {
            await Purchases.logOut();
          } catch (e) {
            debugPrint('RevenueCat logOut failed: $e');
          }

          ref.read(syncProvider.notifier).stopSync();
          // Unregister FCM token on logout
          FcmService.unregisterToken();
        }
      });
    });

    // Show login page while loading instead of hanging on spinner
    return authInfo.when(
      data: (info) {
        if (info != null) {
          return const ChatPage();
        }
        return const LoginPage();
      },
      loading: () => const LoginPage(),
      error: (_, _) => const LoginPage(),
    );
  }
}
