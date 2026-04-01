import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/utils/formatters.dart';

void main() {
  group('Formatters.formatCurrency', () {
    test('formats with default rupee symbol', () {
      final result = Formatters.formatCurrency(599);
      expect(result, contains('599'));
      expect(result, contains('\u20B9'));
    });

    test('formats with custom symbol', () {
      final result = Formatters.formatCurrency(1299.5, symbol: '\$');
      expect(result, contains('\$'));
      expect(result, contains('1,299.50'));
    });

    test('formats zero correctly', () {
      final result = Formatters.formatCurrency(0);
      expect(result, contains('0.00'));
    });
  });

  group('Formatters.formatDistance', () {
    test('shows metres for distances under 1 km', () {
      expect(Formatters.formatDistance(0.35), '350 m');
      expect(Formatters.formatDistance(0.5), '500 m');
    });

    test('shows km for distances >= 1 km', () {
      expect(Formatters.formatDistance(2.5), '2.5 km');
      expect(Formatters.formatDistance(1.0), '1.0 km');
    });
  });

  group('Formatters.formatDuration', () {
    test('shows minutes for durations under 60 min', () {
      expect(Formatters.formatDuration(25), '25 min');
      expect(Formatters.formatDuration(0), '0 min');
    });

    test('shows hours and minutes for durations >= 60 min', () {
      expect(Formatters.formatDuration(90), '1h 30min');
    });

    test('shows hours only when remainder is 0', () {
      expect(Formatters.formatDuration(60), '1h');
      expect(Formatters.formatDuration(120), '2h');
    });
  });

  group('Formatters.formatOrderNumber', () {
    test('returns TF-prefixed order number', () {
      final result = Formatters.formatOrderNumber('aBcDeFgHiJkL');
      expect(result, startsWith('TF-'));
      expect(result, endsWith('-ABCD'));
    });

    test('pads short order IDs', () {
      final result = Formatters.formatOrderNumber('ab');
      expect(result, endsWith('-ABXX'));
    });
  });

  group('Formatters.formatCompactNumber', () {
    test('formats large numbers', () {
      expect(Formatters.formatCompactNumber(1200), isNotEmpty);
      expect(Formatters.formatCompactNumber(3500000), isNotEmpty);
    });

    test('formats small numbers', () {
      expect(Formatters.formatCompactNumber(5), isNotEmpty);
    });
  });

  group('Formatters.formatRating', () {
    test('formats to one decimal place', () {
      expect(Formatters.formatRating(4.567), '4.6');
      expect(Formatters.formatRating(3.0), '3.0');
      expect(Formatters.formatRating(5.0), '5.0');
    });
  });
}
