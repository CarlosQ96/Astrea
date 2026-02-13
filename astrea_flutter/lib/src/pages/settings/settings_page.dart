import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/client_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/astrea_colors.dart';

/// Settings screen with logout option.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => _SettingsContent(settings: settings),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AstreaColors.starlightCyan),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: AstreaColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load settings',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(
                    color: AstreaColors.mist,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userSettingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AstreaColors.starlightCyan,
                    foregroundColor: AstreaColors.deepVoid,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  final dynamic settings;

  const _SettingsContent({required this.settings});

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  late bool _voiceEnabled;
  late int _snoozeMinutes;

  @override
  void initState() {
    super.initState();
    _voiceEnabled = widget.settings.voiceEnabled;
    _snoozeMinutes = widget.settings.defaultSnoozeMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    return ListView(
      children: [
        const SizedBox(height: 16),

        // Subscription section
        _buildSectionHeader(context, 'Subscription'),
        ListTile(
          leading: Icon(
            Icons.auto_awesome,
            color: isPro ? AstreaColors.oracleGold : AstreaColors.mist,
          ),
          title: Text(isPro ? 'Astrea Pro' : 'Free Plan'),
          subtitle: Text(
            isPro ? 'Manage your subscription' : 'Upgrade to Pro',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            try {
              if (isPro) {
                await RevenueCatUI.presentCustomerCenter();
              } else {
                await RevenueCatUI.presentPaywallIfNeeded('Astrea Pro');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription management unavailable')),
                );
              }
            }
          },
        ),
        const Divider(),

        // Account section
        _buildSectionHeader(context, 'Account'),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: AstreaColors.starlightCyan,
            child: Icon(
              Icons.person_outline,
              color: AstreaColors.deepVoid,
            ),
          ),
          title: const Text('Signed In'),
          subtitle: const Text('Manage your account'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAccountInfo(context),
        ),
        const Divider(),

        // Preferences section
        _buildSectionHeader(context, 'Preferences'),
        SwitchListTile(
          secondary: const Icon(Icons.record_voice_over_outlined),
          title: const Text('Voice Input'),
          subtitle: const Text('Enable voice commands'),
          value: _voiceEnabled,
          onChanged: (value) async {
            setState(() => _voiceEnabled = value);
            await updateUserSettings(ref, voiceEnabled: value);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Voice input enabled' : 'Voice input disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Default Snooze'),
          subtitle: Text('$_snoozeMinutes minutes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSnoozePicker(context),
        ),
        const Divider(),

        // About section
        _buildSectionHeader(context, 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 24,
              height: 24,
            ),
          ),
          title: const Text('About Astrea'),
          subtitle: const Text('AI-powered reminder assistant'),
          onTap: () => _showAboutDialog(context),
        ),
        const Divider(),

        // Sign out
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AstreaColors.error,
              side: const BorderSide(color: AstreaColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AstreaColors.starlightCyan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showAccountInfo(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'Unknown';
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AstreaColors.astralPurple,
        title: const Text('Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(email),
            ),
            const ListTile(
              leading: Icon(Icons.calendar_today_outlined),
              title: Text('Member since'),
              subtitle: Text('January 2026'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnoozePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AstreaColors.astralPurple,
        title: const Text('Default Snooze Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 60].map((minutes) {
            return ListTile(
              title: Text('$minutes minutes'),
              trailing: _snoozeMinutes == minutes
                  ? const Icon(Icons.check, color: AstreaColors.starlightCyan)
                  : null,
              onTap: () async {
                setState(() => _snoozeMinutes = minutes);
                Navigator.pop(dialogContext);
                await updateUserSettings(ref, defaultSnoozeMinutes: minutes);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Snooze set to $minutes minutes'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AstreaColors.astralPurple,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Astrea'),
          ],
        ),
        content: const Text(
          'Astrea is your AI-powered reminder assistant. '
          'Simply chat naturally to create, manage, and track your reminders.\n\n'
          'Built with Flutter and Serverpod for the "Build Your Flutter Butler" hackathon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AstreaColors.astralPurple,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AstreaColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = ref.read(clientProvider);
      await client.authSessionManager.signOutDevice();
    }
  }
}
