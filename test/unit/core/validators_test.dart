import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error for null', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('missing@domain'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('test.user+tag@mail.co'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error for null or empty', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('returns error for too short', () {
      expect(Validators.validatePassword('Ab1'), isNotNull);
    });

    test('returns error for no letter', () {
      expect(Validators.validatePassword('123456'), isNotNull);
    });

    test('returns error for no digit', () {
      expect(Validators.validatePassword('abcdef'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.validatePassword('abc123'), isNull);
      expect(Validators.validatePassword('P@ssw0rd'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns error when empty', () {
      expect(Validators.validateConfirmPassword(null, 'abc123'), isNotNull);
      expect(Validators.validateConfirmPassword('', 'abc123'), isNotNull);
    });

    test('returns error when passwords do not match', () {
      expect(Validators.validateConfirmPassword('abc124', 'abc123'), isNotNull);
    });

    test('returns null when passwords match', () {
      expect(Validators.validateConfirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('Validators.validatePhone', () {
    test('returns error for null or empty', () {
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
    });

    test('returns error for invalid phone', () {
      expect(Validators.validatePhone('abc'), isNotNull);
      expect(Validators.validatePhone('12'), isNotNull);
    });

    test('returns null for valid phone', () {
      expect(Validators.validatePhone('+1234567890'), isNull);
      expect(Validators.validatePhone('(123) 456-7890'), isNull);
    });
  });

  group('Validators.validateRequired', () {
    test('returns error for null or empty', () {
      expect(Validators.validateRequired(null), isNotNull);
      expect(Validators.validateRequired('   '), isNotNull);
    });

    test('uses custom field name', () {
      final result = Validators.validateRequired('', fieldName: 'Username');
      expect(result, contains('Username'));
    });

    test('returns null for non-empty value', () {
      expect(Validators.validateRequired('hello'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('returns error for null or empty', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
    });

    test('returns error for too short', () {
      expect(Validators.validateName('A'), isNotNull);
    });

    test('returns error for invalid characters', () {
      expect(Validators.validateName('John123'), isNotNull);
    });

    test('returns null for valid name', () {
      expect(Validators.validateName('John Doe'), isNull);
      expect(Validators.validateName("O'Brien"), isNull);
      expect(Validators.validateName('Mary-Jane'), isNull);
    });
  });

  group('Validators.validateOtp', () {
    test('returns error for null or empty', () {
      expect(Validators.validateOtp(null), isNotNull);
      expect(Validators.validateOtp(''), isNotNull);
    });

    test('returns error for non-6-digit', () {
      expect(Validators.validateOtp('12345'), isNotNull);
      expect(Validators.validateOtp('1234567'), isNotNull);
      expect(Validators.validateOtp('abcdef'), isNotNull);
    });

    test('returns null for valid 6-digit OTP', () {
      expect(Validators.validateOtp('123456'), isNull);
      expect(Validators.validateOtp('000000'), isNull);
    });
  });
}
