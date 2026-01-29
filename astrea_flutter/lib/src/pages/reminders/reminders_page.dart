import 'package:astrea_client/astrea_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/client_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/astrea_colors.dart';
import '../../widgets/reminder_card.dart';

/// Displays list of reminders grouped by time.
class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(remindersProvider),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildRemindersList(context, ref, reminders);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AstreaColors.starlightCyan,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AstreaColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(remindersProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.checklist_outlined,
            size: 64,
            color: AstreaColors.mysticViolet,
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with Astrea to create reminders',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AstreaColors.mist,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(
    BuildContext context,
    WidgetRef ref,
    List<Reminder> reminders,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final overdue = <Reminder>[];
    final todayReminders = <Reminder>[];
    final tomorrowReminders = <Reminder>[];
    final later = <Reminder>[];

    for (final r in reminders) {
      if (r.isCompleted) continue;

      // Convert UTC to local time for proper day grouping
      final dueLocal = r.dueAtUtc.toLocal();
      final dueDate = DateTime(
        dueLocal.year,
        dueLocal.month,
        dueLocal.day,
      );

      if (dueLocal.isBefore(now)) {
        overdue.add(r);
      } else if (dueDate == today) {
        todayReminders.add(r);
      } else if (dueDate == tomorrow) {
        tomorrowReminders.add(r);
      } else {
        later.add(r);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _buildSection(context, ref, 'Overdue', overdue, AstreaColors.error),
          const SizedBox(height: 16),
        ],
        if (todayReminders.isNotEmpty) ...[
          _buildSection(
            context,
            ref,
            'Today',
            todayReminders,
            AstreaColors.oracleGold,
          ),
          const SizedBox(height: 16),
        ],
        if (tomorrowReminders.isNotEmpty) ...[
          _buildSection(
            context,
            ref,
            'Tomorrow',
            tomorrowReminders,
            AstreaColors.starlightCyan,
          ),
          const SizedBox(height: 16),
        ],
        if (later.isNotEmpty)
          _buildSection(context, ref, 'Later', later, AstreaColors.mist),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Reminder> reminders,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${reminders.length})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...reminders.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ReminderCard(
              reminder: r,
              onComplete: () => _completeReminder(ref, r),
              onDelete: () => _deleteReminder(ref, r),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeReminder(WidgetRef ref, Reminder reminder) async {
    final id = reminder.id;
    if (id == null) return; // Guard against optimistic/unsaved reminders
    final client = ref.read(clientProvider);
    await client.reminder.complete(id);
    await NotificationService.cancelReminder(id);
    ref.invalidate(remindersProvider);
  }

  Future<void> _deleteReminder(WidgetRef ref, Reminder reminder) async {
    final id = reminder.id;
    if (id == null) return; // Guard against optimistic/unsaved reminders
    final client = ref.read(clientProvider);
    await client.reminder.delete(id);
    await NotificationService.cancelReminder(id);
    ref.invalidate(remindersProvider);
  }
}
