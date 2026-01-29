import 'package:astrea_client/astrea_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the Serverpod client instance throughout the app.
final clientProvider = Provider<Client>((ref) {
  throw UnimplementedError('Client must be overridden in ProviderScope');
});
