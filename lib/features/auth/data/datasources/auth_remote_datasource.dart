import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);

  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken)
        onCodeSent,
    required void Function(String message) onError,
  });

  Future<UserModel> verifyOtp(String verificationId, String otp);

  Future<void> signOut();

  Future<void> resetPassword(String email);

  Stream<UserModel?> authStateChanges();

  Future<UserModel?> getCurrentUser();

  Future<UserRole?> getUserRole();

  Future<void> saveUserToFirestore(UserModel user);

  Future<UserModel?> getUserFromFirestore(String uid);

  Future<void> updateUserRole(String uid, UserRole role);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  CollectionReference get _usersRef =>
      _firestore.collection(FirebaseConstants.usersCollection);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in failed: no user returned');
      }

      // Try to get the user document from Firestore
      final firestoreUser = await getUserFromFirestore(user.uid);
      if (firestoreUser != null) {
        return firestoreUser;
      }

      // Fallback: create UserModel from Firebase user
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign up failed: no user returned');
      }

      // Update the display name
      await user.updateDisplayName(displayName);
      await user.reload();

      // Create user model — no role yet; user picks on role selection screen
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        isActive: true,
        isBanned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await saveUserToFirestore(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken)
        onCodeSent,
    required void Function(String message) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapFirebaseAuthError(e.code));
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      throw AuthException('Phone verification failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('OTP verification failed: no user returned');
      }

      // Check if user already exists in Firestore
      final firestoreUser = await getUserFromFirestore(user.uid);
      if (firestoreUser != null) {
        return firestoreUser;
      }

      // New user via phone - create Firestore document
      final userModel = UserModel.fromFirebaseUser(user);
      await saveUserToFirestore(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('OTP verification failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final firestoreUser = await getUserFromFirestore(user.uid);
      return firestoreUser ?? UserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final firestoreUser = await getUserFromFirestore(user.uid);
      return firestoreUser ?? UserModel.fromFirebaseUser(user);
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<UserRole?> getUserRole() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      // Check custom claims first
      final idTokenResult = await user.getIdTokenResult();
      final roleClaim =
          idTokenResult.claims?[FirebaseConstants.roleClaimKey] as String?;
      if (roleClaim != null) {
        return UserRole.fromString(roleClaim);
      }

      // Fallback to Firestore
      final doc = await _usersRef.doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return UserRole.fromString(data?['role'] as String?);
      }

      return null;
    } catch (e) {
      throw AuthException('Failed to get user role: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw ServerException('Failed to save user data: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(
          'Failed to get user from Firestore: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      // Call Cloud Function to set both custom claims AND Firestore atomically.
      // This ensures Firestore security rules see the correct role claim.
      final callable = FirebaseFunctions.instance.httpsCallable(
        'selectUserRole',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      await callable.call<Map<String, dynamic>>({'role': role.claimValue});

      // Force token refresh so the new custom claim is available immediately
      await _firebaseAuth.currentUser?.getIdToken(true);
    } catch (e) {
      throw ServerException('Failed to update user role: ${e.toString()}');
    }
  }

  String _mapFirebaseAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'invalid-email' => 'The email address is not valid.',
      'weak-password' => 'The password is too weak.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please try again later.',
      'operation-not-allowed' => 'This sign-in method is not enabled.',
      'invalid-verification-code' => 'The OTP entered is invalid.',
      'invalid-verification-id' => 'The verification session has expired.',
      'session-expired' =>
        'The verification code has expired. Please resend.',
      'invalid-credential' => 'Invalid email or password.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
