// ignore_for_file: avoid_print

import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'package:astrea_server/src/generated/endpoints.dart';
import 'package:astrea_server/src/generated/protocol.dart';

/// Seeds a test user for development/testing.
///
/// Run with: dart run bin/seed.dart
///
/// The test user credentials will be:
///   - Email: test@astrea.local
///   - Password: Test123!
void main(List<String> args) async {
  // Initialize Serverpod in maintenance mode
  final pod = Serverpod(
    ['--mode', 'development', '--role', 'maintenance'],
    Protocol(),
    Endpoints(),
  );

  // Initialize authentication services
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode:
            (
              _, {
              required email,
              required accountRequestId,
              required verificationCode,
              required transaction,
            }) {},
        sendPasswordResetVerificationCode:
            (
              _, {
              required email,
              required passwordResetRequestId,
              required verificationCode,
              required transaction,
            }) {},
      ),
    ],
  );

  await pod.start();

  final session = await pod.createSession();

  try {
    await _seedTestUser(session);
    print('✅ Seed completed successfully!');
    print('');
    print('Test user credentials:');
    print('  Email:    test@astrea.local');
    print('  Password: Test123!');
  } catch (e, stack) {
    print('❌ Seed failed: $e');
    print(stack);
    exit(1);
  } finally {
    await session.close();
    await pod.shutdown();
  }

  exit(0);
}

Future<void> _seedTestUser(Session session) async {
  const email = 'test@astrea.local';
  const password = 'Test123!';

  // Check if user already exists
  final existingAccount = await EmailAccount.db.findFirstRow(
    session,
    where: (t) => t.email.equals(email),
  );

  if (existingAccount != null) {
    print('ℹ️  Test user already exists, skipping...');
    return;
  }

  // Get the email IDP utils for proper password hashing
  final emailIdpConfig = EmailIdpConfigFromPasswords(
    sendRegistrationVerificationCode:
        (
          _, {
          required email,
          required accountRequestId,
          required verificationCode,
          required transaction,
        }) {},
    sendPasswordResetVerificationCode:
        (
          _, {
          required email,
          required passwordResetRequestId,
          required verificationCode,
          required transaction,
        }) {},
  );

  final emailIdpUtils = EmailIdpUtils(config: emailIdpConfig);
  final passwordHash = await emailIdpUtils.hashUtil.createHashFromString(
    secret: password,
  );

  // Create the auth user first
  final authUser = await AuthUser.db.insertRow(
    session,
    AuthUser(
      createdAt: DateTime.now(),
      scopeNames: <String>{},
      blocked: false,
    ),
  );

  // Create the email account linked to the auth user
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: authUser.id!,
      createdAt: DateTime.now(),
      email: email,
      passwordHash: passwordHash,
    ),
  );

  // Create a user profile
  await UserProfile.db.insertRow(
    session,
    UserProfile(
      authUserId: authUser.id!,
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    ),
  );

  print('ℹ️  Created test user with ID: ${authUser.id}');
}
