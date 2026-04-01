import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract for checking network availability.
abstract class NetworkInfo {
  /// Returns `true` when the device has an active network connection
  /// (Wi-Fi, mobile data, ethernet, or VPN).
  Future<bool> get isConnected;
}

/// Concrete [NetworkInfo] implementation backed by [Connectivity].
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl({required Connectivity connectivity})
      : _connectivity = connectivity;

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
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

final _connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(connectivity: ref.watch(_connectivityProvider));
});
