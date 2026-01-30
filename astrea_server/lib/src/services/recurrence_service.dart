/// Service for handling recurring reminder logic.
///
/// Supports basic iCalendar RRULE patterns:
/// - FREQ=DAILY (every day)
/// - FREQ=WEEKLY (every week, same day)
/// - FREQ=MONTHLY (every month, same day)
/// - FREQ=YEARLY (every year, same date)
/// - INTERVAL=N (every N periods)
/// - COUNT=N (repeat N times total)
class RecurrenceService {
  /// Common RRULE patterns for easy creation.
  static const String daily = 'FREQ=DAILY';
  static const String weekly = 'FREQ=WEEKLY';
  static const String weekdays = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
  static const String monthly = 'FREQ=MONTHLY';
  static const String yearly = 'FREQ=YEARLY';

  /// Calculates the next occurrence based on the current due date and RRULE.
  ///
  /// Returns null if:
  /// - repeatRule is null or empty
  /// - COUNT limit has been reached
  /// - UNTIL date has passed
  /// - Rule cannot be parsed
  static DateTime? getNextOccurrence(
    DateTime currentDueUtc,
    String? repeatRule, {
    int completionCount = 0,
  }) {
    if (repeatRule == null || repeatRule.isEmpty) return null;

    final rule = repeatRule.toUpperCase();
    final parts = _parseRRule(rule);

    // Check COUNT limit
    final count = parts['COUNT'];
    if (count != null && completionCount >= int.parse(count)) {
      return null; // Reached repeat limit
    }

    // Check UNTIL date
    final until = parts['UNTIL'];
    if (until != null) {
      final untilDate = _parseUntilDate(until);
      if (untilDate != null && currentDueUtc.isAfter(untilDate)) {
        return null; // Past end date
      }
    }

    // Get interval (default 1)
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;

    // Calculate next based on frequency
    final freq = parts['FREQ'];
    if (freq == null) return null;

    switch (freq) {
      case 'DAILY':
        return currentDueUtc.add(Duration(days: interval));

      case 'WEEKLY':
        // Check for BYDAY (specific days of week)
        final byDay = parts['BYDAY'];
        if (byDay != null) {
          return _getNextWeekday(currentDueUtc, byDay, interval);
        }
        return currentDueUtc.add(Duration(days: 7 * interval));

      case 'MONTHLY':
        return _addMonths(currentDueUtc, interval);

      case 'YEARLY':
        return DateTime.utc(
          currentDueUtc.year + interval,
          currentDueUtc.month,
          currentDueUtc.day,
          currentDueUtc.hour,
          currentDueUtc.minute,
          currentDueUtc.second,
        );

      default:
        return null;
    }
  }

  /// Parses RRULE string into key-value map.
  static Map<String, String> _parseRRule(String rule) {
    final result = <String, String>{};
    // Remove RRULE: prefix if present
    final cleanRule = rule.replaceFirst(
      RegExp(r'^RRULE:', caseSensitive: false),
      '',
    );

    for (final part in cleanRule.split(';')) {
      final kv = part.split('=');
      if (kv.length == 2) {
        result[kv[0].trim()] = kv[1].trim();
      }
    }
    return result;
  }

  /// Parses UNTIL date format (YYYYMMDD or YYYYMMDDTHHmmssZ).
  static DateTime? _parseUntilDate(String until) {
    try {
      if (until.length >= 8) {
        final year = int.parse(until.substring(0, 4));
        final month = int.parse(until.substring(4, 6));
        final day = int.parse(until.substring(6, 8));
        return DateTime.utc(year, month, day, 23, 59, 59);
      }
    } catch (_) {}
    return null;
  }

  /// Gets next occurrence for BYDAY rules (e.g., MO,WE,FR).
  static DateTime _getNextWeekday(
    DateTime current,
    String byDay,
    int interval,
  ) {
    final days = byDay.split(',').map((d) => d.trim()).toList();
    final targetDays = days.map(_weekdayFromString).whereType<int>().toSet();

    if (targetDays.isEmpty) {
      return current.add(Duration(days: 7 * interval));
    }

    // Find next matching day
    var next = current.add(const Duration(days: 1));
    var weeksSearched = 0;

    while (weeksSearched < 8) {
      // Safety limit
      if (targetDays.contains(next.weekday)) {
        return next;
      }
      next = next.add(const Duration(days: 1));
      if (next.weekday == DateTime.monday) {
        weeksSearched++;
        if (interval > 1 && weeksSearched == 1) {
          // Skip weeks based on interval
          next = next.add(Duration(days: 7 * (interval - 1)));
        }
      }
    }

    // Fallback
    return current.add(Duration(days: 7 * interval));
  }

  /// Converts RRULE day string to Dart weekday.
  static int? _weekdayFromString(String day) {
    switch (day.toUpperCase()) {
      case 'MO':
        return DateTime.monday;
      case 'TU':
        return DateTime.tuesday;
      case 'WE':
        return DateTime.wednesday;
      case 'TH':
        return DateTime.thursday;
      case 'FR':
        return DateTime.friday;
      case 'SA':
        return DateTime.saturday;
      case 'SU':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  /// Adds months to a date, handling month-end edge cases.
  static DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;

    while (month > 12) {
      month -= 12;
      year++;
    }

    // Handle month-end (e.g., Jan 31 + 1 month = Feb 28/29)
    var day = date.day;
    final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
    if (day > lastDayOfMonth) {
      day = lastDayOfMonth;
    }

    return DateTime.utc(year, month, day, date.hour, date.minute, date.second);
  }

  /// Creates a human-readable description of the recurrence rule.
  static String describeRule(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) return 'Does not repeat';

    final parts = _parseRRule(repeatRule.toUpperCase());
    final freq = parts['FREQ'];
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final byDay = parts['BYDAY'];

    String base;
    switch (freq) {
      case 'DAILY':
        base = interval == 1 ? 'Every day' : 'Every $interval days';
        break;
      case 'WEEKLY':
        if (byDay != null) {
          if (byDay == 'MO,TU,WE,TH,FR') {
            base = 'Every weekday';
          } else {
            base = 'Every ${_formatDays(byDay)}';
          }
        } else {
          base = interval == 1 ? 'Every week' : 'Every $interval weeks';
        }
        break;
      case 'MONTHLY':
        base = interval == 1 ? 'Every month' : 'Every $interval months';
        break;
      case 'YEARLY':
        base = interval == 1 ? 'Every year' : 'Every $interval years';
        break;
      default:
        return 'Custom recurrence';
    }

    final count = parts['COUNT'];
    if (count != null) {
      base += ', $count times';
    }

    final until = parts['UNTIL'];
    if (until != null) {
      final untilDate = _parseUntilDate(until);
      if (untilDate != null) {
        base += ', until ${untilDate.month}/${untilDate.day}/${untilDate.year}';
      }
    }

    return base;
  }

  /// Formats BYDAY string for display.
  static String _formatDays(String byDay) {
    final dayNames = {
      'MO': 'Mon',
      'TU': 'Tue',
      'WE': 'Wed',
      'TH': 'Thu',
      'FR': 'Fri',
      'SA': 'Sat',
      'SU': 'Sun',
    };

    return byDay
        .split(',')
        .map((d) => dayNames[d.trim().toUpperCase()] ?? d)
        .join(', ');
  }
}
