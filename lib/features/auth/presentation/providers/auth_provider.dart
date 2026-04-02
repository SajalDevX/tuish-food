import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tuish_food/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/domain/repositories/auth_repository.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_state.dart';
import 'package:tuish_food/injection_container.dart';

// Data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// Auth state stream provider
final appAuthStateProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

// Auth notifier provider
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Current user role provider
//
// Prefers the auth notifier state (set immediately after role selection or
// login) over the async claims/Firestore lookup. This avoids the race
// condition where custom claims haven't refreshed yet but the user has
// already selected a role.
final currentUserRoleProvider = FutureProvider<UserRole?>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  // Fast path: auth notifier already knows the role (e.g. after login or
  // role selection). Trust it — it reflects the latest user intent.
  if (authState is Authenticated) {
    return authState.user.role;
  }

  // Slow path: check custom claims + Firestore via repository
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getUserRole();
  return result.fold(
    (failure) => null,
    (role) => role,
  );
});

class AuthNotifier extends Notifier<AuthState> {
  String? _verificationId;

  @override
  AuthState build() => const AuthInitial();

  AuthRepository get _repository => ref.watch(authRepositoryProvider);
  AuthRemoteDataSource get _remoteDataSource =>
      ref.watch(authRemoteDataSourceProvider);

  String? get verificationId => _verificationId;

  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = const Unauthenticated(),
      (user) {
        if (user != null) {
          state = Authenticated(user);
        } else {
          state = const Unauthenticated();
        }
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthLoading();
    final result = await _repository.signInWithEmail(email, password);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AuthLoading();
    final result = await _repository.signUpWithEmail(
      email,
      password,
      displayName,
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    state = const AuthLoading();

    final completer = Completer<void>();

    await _remoteDataSource.signInWithPhone(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        state = PhoneCodeSent(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (message) {
        state = AuthError(message);
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        state = const AuthError(
          'Phone verification timed out. Please try again.',
        );
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      state = const AuthError('No verification in progress');
      return;
    }
    state = const AuthLoading();
    final result = await _repository.verifyOtp(_verificationId!, otp);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    final result = await _repository.signOut();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const Unauthenticated(),
    );
  }

  Future<void> resetPassword(String email) async {
    state = const AuthLoading();
    final result = await _repository.resetPassword(email);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const PasswordResetSent(),
    );
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    state = const AuthLoading();
    try {
      await _remoteDataSource.updateUserRole(uid, role);
      final result = await _repository.getCurrentUser();
      result.fold(
        (failure) => state = AuthError(failure.message),
        (user) {
          if (user != null) {
            state = Authenticated(user.copyWith(role: role));
          } else {
            state = const Unauthenticated();
          }
        },
      );
      // Invalidate so the router picks up the new role immediately
      ref.invalidate(currentUserRoleProvider);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  void resetState() {
    state = const AuthInitial();
  }
}
