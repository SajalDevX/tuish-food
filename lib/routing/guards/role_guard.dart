import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/enums/user_role.dart';

/// Placeholder for role-based guard logic.
///
/// The actual role-based redirect logic is handled directly in
/// [app_router.dart] via GoRouter's top-level redirect callback.
///
/// This class is reserved for any future guard logic that
/// needs to be extracted from the router configuration.
class RoleGuard {
  RoleGuard();

  /// Returns true if the current user has the required role.
  bool hasRole(UserRole requiredRole) {
    // Will be implemented with actual role check
    return false;
  }
}

final roleGuardProvider = Provider<RoleGuard>((ref) {
  return RoleGuard();
});
