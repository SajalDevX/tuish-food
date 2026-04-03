import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/services/notification_service.dart';

/// Manages syncing the FCM token to the current user's Firestore document.
///
/// Call [sync] once after Firebase init + auth is ready. It:
/// 1. Requests notification permission
/// 2. Gets the current FCM token and writes it to `users/{uid}.fcmTokens`
/// 3. Listens for token refreshes and writes them too
class FcmTokenManager {
  FcmTokenManager._();

  static final FcmTokenManager instance = FcmTokenManager._();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authSub;

  /// Start listening for auth state changes and sync tokens accordingly.
  void init({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required NotificationService notificationService,
  }) {
    _authSub?.cancel();
    _authSub = auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _syncToken(
          uid: user.uid,
          firestore: firestore,
          notificationService: notificationService,
        );
        _listenForRefresh(
          uid: user.uid,
          firestore: firestore,
          notificationService: notificationService,
        );
      } else {
        _tokenRefreshSub?.cancel();
        _tokenRefreshSub = null;
      }
    });
  }

  Future<void> _syncToken({
    required String uid,
    required FirebaseFirestore firestore,
    required NotificationService notificationService,
  }) async {
    try {
      await notificationService.requestPermission();
      final token = await notificationService.getToken();
      if (token != null) {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
        debugPrint('FcmTokenManager: token synced for $uid');
      }
    } catch (e) {
      debugPrint('FcmTokenManager: failed to sync token — $e');
    }
  }

  void _listenForRefresh({
    required String uid,
    required FirebaseFirestore firestore,
    required NotificationService notificationService,
  }) {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        notificationService.onTokenRefresh.listen((newToken) async {
      try {
        await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        });
        debugPrint('FcmTokenManager: refreshed token synced for $uid');
      } catch (e) {
        debugPrint('FcmTokenManager: failed to sync refreshed token — $e');
      }
    });
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _authSub?.cancel();
  }
}
