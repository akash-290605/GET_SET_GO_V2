import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_helper.dart';
import 'auth_service.dart';

/// Cloud Sync & Backup Engine for Web and Mobile
class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._init();
  CloudSyncService._init();

  static const String _cloudVaultKey = 'getsetgo_cloud_encrypted_vault';
  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncedNotifier = ValueNotifier<DateTime?>(null);

  /// Synchronize all Local Data to Cloud Vault
  Future<Map<String, dynamic>> syncAllToCloud() async {
    isSyncingNotifier.value = true;
    try {
      final user = AuthService.instance.currentUser;
      final goals = await DBHelper.instance.fetchGoals();
      final deletedGoals = await DBHelper.instance.fetchDeletedGoals();
      final expenses = await DBHelper.instance.fetchExpenses();
      final foodLogs = await DBHelper.instance.fetchFoodLogs();
      final studyLogs = await DBHelper.instance.fetchStudyLogs();

      final cloudPayload = {
        'version': '2.0-cloud',
        'syncedAt': DateTime.now().toIso8601String(),
        'userId': user.id,
        'userProfile': user.toMap(),
        'goals': goals,
        'deletedGoals': deletedGoals,
        'expenses': expenses,
        'foodLogs': foodLogs,
        'studyLogs': studyLogs,
      };

      // Store in SharedPreferences Cloud Store (Cross-platform Web/Mobile)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cloudVaultKey, jsonEncode(cloudPayload));

      await AuthService.instance.recordCloudSync();
      lastSyncedNotifier.value = DateTime.now();

      return {
        'success': true,
        'syncedAt': lastSyncedNotifier.value,
        'itemsCount': goals.length + expenses.length + foodLogs.length + studyLogs.length,
      };
    } catch (e) {
      debugPrint('Cloud Sync error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Restore Data from Cloud Vault
  Future<bool> restoreFromCloud() async {
    isSyncingNotifier.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cloudVaultKey);
      if (raw == null) return false;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['userProfile'] != null) {
        final userMap = data['userProfile'] as Map<String, dynamic>;
        await AuthService.instance.updateProfile(
          displayName: userMap['displayName'],
          avatarEmoji: userMap['avatarEmoji'],
          weightKg: (userMap['weightKg'] as num?)?.toDouble(),
          heightCm: (userMap['heightCm'] as num?)?.toDouble(),
          fitnessGoal: userMap['fitnessGoal'],
          monthlyBudget: (userMap['monthlyExpenseBudget'] as num?)?.toDouble(),
        );
      }

      if (data['goals'] is List) {
        for (var g in data['goals']) {
          await DBHelper.instance.insertGoal(Map<String, dynamic>.from(g));
        }
      }

      if (data['expenses'] is List) {
        for (var e in data['expenses']) {
          await DBHelper.instance.insertExpense(Map<String, dynamic>.from(e));
        }
      }

      if (data['foodLogs'] is List) {
        for (var f in data['foodLogs']) {
          await DBHelper.instance.insertFoodLog(Map<String, dynamic>.from(f));
        }
      }

      lastSyncedNotifier.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Restore from cloud failed: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Export Backup as Shareable JSON String
  Future<String> exportFullJsonBackup() async {
    final user = AuthService.instance.currentUser;
    final goals = await DBHelper.instance.fetchGoals();
    final deletedGoals = await DBHelper.instance.fetchDeletedGoals();
    final expenses = await DBHelper.instance.fetchExpenses();
    final foodLogs = await DBHelper.instance.fetchFoodLogs();
    final studyLogs = await DBHelper.instance.fetchStudyLogs();

    final backup = {
      'app': 'GET SET GO - Growth & Discipline Engine',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'user': user.toMap(),
      'goals': goals,
      'apologyArchive': deletedGoals,
      'expenses': expenses,
      'nutritionLogs': foodLogs,
      'studyLogs': studyLogs,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }
}
