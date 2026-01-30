import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/device_token.dart';

/// Service for sending Firebase Cloud Messaging push notifications.
/// Uses FCM HTTP v1 API with service account authentication.
class FcmService {
  static FcmService? _instance;
  static String? _projectId;
  static auth.AccessCredentials? _credentials;
  static String? _serviceAccountJson;

  FcmService._();

  /// Get singleton instance, initializing with Firebase credentials if needed.
  static Future<FcmService?> getInstance(Session session) async {
    if (_instance != null && _credentials != null && _isTokenValid()) {
      return _instance;
    }

    // Read Firebase service account from passwords config
    final serviceAccountJson = session.passwords['firebaseServiceAccount'];
    if (serviceAccountJson == null || serviceAccountJson.isEmpty) {
      session.log(
        'Firebase service account not configured - FCM disabled',
        level: LogLevel.warning,
      );
      return null;
    }

    _serviceAccountJson = serviceAccountJson;

    try {
      final serviceAccount =
          jsonDecode(serviceAccountJson) as Map<String, dynamic>;
      _projectId = serviceAccount['project_id'] as String?;

      if (_projectId == null) {
        session.log(
          'Firebase project_id not found in service account',
          level: LogLevel.error,
        );
        return null;
      }

      // Create service account credentials and get access token
      await _refreshAccessToken(session);

      _instance = FcmService._();
      session.log('FCM service initialized for project: $_projectId');
      return _instance;
    } catch (e, stack) {
      session.log(
        'Failed to initialize FCM service: $e\n$stack',
        level: LogLevel.error,
      );
      return null;
    }
  }

  static bool _isTokenValid() {
    if (_credentials == null) return false;
    return DateTime.now().isBefore(
      _credentials!.accessToken.expiry.subtract(Duration(minutes: 5)),
    );
  }

  static Future<void> _refreshAccessToken(Session session) async {
    if (_serviceAccountJson == null) return;

    try {
      // Parse service account credentials
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        _serviceAccountJson!,
      );

      // FCM requires this scope
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Get access credentials using http client
      final httpClient = http.Client();
      _credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        scopes,
        httpClient,
      );
      httpClient.close();

      session.log(
        'Firebase access token obtained, expires: ${_credentials!.accessToken.expiry}',
      );
    } catch (e) {
      session.log(
        'Failed to obtain Firebase access token: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// Send a sync event to all devices for a user.
  Future<void> sendSyncEvent(
    Session session, {
    required UuidValue userId,
    required String eventType,
    required int reminderId,
  }) async {
    if (_credentials == null || _projectId == null) {
      session.log('FCM not configured, skipping push', level: LogLevel.debug);
      return;
    }

    // Refresh token if needed
    if (!_isTokenValid()) {
      await _refreshAccessToken(session);
    }

    // Get all device tokens for this user
    final tokens = await DeviceToken.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (tokens.isEmpty) {
      session.log(
        'No FCM tokens for user, skipping push',
        level: LogLevel.debug,
      );
      return;
    }

    session.log('Sending FCM to ${tokens.length} device(s) for user');

    final invalidTokens = <DeviceToken>[];

    for (final deviceToken in tokens) {
      final success = await _sendToToken(
        session,
        token: deviceToken.token,
        data: {
          'type': 'reminder_sync',
          'eventType': eventType,
          'reminderId': reminderId.toString(),
        },
      );

      if (!success) {
        invalidTokens.add(deviceToken);
      }
    }

    // Clean up invalid tokens
    for (final invalidToken in invalidTokens) {
      await DeviceToken.db.deleteRow(session, invalidToken);
      session.log(
        'Removed invalid FCM token: ${invalidToken.id}',
        level: LogLevel.info,
      );
    }
  }

  /// Send a data message to a specific FCM token.
  Future<bool> _sendToToken(
    Session session, {
    required String token,
    required Map<String, String> data,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final request = await client.postUrl(uri);
      request.headers.set(
        'Authorization',
        'Bearer ${_credentials!.accessToken.data}',
      );
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'message': {
          'token': token,
          'data': data,
          // Use data-only message for silent/background processing
          'android': {
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'content-available': 1,
              },
            },
          },
        },
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        session.log('FCM sent successfully');
        return true;
      }

      // Check for invalid token errors
      if (response.statusCode == 404 ||
          responseBody.contains('UNREGISTERED') ||
          responseBody.contains('INVALID_ARGUMENT')) {
        session.log(
          'FCM token invalid or unregistered: ${response.statusCode}',
          level: LogLevel.info,
        );
        return false;
      }

      session.log(
        'FCM send failed: ${response.statusCode} - $responseBody',
        level: LogLevel.error,
      );
      return true; // Don't remove token for other errors
    } catch (e) {
      session.log('FCM send error: $e', level: LogLevel.error);
      return true; // Don't remove token on network errors
    }
  }
}
