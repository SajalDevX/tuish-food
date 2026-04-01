import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Convenience formatting extensions on [DateTime].
extension DateTimeExtensions on DateTime {
  // ---------------------------------------------------------------------------
  // Relative time
  // ---------------------------------------------------------------------------

  /// Returns a human-readable relative string such as "2 hours ago" or
  /// "just now".
  String get timeAgo => timeago.format(this, allowFromNow: true);

  // ---------------------------------------------------------------------------
  // Formatted strings
  // ---------------------------------------------------------------------------

  /// e.g. "Mar 29, 2026"
  String get formatted => DateFormat.yMMMd().format(this);

  /// e.g. "9:30 PM"
  String get formattedTime => DateFormat.jm().format(this);

  /// e.g. "Mar 29, 2026 at 9:30 PM"
  String get formattedDateTime =>
      '${DateFormat.yMMMd().format(this)} at ${DateFormat.jm().format(this)}';

  /// e.g. "Saturday, March 29, 2026"
  String get formattedFull => DateFormat.yMMMMEEEEd().format(this);

  /// e.g. "29/03/2026"
  String get formattedShort => DateFormat('dd/MM/yyyy').format(this);

  // ---------------------------------------------------------------------------
  // Day comparisons
  // ---------------------------------------------------------------------------

  /// `true` when this [DateTime] falls on the current calendar day.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// `true` when this [DateTime] falls on the previous calendar day.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// `true` when this [DateTime] falls on the next calendar day.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// `true` when this [DateTime] falls within the current calendar week
  /// (Monday--Sunday).
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a user-friendly label: "Today", "Yesterday", or the formatted
  /// date.
  String get smartDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return formatted;
  }

  /// Returns the start of the day (00:00:00.000).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
