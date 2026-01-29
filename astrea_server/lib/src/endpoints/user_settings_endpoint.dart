import 'package:serverpod/serverpod.dart';

import '../generated/user_settings.dart';

class UserSettingsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  UuidValue _getUserId(Session session) {
    return UuidValue.fromString(session.authenticated!.userIdentifier);
  }

  Future<UserSettings> get(Session session) async {
    final userId = _getUserId(session);

    final existing = await UserSettings.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing != null) {
      return existing;
    }

    final settings = UserSettings(userId: userId);
    return await UserSettings.db.insertRow(session, settings);
  }

  Future<UserSettings> update(
    Session session, {
    int? defaultSnoozeMinutes,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? voiceEnabled,
    String? timezone,
  }) async {
    final userId = _getUserId(session);

    var existing = await UserSettings.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing == null) {
      existing = UserSettings(userId: userId);
      existing = await UserSettings.db.insertRow(session, existing);
    }

    final updated = existing.copyWith(
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      voiceEnabled: voiceEnabled,
      timezone: timezone,
    );

    return await UserSettings.db.updateRow(session, updated);
  }
}
