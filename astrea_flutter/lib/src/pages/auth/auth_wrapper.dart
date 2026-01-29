import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
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
      next.whenData((info) {
        if (info != null) {
          ref.read(syncProvider.notifier).startSync();
        } else {
          ref.read(syncProvider.notifier).stopSync();
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
