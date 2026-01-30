import 'package:astrea_client/astrea_client.dart';
import 'package:flutter/material.dart';

import '../theme/astrea_colors.dart';
import 'recurrence_picker.dart';

/// Bottom sheet for viewing and editing reminder details.
class ReminderDetailSheet extends StatefulWidget {
  final Reminder reminder;
  final Future<void> Function(Reminder updated)? onUpdate;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const ReminderDetailSheet({
    super.key,
    required this.reminder,
    this.onUpdate,
    this.onComplete,
    this.onDelete,
  });

  /// Shows the reminder detail bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Reminder reminder,
    Future<void> Function(Reminder updated)? onUpdate,
    VoidCallback? onComplete,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AstreaColors.nightSky,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReminderDetailSheet(
        reminder: reminder,
        onUpdate: onUpdate,
        onComplete: onComplete,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ReminderDetailSheet> createState() => _ReminderDetailSheetState();
}

class _ReminderDetailSheetState extends State<ReminderDetailSheet> {
  late String? _repeatRule;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repeatRule = widget.reminder.repeatRule;
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final dueLocal = reminder.dueAtUtc.toLocal();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AstreaColors.mysticViolet,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildPriorityIndicator(reminder.priority),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: const TextStyle(
                          color: AstreaColors.starWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Description
              if (reminder.description != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    reminder.description!,
                    style: const TextStyle(
                      color: AstreaColors.mist,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Due date/time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInfoRow(
                  Icons.access_time,
                  _formatDateTime(dueLocal),
                ),
              ),

              const SizedBox(height: 16),

              // Recurrence picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repeat',
                      style: TextStyle(
                        color: AstreaColors.mist,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RecurrencePicker(
                      currentRRule: _repeatRule,
                      onChanged: (newRRule) {
                        setState(() {
                          _repeatRule = newRRule;
                          _hasChanges =
                              _repeatRule != widget.reminder.repeatRule;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Complete button
                    if (!reminder.isCompleted && widget.onComplete != null)
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.check_circle,
                          label: reminder.repeatRule != null
                              ? 'Reschedule'
                              : 'Complete',
                          color: AstreaColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onComplete?.call();
                          },
                        ),
                      ),
                    if (!reminder.isCompleted && widget.onComplete != null)
                      const SizedBox(width: 12),

                    // Delete button
                    if (widget.onDelete != null)
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: AstreaColors.error,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Save button (if changes made)
              if (_hasChanges && widget.onUpdate != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AstreaColors.starlightCyan,
                        foregroundColor: AstreaColors.deepVoid,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AstreaColors.deepVoid,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    final color = switch (priority) {
      3 => AstreaColors.error,
      1 => AstreaColors.mist,
      _ => AstreaColors.oracleGold,
    };
    final label = switch (priority) {
      3 => 'High',
      1 => 'Low',
      _ => 'Medium',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AstreaColors.faded, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: AstreaColors.starWhite),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(128)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    String dayStr;
    if (date == today) {
      dayStr = 'Today';
    } else if (date == today.add(const Duration(days: 1))) {
      dayStr = 'Tomorrow';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dayStr = 'Yesterday';
    } else {
      final weekday = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][dt.weekday - 1];
      dayStr = '$weekday, ${dt.month}/${dt.day}/${dt.year}';
    }

    return '$dayStr at $time';
  }

  Future<void> _saveChanges() async {
    if (widget.onUpdate == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = widget.reminder.copyWith(
        repeatRule: _repeatRule,
      );
      await widget.onUpdate!(updated);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
