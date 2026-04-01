import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Online / offline detection backed by [Connectivity].
///
/// Exposes a synchronous [isConnected] getter (cached from the latest check)
/// and a reactive [onConnectivityChanged] stream.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// The last-known connectivity state.  Updated automatically after [init].
  bool get isConnected => _isConnected;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Performs an initial connectivity check and starts listening for changes.
  ///
  /// Call once during app startup; subsequent calls are no-ops.
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(results);
    debugPrint('ConnectivityService: initial state -- connected=$_isConnected');

    _subscription ??= _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = _hasConnection(results);
      debugPrint(
        'ConnectivityService: connectivity changed -- connected=$_isConnected',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Reactive stream
  // ---------------------------------------------------------------------------

  /// Emits `true` when the device gains connectivity and `false` when it
  /// loses it.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Cancels the internal subscription.  Call when the service is no longer
  /// needed (typically never for a global singleton).
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}

// -----------------------------------------------------------------------------
// Riverpod providers
// -----------------------------------------------------------------------------

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// A stream provider that emits connectivity status changes.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
