import 'package:intl/intl.dart';

/// Pure formatting utilities for currency, distance, duration, and identifiers.
abstract final class Formatters {
  // ---------------------------------------------------------------------------
  // Currency
  // ---------------------------------------------------------------------------

  /// Formats [amount] as a currency string.
  ///
  /// ```dart
  /// Formatters.formatCurrency(599)       // '₹599.00'
  /// Formatters.formatCurrency(1299.5, symbol: '\$') // '\$1,299.50'
  /// ```
  static String formatCurrency(
    double amount, {
    String symbol = '\u20B9', // ₹
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  // ---------------------------------------------------------------------------
  // Distance
  // ---------------------------------------------------------------------------

  /// Formats a distance given in **kilometres**.
  ///
  /// Distances below 1 km are shown in metres; otherwise in km with one
  /// decimal place.
  ///
  /// ```dart
  /// Formatters.formatDistance(2.5)   // '2.5 km'
  /// Formatters.formatDistance(0.35)  // '350 m'
  /// ```
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    // Show one decimal only when it is meaningful.
    final formatted = km.toStringAsFixed(1);
    return '$formatted km';
  }

  // ---------------------------------------------------------------------------
  // Duration
  // ---------------------------------------------------------------------------

  /// Formats a duration given in **minutes**.
  ///
  /// ```dart
  /// Formatters.formatDuration(25)  // '25 min'
  /// Formatters.formatDuration(90)  // '1h 30min'
  /// Formatters.formatDuration(60)  // '1h 0min'
  /// ```
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remaining}min';
  }

  // ---------------------------------------------------------------------------
  // Order number
  // ---------------------------------------------------------------------------

  /// Formats a raw Firestore order ID into a short, human-friendly order
  /// number.
  ///
  /// ```dart
  /// Formatters.formatOrderNumber('aBcDeFgHiJkL')
  /// // 'TF-20260329-ABCD'
  /// ```
  static String formatOrderNumber(String orderId) {
    final datePart = DateFormat('yyyyMMdd').format(DateTime.now());
    final idSuffix = orderId.length >= 4
        ? orderId.substring(0, 4).toUpperCase()
        : orderId.toUpperCase().padRight(4, 'X');
    return 'TF-$datePart-$idSuffix';
  }

  // ---------------------------------------------------------------------------
  // Compact number
  // ---------------------------------------------------------------------------

  /// Formats large numbers in compact notation (e.g. "1.2K", "3.5M").
  static String formatCompactNumber(num value) {
    return NumberFormat.compact().format(value);
  }

  // ---------------------------------------------------------------------------
  // Rating
  // ---------------------------------------------------------------------------

  /// Formats a rating value with one decimal place.
  ///
  /// ```dart
  /// Formatters.formatRating(4.567) // '4.6'
  /// ```
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }
}
