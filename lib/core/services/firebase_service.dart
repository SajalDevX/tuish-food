import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Utility class that ensures Firebase is initialized exactly once.
///
/// Call [FirebaseService.init] early in your app startup (e.g. in `main()`),
/// before accessing any Firebase products.
abstract final class FirebaseService {
  static bool _initialized = false;

  /// Initializes the default Firebase app.
  ///
  /// Safe to call multiple times -- subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('FirebaseService: Firebase initialized successfully');
    } on FirebaseException catch (e) {
      // If Firebase is already initialized (e.g. from a native plugin),
      // treat it as success rather than an error.
      if (e.code == 'duplicate-app') {
        _initialized = true;
        debugPrint('FirebaseService: Firebase was already initialized');
      } else {
        debugPrint('FirebaseService: initialization failed -- ${e.message}');
        rethrow;
      }
    }
  }

  /// Whether Firebase has been initialized via [init].
  static bool get isInitialized => _initialized;
}
