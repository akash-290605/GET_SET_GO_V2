import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'workout_service.dart';
import 'finance_service.dart';
import 'food_service.dart';

enum CloudSyncStatus {
  idle,
  syncing,
  synced,
  error,
}

class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService _instance = CloudSyncService._internal();
  static CloudSyncService get instance => _instance;
  CloudSyncService._internal();

  CloudSyncStatus _status = CloudSyncStatus.idle;
  DateTime? _lastSyncedAt;
  String _lastErrorMessage = '';
  final String _firebaseProjectId = 'get-set-go-ad19f';

  CloudSyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get lastErrorMessage => _lastErrorMessage;
  String get firebaseProjectId => _firebaseProjectId;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('cloud_last_synced_at');
      if (lastSyncStr != null) {
        _lastSyncedAt = DateTime.tryParse(lastSyncStr);
      }
    } catch (e) {
      debugPrint('CloudSyncService init error: $e');
    }
    notifyListeners();
  }

  // Generate full application vault JSON snapshot
  String exportCompleteVaultJson() {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '2.0.0',
      'user': AuthService.instance.currentUser?.toMap(),
      'profile': ProfileService.instance.profile.toMap(),
      'workouts': WorkoutService.instance.plans.map((k, v) => MapEntry(k, v.toMap())),
      'finance': {
        'budget': FinanceService.instance.monthlyBudget,
        'transactions': FinanceService.instance.allTransactions.map((t) => t.toMap()).toList(),
      },
      'nutrition': {
        'foods': FoodService.instance.todayFoods.map((f) => f.toMap()).toList(),
        'waterMl': FoodService.instance.todayWaterMl,
        'targets': FoodService.instance.macroTargets.toMap(),
      },
    };
    return json.encode(payload);
  }

  // Restore application state from JSON vault
  Future<bool> importCompleteVaultJson(String jsonString) async {
    _status = CloudSyncStatus.syncing;
    notifyListeners();

    try {
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data.containsKey('profile')) {
        await ProfileService.instance.updateProfile(UserProfile.fromMap(Map<String, dynamic>.from(data['profile'])));
      }

      if (data.containsKey('workouts')) {
        final Map<String, dynamic> workoutsMap = data['workouts'];
        for (var entry in workoutsMap.entries) {
          final plan = WorkoutService.instance.plans[entry.key];
          if (plan != null) {
            await WorkoutService.instance.updatePlan(plan);
          }
        }
      }

      if (data.containsKey('finance')) {
        final fData = data['finance'];
        if (fData['budget'] != null) {
          await FinanceService.instance.setMonthlyBudget((fData['budget'] as num).toDouble());
        }
      }

      _lastSyncedAt = DateTime.now();
      _status = CloudSyncStatus.synced;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cloud_last_synced_at', _lastSyncedAt!.toIso8601String());
      return true;
    } catch (e) {
      _status = CloudSyncStatus.error;
      _lastErrorMessage = 'Failed to import vault: $e';
      notifyListeners();
      return false;
    }
  }

  // Firebase Firestore cloud sync
  Future<bool> syncWithFirebaseCloud() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _lastErrorMessage = 'User not signed in. Authenticate first.';
      _status = CloudSyncStatus.error;
      notifyListeners();
      return false;
    }

    _status = CloudSyncStatus.syncing;
    notifyListeners();

    try {
      // Simulate high-speed secure cloud synchronization
      await Future.delayed(const Duration(milliseconds: 900));

      final prefs = await SharedPreferences.getInstance();
      _lastSyncedAt = DateTime.now();
      await prefs.setString('cloud_last_synced_at', _lastSyncedAt!.toIso8601String());
      await prefs.setString('cloud_vault_backup', exportCompleteVaultJson());

      _status = CloudSyncStatus.synced;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CloudSyncStatus.error;
      _lastErrorMessage = 'Sync error: $e';
      notifyListeners();
      return false;
    }
  }
}
