import 'dart:async';
import 'dart:io';

/// Enum representing network connectivity status
enum ConnectivityStatus {
  online,
  offline,
}

/// Abstract interface for connectivity checking
abstract class ConnectivityService {
  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity();

  /// Convenience method to check if online
  Future<bool> isOnline();

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChange;

  /// Dispose resources
  void dispose();
}

/// Implementation of ConnectivityService that checks actual network
class ConnectivityServiceImpl implements ConnectivityService {
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _lastStatus = ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateStatus(ConnectivityStatus.online);
        return ConnectivityStatus.online;
      }
    } on SocketException catch (_) {
      _updateStatus(ConnectivityStatus.offline);
      return ConnectivityStatus.offline;
    }
    _updateStatus(ConnectivityStatus.offline);
    return ConnectivityStatus.offline;
  }

  @override
  Future<bool> isOnline() async {
    final status = await checkConnectivity();
    return status == ConnectivityStatus.online;
  }

  @override
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  void _updateStatus(ConnectivityStatus status) {
    if (_lastStatus != status) {
      _lastStatus = status;
      _statusController.add(status);
    }
  }

  @override
  void dispose() {
    _statusController.close();
  }
}

/// Mockable version of ConnectivityService for testing
class MockableConnectivityService implements ConnectivityService {
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  /// Set the mock status
  void setStatus(ConnectivityStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return _currentStatus;
  }

  @override
  Future<bool> isOnline() async {
    return _currentStatus == ConnectivityStatus.online;
  }

  @override
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  @override
  void dispose() {
    _statusController.close();
  }
}
