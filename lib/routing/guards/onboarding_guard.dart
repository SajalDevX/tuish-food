import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for onboarding guard logic.
///
/// This will be used to check whether a newly registered user
/// has completed the onboarding flow (e.g., role selection,
/// profile setup, address entry).
///
/// The actual implementation will read from user profile data
/// to determine onboarding completion status.
class OnboardingGuard {
  OnboardingGuard();

  /// Returns true if the user has completed onboarding.
  bool get isOnboardingComplete {
    // Will be implemented with actual onboarding check
    return true;
  }
}

final onboardingGuardProvider = Provider<OnboardingGuard>((ref) {
  return OnboardingGuard();
});
