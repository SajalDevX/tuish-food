import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions.capitalize', () {
    test('capitalizes first character', () {
      expect('hello'.capitalize, 'Hello');
    });

    test('returns empty string for empty input', () {
      expect(''.capitalize, '');
    });

    test('handles single character', () {
      expect('a'.capitalize, 'A');
    });

    test('does not change already capitalized', () {
      expect('Hello'.capitalize, 'Hello');
    });
  });

  group('StringExtensions.truncate', () {
    test('truncates long strings', () {
      expect('A very long restaurant name'.truncate(15), 'A very long res...');
    });

    test('returns original if within limit', () {
      expect('Short'.truncate(10), 'Short');
    });

    test('returns original if exactly at limit', () {
      expect('12345'.truncate(5), '12345');
    });
  });

  group('StringExtensions.isValidEmail', () {
    test('returns true for valid emails', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('test+tag@mail.co'.isValidEmail, isTrue);
    });

    test('returns false for invalid emails', () {
      expect(''.isValidEmail, isFalse);
      expect('notanemail'.isValidEmail, isFalse);
      expect('@no-local.com'.isValidEmail, isFalse);
    });
  });

  group('StringExtensions.isValidPhone', () {
    test('returns true for valid phones', () {
      expect('+1234567890'.isValidPhone, isTrue);
      expect('(123) 456-7890'.isValidPhone, isTrue);
    });

    test('returns false for invalid phones', () {
      expect(''.isValidPhone, isFalse);
      expect('abc'.isValidPhone, isFalse);
      expect('12'.isValidPhone, isFalse);
    });
  });

  group('StringExtensions.removeWhitespace', () {
    test('removes all whitespace', () {
      expect('hello world'.removeWhitespace, 'helloworld');
      expect('  spaces  '.removeWhitespace, 'spaces');
    });
  });

  group('StringExtensions.nullIfEmpty', () {
    test('returns null for empty string', () {
      expect(''.nullIfEmpty, isNull);
    });

    test('returns string for non-empty', () {
      expect('hello'.nullIfEmpty, 'hello');
    });
  });

  group('StringExtensions.toTitleCase', () {
    test('converts to title case', () {
      expect('hello world'.toTitleCase, 'Hello World');
    });

    test('handles empty string', () {
      expect(''.toTitleCase, '');
    });

    test('handles single word', () {
      expect('hello'.toTitleCase, 'Hello');
    });
  });

  group('NullableStringExtensions', () {
    test('isNullOrEmpty returns true for null', () {
      const String? s = null;
      expect(s.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty', () {
      expect(''.isNullOrEmpty, isTrue);
    });

    test('isNotNullOrEmpty returns true for non-empty', () {
      expect('hello'.isNotNullOrEmpty, isTrue);
    });
  });
}
