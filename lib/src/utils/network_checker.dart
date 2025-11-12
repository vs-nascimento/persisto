import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
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
