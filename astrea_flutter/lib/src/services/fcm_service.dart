import 'dart:io';

import 'package:astrea_client/astrea_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.data}');

  // Handle sync event
  final type = message.data['type'];
  if (type == 'reminder_sync') {
    // The app will sync when it comes to foreground
    // For now, just log the event
    debugPrint('Reminder sync event: ${message.data['eventType']}');
  }
}

/// Service for handling Firebase Cloud Messaging (FCM) push notifications.
/// Manages token registration, background message handling, and sync events.
class FcmService {
  static FcmService? _instance;
  static FirebaseMessaging? _messaging;
  static Client? _client;
  static String? _currentToken;

  FcmService._();

  /// Initialize FCM. Call this in main() after Firebase.initializeApp().
  static Future<FcmService> initialize() async {
    if (_instance != null) return _instance!;

    _messaging = FirebaseMessaging.instance;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _instance = FcmService._();
    return _instance!;
  }

  /// Set the client for API calls. Call after user authentication.
  static void setClient(Client client) {
    _client = client;
  }

  /// Request notification permissions and register token with server.
  /// Call this after user logs in.
  static Future<void> registerToken() async {
    if (_messaging == null || _client == null) return;

    // Request permission (required for iOS, optional for Android)
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('FCM permission denied');
      return;
    }

    // Get token
    final token = await _messaging!.getToken();
    if (token == null) {
      debugPrint('Failed to get FCM token');
      return;
    }

    await _sendTokenToServer(token);

    // Listen for token refresh
    _messaging!.onTokenRefresh.listen(_sendTokenToServer);
  }

  /// Send token to server for registration.
  static Future<void> _sendTokenToServer(String token) async {
    if (_client == null) return;

    // Don't re-register same token
    if (token == _currentToken) return;

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _client!.deviceToken.register(
        token: token,
        platform: platform,
      );
      _currentToken = token;
      debugPrint('FCM token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Unregister token from server. Call on logout.
  static Future<void> unregisterToken() async {
    if (_client == null || _currentToken == null) return;

    try {
      await _client!.deviceToken.unregister(_currentToken!);
      _currentToken = null;
      debugPrint('FCM token unregistered');
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  /// Handle foreground messages - trigger sync.
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.data}');

    final type = message.data['type'];
    if (type == 'reminder_sync') {
      // Notify the app to refresh reminders
      // This could use a stream or callback to trigger provider refresh
      _onSyncEvent?.call(message.data);
    }
  }

  /// Handle notification tap when app is in background.
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM message opened app: ${message.data}');

    final type = message.data['type'];
    if (type == 'reminder_sync') {
      // App is now in foreground, sync will happen automatically
      _onSyncEvent?.call(message.data);
    }
  }

  /// Callback for sync events - set by the app to trigger provider refresh.
  static void Function(Map<String, dynamic>)? _onSyncEvent;

  /// Set callback for sync events.
  static void setOnSyncEvent(void Function(Map<String, dynamic>) callback) {
    _onSyncEvent = callback;
  }
}
