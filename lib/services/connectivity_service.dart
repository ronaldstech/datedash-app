import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  /// Stream of connectivity status
  Stream<bool> get isOnline {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Listen to connectivity changes
  void startListening(Function(bool) onStatusChanged) {
    _connectivity.onConnectivityChanged.listen((result) {
      onStatusChanged(result != ConnectivityResult.none);
    });
  }
}
