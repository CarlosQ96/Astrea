import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'client_provider.dart';

/// Watches auth state via ValueListenable from Serverpod.
final authInfoProvider = StreamProvider<AuthSuccess?>((ref) {
  final client = ref.watch(clientProvider);
  final sessionManager = client.authSessionManager;

  // Convert ValueListenable to Stream
  final controller = StreamController<AuthSuccess?>.broadcast();
  controller.add(sessionManager.authInfo);

  void listener() {
    controller.add(sessionManager.authInfo);
  }

  sessionManager.authInfoListenable.addListener(listener);

  ref.onDispose(() {
    sessionManager.authInfoListenable.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});

/// Returns true if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authInfo = ref.watch(authInfoProvider);
  return authInfo.maybeWhen(
    data: (info) => info != null,
    orElse: () => false,
  );
});
