import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:tuish_food/core/errors/exceptions.dart';

/// A typed wrapper around Firebase Cloud Functions HTTPS callables.
///
/// Usage:
/// ```dart
/// final callable = FirebaseCallable();
/// final result = await callable.call<Map<String, dynamic>>(
///   functionName: 'createOrder',
///   parameters: {'restaurantId': 'abc', 'items': [...]},
/// );
/// ```
class FirebaseCallable {
  FirebaseCallable({
    FirebaseFunctions? functions,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Default timeout applied to every callable unless overridden per-call.
  final Duration defaultTimeout;

  /// Invokes the Cloud Function identified by [functionName] and returns the
  /// deserialized result typed as [T].
  ///
  /// [parameters] is the JSON-serialisable body sent to the function.
  /// [timeout] overrides [defaultTimeout] for this single invocation.
  Future<T> call<T>({
    required String functionName,
    Map<String, dynamic>? parameters,
    Duration? timeout,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(
          timeout: timeout ?? defaultTimeout,
        ),
      );

      final result = await callable.call<T>(parameters);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'FirebaseCallable: Cloud Function "$functionName" failed '
        '-- code=${e.code}, message=${e.message}',
      );
      throw ServerException(
        _mapFunctionsError(e.code, e.message),
      );
    } catch (e) {
      debugPrint(
        'FirebaseCallable: unexpected error calling "$functionName" -- $e',
      );
      throw ServerException(
        'Failed to call cloud function "$functionName": $e',
      );
    }
  }

  /// Maps a Firebase Functions error code to a user-friendly message.
  String _mapFunctionsError(String code, String? message) {
    switch (code) {
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'The resource already exists.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unauthenticated':
        return 'You must be signed in to perform this action.';
      case 'resource-exhausted':
        return 'Request limit reached. Please try again later.';
      case 'failed-precondition':
        return 'The operation cannot be performed in the current state.';
      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'The operation timed out. Please try again.';
      case 'invalid-argument':
        return message ?? 'Invalid data provided.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'cancelled':
        return 'The operation was cancelled.';
      default:
        return message ?? 'An unexpected error occurred.';
    }
  }
}
