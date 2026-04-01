import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for auth guard logic.
///
/// The actual redirect logic is handled directly in [app_router.dart]
/// via GoRouter's top-level redirect callback.
///
/// This class is reserved for any future guard logic that
/// needs to be extracted from the router configuration.
class AuthGuard {
  AuthGuard();

  /// Returns true if the user is currently authenticated.
  bool get isAuthenticated {
    // Will be implemented with actual auth check
    return false;
  }
}

final authGuardProvider = Provider<AuthGuard>((ref) {
  return AuthGuard();
});
