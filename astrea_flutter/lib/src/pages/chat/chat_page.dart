import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/astrea_colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/constellation_background.dart';
import '../onboarding/onboarding_page.dart';
import '../reminders/reminders_page.dart';
import '../settings/settings_page.dart';

/// Main chat interface for natural language reminders.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ChatView(),
          RemindersPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView();

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _dissolveOldMessages();
  }

  void _dissolveOldMessages() {
    if (!mounted) return;

    final messages = ref.read(chatMessagesProvider);
    // Keep only the most recent 4 messages visible
    const maxVisibleMessages = 4;

    if (messages.length <= maxVisibleMessages) return;

    final messagesToDissolve = <String>{};

    // Dissolve oldest messages (at the start of the list)
    for (int i = 0; i < messages.length - maxVisibleMessages; i++) {
      final msg = messages[i];
      if (!msg.isDissolving) {
        messagesToDissolve.add(msg.id);
      }
    }

    if (messagesToDissolve.isNotEmpty) {
      ref
          .read(chatMessagesProvider.notifier)
          .markMultipleDissolving(
            messagesToDissolve,
          );
      // Remove after animation
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) {
          for (final id in messagesToDissolve) {
            ref.read(chatMessagesProvider.notifier).removeMessage(id);
          }
        }
      });
    }
  }

  void _onDissolveComplete(String messageId) {
    ref.read(chatMessagesProvider.notifier).removeMessage(messageId);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);

    // Auto-dissolve old messages when list grows
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dissolveOldMessages();
    });

    return Column(
      children: [
        // App bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          color: AstreaColors.deepVoid,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Astrea',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OnboardingPage(
                      onComplete: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                tooltip: 'How it works',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                onPressed: () => NotificationService.showTestNotification(),
                tooltip: 'Test notification',
              ),
              if (messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      ref.read(chatMessagesProvider.notifier).clear(),
                  tooltip: 'Clear chat',
                ),
            ],
          ),
        ),

        // Messages list with constellation background
        Expanded(
          child: Stack(
            children: [
              // Full-screen constellation background
              const Positioned.fill(
                child: ConstellationBackground(
                  starCount: 80,
                  particleCount: 25,
                ),
              ),
              // Messages
              messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageIndex = messages.length - 1 - index;
                        final message = messages[messageIndex];
                        return ChatBubble(
                          key: ValueKey(message.id),
                          message: message,
                          onDissolveComplete: () =>
                              _onDissolveComplete(message.id),
                        );
                      },
                    ),
            ],
          ),
        ),

        // Loading indicator - fixed height to prevent layout shifts
        AnimatedOpacity(
          opacity: isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const SizedBox(
            height: 24,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AstreaColors.starlightCyan,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Astrea is thinking...',
                    style: TextStyle(color: AstreaColors.mist),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Input
        const ChatInput(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AstreaColors.mysticViolet,
            ),
            const SizedBox(height: 16),
            Text(
              'Hi! I\'m Astrea',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell me what you need to remember.\nTry: "Remind me to call mom tomorrow at 3pm"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AstreaColors.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
