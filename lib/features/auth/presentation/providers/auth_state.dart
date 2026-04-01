import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class PhoneCodeSent extends AuthState {
  final String verificationId;
  const PhoneCodeSent(this.verificationId);
}

class PasswordResetSent extends AuthState {
  const PasswordResetSent();
}
