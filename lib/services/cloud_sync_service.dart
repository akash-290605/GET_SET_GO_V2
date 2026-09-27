import 'package:flutter/foundation.dart';

enum CloudSyncStatus {
  synced,
  syncing,
  offline,
  error,
}

class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService instance = CloudSyncService._internal();
  CloudSyncService._internal();

  CloudSyncStatus _status = CloudSyncStatus.synced;
  CloudSyncStatus get status => _status;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> init() async {
    _status = CloudSyncStatus.synced;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  Future<void> syncAll() async {
    _status = CloudSyncStatus.syncing;
    notifyListeners();

    try {
      // Simulate/perform multi-collection sync between local SQLite and cloud vault
      await Future.delayed(const Duration(milliseconds: 600));
      _lastSyncTime = DateTime.now();
      _status = CloudSyncStatus.synced;
    } catch (e) {
      _status = CloudSyncStatus.error;
      debugPrint('Cloud sync error: $e');
    }
    notifyListeners();
  }
}
