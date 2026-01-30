/// User intent classification and parsed actions.
library;

enum Intent {
  createReminder('create_reminder'),
  updateReminder('update_reminder'),
  listReminders('list_reminders'),
  completeReminder('complete_reminder'),
  deleteReminder('delete_reminder'),
  snoozeReminder('snooze_reminder'),
  question('question'),
  chat('chat'),
  unknown('unknown');

  const Intent(this.value);
  final String value;

  static Intent fromString(String? value) {
    if (value == null) return Intent.unknown;
    return Intent.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => Intent.unknown,
    );
  }
}

sealed class ParsedAction {
  const ParsedAction();
}

class CreateReminderAction extends ParsedAction {
  final String title;
  final String? description;
  final DateTime dueAtUtc;
  final int priority;
  final String? repeatRule;

  const CreateReminderAction({
    required this.title,
    this.description,
    required this.dueAtUtc,
    this.priority = 2,
    this.repeatRule,
  });
}

class UpdateReminderAction extends ParsedAction {
  final int reminderId;
  final String? title;
  final String? description;
  final DateTime? dueAtUtc;
  final int? priority;
  final String? repeatRule;
  final bool clearRepeatRule; // For explicitly removing recurrence

  const UpdateReminderAction({
    required this.reminderId,
    this.title,
    this.description,
    this.dueAtUtc,
    this.priority,
    this.repeatRule,
    this.clearRepeatRule = false,
  });
}

class CompleteReminderAction extends ParsedAction {
  final int reminderId;
  const CompleteReminderAction({required this.reminderId});
}

class DeleteReminderAction extends ParsedAction {
  final int reminderId;
  const DeleteReminderAction({required this.reminderId});
}

class SnoozeReminderAction extends ParsedAction {
  final int reminderId;
  final int minutes;

  const SnoozeReminderAction({
    required this.reminderId,
    required this.minutes,
  });
}

class NoAction extends ParsedAction {
  const NoAction();
}
