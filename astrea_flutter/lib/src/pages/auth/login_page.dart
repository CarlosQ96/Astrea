import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../providers/client_provider.dart';
import '../../theme/astrea_colors.dart';

/// Login page with email authentication.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final EmailAuthController _authController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientProvider);
    _authController = EmailAuthController(
      client: client,
      onError: (error) {
        setState(() => _error = error.toString());
      },
    );
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _authController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_authController.currentScreen == EmailFlowScreen.login) {
      await _authController.login();
    } else if (_authController.currentScreen ==
        EmailFlowScreen.startRegistration) {
      await _authController.startRegistration();
    } else if (_authController.currentScreen ==
        EmailFlowScreen.verifyRegistration) {
      await _authController.verifyRegistrationCode();
    } else if (_authController.currentScreen ==
        EmailFlowScreen.completeRegistration) {
      await _authController.finishRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authController.currentScreen == EmailFlowScreen.login;
    final isStartReg =
        _authController.currentScreen == EmailFlowScreen.startRegistration;
    final isVerify =
        _authController.currentScreen == EmailFlowScreen.verifyRegistration;
    final isComplete =
        _authController.currentScreen == EmailFlowScreen.completeRegistration;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Astrea',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AstreaColors.starWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI Reminder Assistant',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AstreaColors.mist,
                  ),
                ),
                const SizedBox(height: 48),

                // Email field (login and start registration)
                if (isLogin || isStartReg)
                  TextField(
                    controller: _authController.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                // Verification code field
                if (isVerify)
                  TextField(
                    controller: _authController.verificationCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Verification Code',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),

                if (isLogin || isStartReg || isVerify)
                  const SizedBox(height: 16),

                // Password field (login and complete registration)
                if (isLogin || isComplete)
                  TextField(
                    controller: _authController.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                  ),

                // Terms checkbox for registration
                if (isStartReg) ...[
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        _authController.legalNoticeAcceptedNotifier,
                    builder: (context, accepted, _) {
                      return CheckboxListTile(
                        value: accepted,
                        onChanged: (value) {
                          _authController.legalNoticeAcceptedNotifier.value =
                              value ?? false;
                        },
                        title: const Text(
                          'I agree to the Terms of Service',
                          style: TextStyle(
                            color: AstreaColors.mist,
                            fontSize: 14,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Error message
                if (_error != null || _authController.error != null) ...[
                  Text(
                    _error ?? _authController.errorMessage ?? '',
                    style: const TextStyle(color: AstreaColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _authController.isLoading ? null : _submit,
                    child: _authController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AstreaColors.deepVoid,
                            ),
                          )
                        : Text(_getButtonText()),
                  ),
                ),
                const SizedBox(height: 16),

                // Navigation buttons
                if (_authController.canNavigateBack)
                  TextButton(
                    onPressed: () => _authController.navigateBack(),
                    child: const Text('Go Back'),
                  ),

                if (isLogin)
                  TextButton(
                    onPressed: () => _authController.navigateTo(
                      EmailFlowScreen.startRegistration,
                    ),
                    child: const Text("Don't have an account? Sign Up"),
                  ),

                if (isStartReg)
                  TextButton(
                    onPressed: () =>
                        _authController.navigateTo(EmailFlowScreen.login),
                    child: const Text('Already have an account? Sign In'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    return switch (_authController.currentScreen) {
      EmailFlowScreen.login => 'Sign In',
      EmailFlowScreen.startRegistration => 'Continue',
      EmailFlowScreen.verifyRegistration => 'Verify',
      EmailFlowScreen.completeRegistration => 'Create Account',
      _ => 'Continue',
    };
  }
}
