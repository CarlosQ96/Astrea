import 'package:serverpod/serverpod.dart';

import '../generated/device_token.dart';

/// Manages FCM device tokens for push notifications.
class DeviceTokenEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  UuidValue _getUserId(Session session) {
    return UuidValue.fromString(session.authenticated!.userIdentifier);
  }

  /// Register a device token for push notifications.
  /// Updates existing token if already registered, or creates new.
  Future<DeviceToken> register(
    Session session, {
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    final userId = _getUserId(session);

    // Check if token already exists for this user
    final existing = await DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.token.equals(token),
    );

    if (existing != null) {
      // Update existing token
      final updated = existing.copyWith(
        platform: platform,
        deviceId: deviceId,
        updatedAt: DateTime.now().toUtc(),
      );
      return await DeviceToken.db.updateRow(session, updated);
    }

    // Create new token
    final deviceToken = DeviceToken(
      userId: userId,
      token: token,
      platform: platform,
      deviceId: deviceId,
    );
    return await DeviceToken.db.insertRow(session, deviceToken);
  }

  /// Unregister a device token (e.g., on logout).
  Future<bool> unregister(Session session, String token) async {
    final userId = _getUserId(session);

    final existing = await DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.token.equals(token),
    );

    if (existing == null) return false;

    await DeviceToken.db.deleteRow(session, existing);
    return true;
  }

  /// Unregister all tokens for the current user (e.g., on account deletion).
  Future<int> unregisterAll(Session session) async {
    final userId = _getUserId(session);

    final tokens = await DeviceToken.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    for (final token in tokens) {
      await DeviceToken.db.deleteRow(session, token);
    }

    return tokens.length;
  }
}
