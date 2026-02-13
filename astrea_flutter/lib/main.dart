import 'package:astrea_client/astrea_client.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'firebase_options.dart';
import 'src/config/app_config.dart';
import 'src/pages/onboarding/onboarding_wrapper.dart';
import 'src/providers/client_provider.dart';
import 'src/providers/reminders_provider.dart';
import 'src/services/fcm_service.dart';
import 'src/services/notification_service.dart';
import 'src/theme/astrea_theme.dart';

Future<void> _initRevenueCat() async {
  await Purchases.setLogLevel(LogLevel.debug);

  const apiKey = 'test_jaxFGDhwbzRcCYooVQNkEHjzDGh';

  final configuration = PurchasesConfiguration(apiKey)
    ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat()
    ..shouldShowInAppMessagesAutomatically = true;

  await Purchases.configure(configuration);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for push notifications
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FcmService.initialize();

  // Initialize local notifications and request permissions
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // Only initialize RevenueCat in debug mode (test key crashes release builds)
  if (!kReleaseMode) {
    try {
      await _initRevenueCat();
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }
  }

  final config = await AppConfig.load();
  final serverUrl = config.apiUrl;

  final client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  // Set client for FCM service
  FcmService.setClient(client);

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

class AstreaApp extends ConsumerStatefulWidget {
  const AstreaApp({super.key});

  @override
  ConsumerState<AstreaApp> createState() => _AstreaAppState();
}

class _AstreaAppState extends ConsumerState<AstreaApp> {
  @override
  void initState() {
    super.initState();
    // Set up notification action listeners for foreground handling
    NotificationService.setListeners(
      onActionReceived: _handleNotificationAction,
    );

    // Set up FCM sync callback to refresh reminders
    FcmService.setOnSyncEvent((data) {
      debugPrint('FCM sync event received: $data');
      ref.invalidate(remindersProvider);
    });
  }

  Future<void> _handleNotificationAction(ReceivedAction action) async {
    final reminderId = action.payload?['reminderId'];
    if (reminderId == null) return;

    final client = ref.read(clientProvider);
    final id = int.parse(reminderId);

    switch (action.buttonKeyPressed) {
      case 'SNOOZE':
        // Snooze for 15 minutes - reschedule local notification
        await NotificationService.snoozeReminder(
          reminderId: id,
          title: action.title ?? 'Reminder',
          body: action.body,
          snoozeMinutes: 15,
        );
        // Also update server with new snooze time
        try {
          await client.reminder.snooze(id, 15);
          ref.invalidate(remindersProvider);
        } catch (e) {
          debugPrint('Failed to snooze on server: $e');
        }
        break;
      case 'COMPLETE':
        // Mark as complete on server
        try {
          await client.reminder.complete(id);
          await NotificationService.cancelReminder(id);
          ref.invalidate(remindersProvider);
          debugPrint('Reminder $id marked complete');
        } catch (e) {
          debugPrint('Failed to complete reminder: $e');
        }
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
      home: const OnboardingWrapper(),
    );
  }
}
