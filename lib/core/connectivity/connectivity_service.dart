import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline }

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  NetworkStatus _status = NetworkStatus.offline;
  bool _isManualOfflineMode = false;

  NetworkStatus get status => _isManualOfflineMode ? NetworkStatus.offline : _status;
  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;
  bool get isManualOfflineMode => _isManualOfflineMode;

  ConnectivityService._internal() {
    _initConnectivity();
  }

  // Testing constructor
  ConnectivityService.forTesting({NetworkStatus initialStatus = NetworkStatus.offline}) {
    _status = initialStatus;
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);

      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _status = NetworkStatus.offline;
      notifyListeners();
    }
  }

  void _updateStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet) {
      _status = NetworkStatus.online;
    } else {
      _status = NetworkStatus.offline;
    }
    notifyListeners();
  }

  /// Toggle manual offline simulation for testing offline features without turning off WiFi
  void setManualOfflineMode(bool enabled) {
    _isManualOfflineMode = enabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
