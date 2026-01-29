import 'package:astrea_client/astrea_client.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'src/pages/auth/auth_wrapper.dart';
import 'src/providers/client_provider.dart';
import 'src/services/notification_service.dart';
import 'src/theme/astrea_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications and request permissions early
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

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

class AstreaApp extends StatefulWidget {
  const AstreaApp({super.key});

  @override
  State<AstreaApp> createState() => _AstreaAppState();
}

class _AstreaAppState extends State<AstreaApp> {
  @override
  void initState() {
    super.initState();
    // Set up notification action listeners for foreground handling
    NotificationService.setListeners(
      onActionReceived: _handleNotificationAction,
    );
  }

  Future<void> _handleNotificationAction(ReceivedAction action) async {
    final reminderId = action.payload?['reminderId'];
    if (reminderId == null) return;

    switch (action.buttonKeyPressed) {
      case 'SNOOZE':
        // Snooze for 15 minutes
        await NotificationService.snoozeReminder(
          reminderId: int.parse(reminderId),
          title: action.title ?? 'Reminder',
          body: action.body,
          snoozeMinutes: 15,
        );
        break;
      case 'COMPLETE':
        // Mark as complete - will be handled by provider when app opens
        debugPrint('Complete action for reminder: $reminderId');
        break;
      default:
        // User tapped notification body - navigate to app
        debugPrint('Notification tapped: $reminderId');
        break;
    }
  }

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
