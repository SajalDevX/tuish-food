/// Form-field validators that return a [String] error message when invalid
/// or `null` when valid.
///
/// Designed for direct use with [TextFormField.validator]:
/// ```dart
/// TextFormField(
///   validator: Validators.validateEmail,
/// )
/// ```
abstract final class Validators {
  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates that [value] is a non-empty, well-formed email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  /// Validates that [value] meets minimum password requirements:
  /// - At least 6 characters
  /// - Contains at least one letter
  /// - Contains at least one digit
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Password must contain at least one letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Confirm password
  // ---------------------------------------------------------------------------

  /// Validates that [value] matches [password].
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,15}$');

  /// Validates that [value] is a plausible phone number (7-15 digits,
  /// optional leading `+`, spaces, dashes, or parentheses).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Required field
  // ---------------------------------------------------------------------------

  /// Validates that [value] is non-null and non-empty after trimming.
  ///
  /// Optionally accepts a custom [fieldName] for the error message.
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      final name = fieldName ?? 'This field';
      return '$name is required';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Name
  // ---------------------------------------------------------------------------

  /// Validates a person's name (at least 2 characters, letters and spaces
  /// only).
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // OTP
  // ---------------------------------------------------------------------------

  /// Validates a 6-digit OTP code.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Please enter a valid 6-digit OTP';
    }
    return null;
  }
}
