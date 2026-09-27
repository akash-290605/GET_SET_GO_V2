import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../db_helper.dart';
import 'auth_service.dart';
import 'profile_service.dart';

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
      final user = AuthService.instance.currentUser;
      final uid = user?.uid ?? 'local_user';

      // 1. Fetch local SQLite dataset
      final expenses = await DBHelper.instance.getExpenses();
      final meals = await DBHelper.instance.getMeals();
      final workouts = await DBHelper.instance.getWorkoutPlans();

      final profile = ProfileService.instance;
      final payload = {
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'userId': uid,
        'userEmail': user?.email,
        'userName': profile.userName,
        'profile': {
          'age': profile.age,
          'heightCm': profile.heightCm,
          'weightKg': profile.weightKg,
          'targetWeightKg': profile.targetWeightKg,
          'fitnessGoal': profile.fitnessGoal,
          'monthlyBudgetCap': profile.monthlyBudgetCap,
          'currencySymbol': profile.currencySymbol,
          'strictGoalTitle': profile.strictGoalTitle,
          'dailyStepTarget': profile.dailyStepTarget,
        },
        'expensesCount': expenses.length,
        'mealsCount': meals.length,
        'workoutsCount': workouts.length,
        'meals': meals.map((m) => m.toMap()).toList(),
        'workouts': workouts.map((w) => w.toMap()).toList(),
        'expenses': expenses,
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('cloud_backup')
            .set(payload, SetOptions(merge: true));
      } catch (fsErr) {
        debugPrint('Firestore write: $fsErr');
      }

      _lastSyncTime = DateTime.now();
      _status = CloudSyncStatus.synced;
    } catch (e) {
      _status = CloudSyncStatus.error;
      debugPrint('Cloud sync error: $e');
    }
    notifyListeners();
  }
}
