import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    const user = AppUser(
      uid: 'user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      role: UserRole.customer,
    );

    test('supports value equality', () {
      const user2 = AppUser(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
      );
      expect(user, equals(user2));
    });

    test('different uid means different user', () {
      const user2 = AppUser(
        uid: 'user-2',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
      );
      expect(user, isNot(equals(user2)));
    });

    test('copyWith creates modified copy', () {
      final updated = user.copyWith(displayName: 'New Name');
      expect(updated.displayName, 'New Name');
      expect(updated.uid, user.uid);
      expect(updated.email, user.email);
      expect(updated.role, user.role);
    });

    test('copyWith with role change', () {
      final admin = user.copyWith(role: UserRole.admin);
      expect(admin.role, UserRole.admin);
      expect(admin.uid, user.uid);
    });

    test('defaults are correct', () {
      const minimal = AppUser(uid: 'uid-1');
      expect(minimal.role, UserRole.customer);
      expect(minimal.isActive, isTrue);
      expect(minimal.isBanned, isFalse);
      expect(minimal.email, isNull);
      expect(minimal.phone, isNull);
    });

    test('props includes all fields', () {
      expect(user.props, hasLength(10));
    });
  });
}
