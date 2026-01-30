import 'package:astrea_client/astrea_client.dart';
import 'package:flutter/material.dart';

import '../theme/astrea_colors.dart';

/// Displays a single reminder with actions.
/// Optimized for 60fps with const decorations and efficient keys.
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  // Const decorations for performance - avoid recreating on each build
  static const _borderRadius = BorderRadius.all(Radius.circular(12));
  static const _highPriorityBorder = Border(
    left: BorderSide(color: AstreaColors.error, width: 4),
  );
  static const _mediumPriorityBorder = Border(
    left: BorderSide(color: AstreaColors.oracleGold, width: 4),
  );
  static const _lowPriorityBorder = Border(
    left: BorderSide(color: AstreaColors.mist, width: 4),
  );

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityBorder = switch (reminder.priority) {
      3 => _highPriorityBorder,
      1 => _lowPriorityBorder,
      _ => _mediumPriorityBorder,
    };

    return Container(
      decoration: BoxDecoration(
        color: AstreaColors.astralPurple,
        borderRadius: _borderRadius,
        border: priorityBorder,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          reminder.title,
          style: TextStyle(
            color: AstreaColors.starWhite,
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description != null) ...[
              const SizedBox(height: 4),
              Text(
                reminder.description!,
                style: const TextStyle(color: AstreaColors.mist),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AstreaColors.faded,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDueDate(reminder.dueAtUtc),
                  style: const TextStyle(
                    color: AstreaColors.faded,
                    fontSize: 12,
                  ),
                ),
                if (reminder.repeatRule != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.repeat,
                    size: 14,
                    color: AstreaColors.starlightCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRecurrence(reminder.repeatRule),
                    style: const TextStyle(
                      color: AstreaColors.starlightCyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reminder.isCompleted && onComplete != null)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: AstreaColors.success,
                onPressed: onComplete,
                tooltip: 'Complete',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AstreaColors.error,
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueAtUtc) {
    final local = dueAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(local.year, local.month, local.day);

    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    if (dueDate == today) {
      return 'Today at $time';
    } else if (dueDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at $time';
    } else if (dueDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $time';
    } else {
      return '${local.month}/${local.day} at $time';
    }
  }

  String _formatRecurrence(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) return '';

    final rule = repeatRule.toUpperCase();
    if (rule.contains('FREQ=DAILY')) return 'Daily';
    if (rule.contains('BYDAY=MO,TU,WE,TH,FR')) return 'Weekdays';
    if (rule.contains('FREQ=WEEKLY')) return 'Weekly';
    if (rule.contains('FREQ=MONTHLY')) return 'Monthly';
    if (rule.contains('FREQ=YEARLY')) return 'Yearly';
    return 'Repeats';
  }
}
