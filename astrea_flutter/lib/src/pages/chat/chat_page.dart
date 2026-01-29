import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/astrea_colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';
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

class _ChatView extends ConsumerWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);

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
              const Icon(
                Icons.star_rounded,
                color: AstreaColors.starlightCyan,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Astrea',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
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

        // Messages list
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // reverse: true puts index 0 at the bottom of screen
                    // We want newest message (last in list) at bottom
                    final messageIndex = messages.length - 1 - index;
                    final message = messages[messageIndex];
                    return ChatBubble(
                      key: ValueKey('msg_$messageIndex'),
                      message: message,
                    );
                  },
                ),
        ),

        // Loading indicator
        if (isLoading)
          const Padding(
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
