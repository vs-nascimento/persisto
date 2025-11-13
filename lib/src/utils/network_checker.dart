import 'package:connectivity_plus/connectivity_plus.dart';

/// Helper utility to determine if any network interface is online.
class NetworkChecker {
  /// Returns `true` when at least one connectivity result is not `none`.
  static Future<bool> get isOnline async {
    final dynamic result = await Connectivity().checkConnectivity();

    if (result is List<ConnectivityResult>) {
      if (result.isEmpty) return false;
      return result.any((type) => type != ConnectivityResult.none);
    }

    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    return false;
  }
}
