/// Utility extensions on [String].
extension StringExtensions on String {
  /// Returns a copy with the first character uppercased.
  ///
  /// ```dart
  /// 'hello'.capitalize // 'Hello'
  /// ''.capitalize      // ''
  /// ```
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncates the string to [maxLength] characters and appends an ellipsis
  /// if the original exceeds [maxLength].
  ///
  /// ```dart
  /// 'A very long restaurant name'.truncate(15) // 'A very long res...'
  /// ```
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// `true` when the string matches a standard email pattern.
  bool get isValidEmail {
    if (isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// `true` when the string looks like a valid phone number.
  ///
  /// Accepts optional leading `+`, followed by 7-15 digits (with optional
  /// spaces, dashes or parentheses in between).
  bool get isValidPhone {
    if (isEmpty) return false;
    return RegExp(
      r'^\+?[\d\s\-()]{7,15}$',
    ).hasMatch(this);
  }

  /// Removes all whitespace characters.
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Returns `null` when the string is empty; otherwise returns [this].
  ///
  /// Useful for coalescing empty strings in form fields:
  /// ```dart
  /// final value = textController.text.nullIfEmpty ?? 'default';
  /// ```
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Converts a potentially multi-word string into title-case
  /// ("hello world" -> "Hello World").
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

/// Nullable variant so callers don't need to null-check before accessing
/// the extension.
extension NullableStringExtensions on String? {
  /// `true` when the string is either `null` or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// `true` when the string is neither `null` nor empty.
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
