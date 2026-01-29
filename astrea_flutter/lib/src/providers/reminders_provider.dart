import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client_provider.dart';

/// Fetches all reminders for the current user.
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final client = ref.watch(clientProvider);
  return await client.reminder.list();
});
