import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/errors/failures.dart';

void main() {
  group('Failure subclasses', () {
    test('ServerFailure has default message', () {
      const failure = ServerFailure();
      expect(failure.message, 'Server error occurred');
    });

    test('ServerFailure accepts custom message', () {
      const failure = ServerFailure('Custom server error');
      expect(failure.message, 'Custom server error');
    });

    test('AuthFailure has default message', () {
      const failure = AuthFailure();
      expect(failure.message, 'Authentication failed');
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'No internet connection');
    });

    test('CacheFailure has default message', () {
      const failure = CacheFailure();
      expect(failure.message, 'Cache error occurred');
    });

    test('ValidationFailure has default message', () {
      const failure = ValidationFailure();
      expect(failure.message, 'Validation failed');
    });

    test('PermissionFailure has default message', () {
      const failure = PermissionFailure();
      expect(failure.message, 'Permission denied');
    });

    test('NotFoundFailure has default message', () {
      const failure = NotFoundFailure();
      expect(failure.message, 'Resource not found');
    });

    test('all subclasses are subtypes of Failure', () {
      const failures = <Failure>[
        ServerFailure(),
        AuthFailure(),
        NetworkFailure(),
        CacheFailure(),
        ValidationFailure(),
        PermissionFailure(),
        NotFoundFailure(),
      ];
      expect(failures, hasLength(7));
    });
  });
}
