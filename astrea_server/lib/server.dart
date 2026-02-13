import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';

// MailerSend HTTP API configuration
late String _mailersendApiKey;
late String _fromEmail;
late String _fromName;

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize MailerSend HTTP API configuration
  _mailersendApiKey =
      pod.getPassword('mailersendApiKey') ??
      Platform.environment['MAILERSEND_API_KEY'] ??
      '';
  _fromEmail =
      pod.getPassword('smtpFromEmail') ??
      Platform.environment['SMTP_FROM_EMAIL'] ??
      'MS_oN2rzW@test-p7kx4xw893eg9yjr.mlsender.net';
  _fromName =
      pod.getPassword('smtpFromName') ??
      Platform.environment['SMTP_FROM_NAME'] ??
      'Astrea';

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
      ),
    ],
  );

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Start the server.
  await pod.start();
}

Future<void> _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) async {
  session.log('[EmailIdp] Sending registration code to $email');

  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0E0E18; color: #F5F5FA; padding: 40px; }
    .container { max-width: 480px; margin: 0 auto; text-align: center; }
    .logo { font-size: 32px; color: #4FE8E8; margin-bottom: 24px; }
    .code { font-size: 36px; letter-spacing: 8px; color: #4FE8E8; background: #1F1F35; padding: 20px 32px; border-radius: 12px; margin: 24px 0; display: inline-block; }
    .text { color: #B8B8CC; line-height: 1.6; }
    .footer { margin-top: 32px; font-size: 12px; color: #6A6A80; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">Astrea</div>
    <h2>Welcome to Astrea!</h2>
    <p class="text">Use this code to verify your account:</p>
    <div class="code">$verificationCode</div>
    <p class="text">This code expires in 10 minutes.</p>
    <div class="footer">If you didn't request this, you can safely ignore this email.</div>
  </div>
</body>
</html>
''';

  try {
    await _sendEmailViaMailerSend(
      to: email,
      subject: 'Your Astrea Verification Code',
      html: htmlContent,
    );
    print('[EmailIdp] Registration code sent successfully to $email');
  } catch (e) {
    print('[EmailIdp] Failed to send registration code: $e');
    print('[EmailIdp] Registration code ($email): $verificationCode');
  }
}

Future<void> _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) async {
  session.log('[EmailIdp] Sending password reset code to $email');

  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0E0E18; color: #F5F5FA; padding: 40px; }
    .container { max-width: 480px; margin: 0 auto; text-align: center; }
    .logo { font-size: 32px; color: #4FE8E8; margin-bottom: 24px; }
    .code { font-size: 36px; letter-spacing: 8px; color: #4FE8E8; background: #1F1F35; padding: 20px 32px; border-radius: 12px; margin: 24px 0; display: inline-block; }
    .text { color: #B8B8CC; line-height: 1.6; }
    .footer { margin-top: 32px; font-size: 12px; color: #6A6A80; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">Astrea</div>
    <h2>Password Reset</h2>
    <p class="text">Use this code to reset your password:</p>
    <div class="code">$verificationCode</div>
    <p class="text">This code expires in 10 minutes.</p>
    <div class="footer">If you didn't request this, you can safely ignore this email.</div>
  </div>
</body>
</html>
''';

  try {
    await _sendEmailViaMailerSend(
      to: email,
      subject: 'Reset Your Astrea Password',
      html: htmlContent,
    );
    print('[EmailIdp] Password reset code sent successfully to $email');
  } catch (e) {
    print('[EmailIdp] Failed to send password reset code: $e');
    print('[EmailIdp] Password reset code ($email): $verificationCode');
  }
}

/// Send email using MailerSend HTTP API (Railway blocks SMTP ports)
Future<void> _sendEmailViaMailerSend({
  required String to,
  required String subject,
  required String html,
}) async {
  final response = await http.post(
    Uri.parse('https://api.mailersend.com/v1/email'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_mailersendApiKey',
    },
    body: jsonEncode({
      'from': {'email': _fromEmail, 'name': _fromName},
      'to': [{'email': to}],
      'subject': subject,
      'html': html,
    }),
  );

  if (response.statusCode != 202 && response.statusCode != 200) {
    throw Exception('MailerSend API error: ${response.statusCode} ${response.body}');
  }
}
