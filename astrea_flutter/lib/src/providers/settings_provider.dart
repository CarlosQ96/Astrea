import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client_provider.dart';

/// Fetches user settings from the server.
final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
  final client = ref.watch(clientProvider);
  return await client.userSettings.get();
});

/// Updates user settings on the server.
Future<UserSettings> updateUserSettings(
  WidgetRef ref, {
  int? defaultSnoozeMinutes,
  bool? voiceEnabled,
  String? timezone,
}) async {
  final client = ref.read(clientProvider);
  final updated = await client.userSettings.update(
    defaultSnoozeMinutes: defaultSnoozeMinutes,
    voiceEnabled: voiceEnabled,
    timezone: timezone,
  );
  ref.invalidate(userSettingsProvider);
  return updated;
}
