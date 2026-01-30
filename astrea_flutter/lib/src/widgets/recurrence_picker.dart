import 'package:flutter/material.dart';

import '../theme/astrea_colors.dart';

/// Common recurrence options.
enum RecurrenceOption {
  none('Does not repeat', null),
  daily('Daily', 'FREQ=DAILY'),
  weekdays('Weekdays', 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
  weekly('Weekly', 'FREQ=WEEKLY'),
  monthly('Monthly', 'FREQ=MONTHLY'),
  yearly('Yearly', 'FREQ=YEARLY');

  final String label;
  final String? rrule;

  const RecurrenceOption(this.label, this.rrule);

  /// Returns the RecurrenceOption matching an RRULE string.
  static RecurrenceOption fromRRule(String? rrule) {
    if (rrule == null || rrule.isEmpty) return none;
    final upper = rrule.toUpperCase();
    for (final option in RecurrenceOption.values) {
      if (option.rrule != null && upper.contains(option.rrule!)) {
        // Check for weekdays specifically
        if (upper.contains('BYDAY=MO,TU,WE,TH,FR')) return weekdays;
        if (option != weekdays) return option;
      }
    }
    // Fallback based on FREQ
    if (upper.contains('FREQ=DAILY')) return daily;
    if (upper.contains('FREQ=WEEKLY')) return weekly;
    if (upper.contains('FREQ=MONTHLY')) return monthly;
    if (upper.contains('FREQ=YEARLY')) return yearly;
    return none;
  }
}

/// Bottom sheet for selecting recurrence option.
class RecurrencePicker extends StatelessWidget {
  final String? currentRRule;
  final ValueChanged<String?> onChanged;

  const RecurrencePicker({
    super.key,
    this.currentRRule,
    required this.onChanged,
  });

  /// Shows the recurrence picker bottom sheet.
  static Future<String?> show(BuildContext context, {String? currentRRule}) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AstreaColors.nightSky,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RecurrencePickerSheet(currentRRule: currentRRule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = RecurrenceOption.fromRRule(currentRRule);

    return InkWell(
      onTap: () async {
        final result = await show(context, currentRRule: currentRRule);
        if (result != currentRRule) {
          onChanged(result);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AstreaColors.astralPurple,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AstreaColors.mysticViolet),
        ),
        child: Row(
          children: [
            Icon(
              Icons.repeat,
              color: current == RecurrenceOption.none
                  ? AstreaColors.faded
                  : AstreaColors.starlightCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                current.label,
                style: TextStyle(
                  color: current == RecurrenceOption.none
                      ? AstreaColors.mist
                      : AstreaColors.starWhite,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AstreaColors.faded,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrencePickerSheet extends StatelessWidget {
  final String? currentRRule;

  const _RecurrencePickerSheet({this.currentRRule});

  @override
  Widget build(BuildContext context) {
    final current = RecurrenceOption.fromRRule(currentRRule);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AstreaColors.mysticViolet,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.repeat, color: AstreaColors.starlightCyan),
                SizedBox(width: 12),
                Text(
                  'Repeat',
                  style: TextStyle(
                    color: AstreaColors.starWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...RecurrenceOption.values.map((option) {
            final isSelected = option == current;
            return ListTile(
              leading: Icon(
                _getIcon(option),
                color: isSelected
                    ? AstreaColors.starlightCyan
                    : AstreaColors.mist,
              ),
              title: Text(
                option.label,
                style: TextStyle(
                  color: isSelected
                      ? AstreaColors.starWhite
                      : AstreaColors.mist,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AstreaColors.starlightCyan)
                  : null,
              onTap: () => Navigator.pop(context, option.rrule),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIcon(RecurrenceOption option) {
    return switch (option) {
      RecurrenceOption.none => Icons.block,
      RecurrenceOption.daily => Icons.today,
      RecurrenceOption.weekdays => Icons.work_outline,
      RecurrenceOption.weekly => Icons.calendar_view_week,
      RecurrenceOption.monthly => Icons.calendar_month,
      RecurrenceOption.yearly => Icons.cake_outlined,
    };
  }
}
