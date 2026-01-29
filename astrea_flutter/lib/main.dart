import 'package:astrea_client/astrea_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'src/pages/auth/auth_wrapper.dart';
import 'src/providers/client_provider.dart';
import 'src/theme/astrea_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serverUrl = await getServerUrl();

  final client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  // Initialize auth in background - don't block app startup
  client.auth.initialize();

  runApp(
    ProviderScope(
      overrides: [
        clientProvider.overrideWithValue(client),
      ],
      child: const AstreaApp(),
    ),
  );
}

class AstreaApp extends StatelessWidget {
  const AstreaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astrea',
      debugShowCheckedModeBanner: false,
      theme: AstreaTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
