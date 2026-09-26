import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User Profile Model for Local & Cloud Authentication
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String avatarEmoji;
  final double weightKg;
  final double heightCm;
  final String fitnessGoal;
  final double monthlyExpenseBudget;
  final bool isCloudAccount;
  final DateTime lastCloudSyncTime;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarEmoji = '⚡',
    this.weightKg = 72.5,
    this.heightCm = 178.0,
    this.fitnessGoal = 'Lean Shredding & Peak Athleticism 🔥',
    this.monthlyExpenseBudget = 25000.0,
    this.isCloudAccount = true,
    required this.lastCloudSyncTime,
  });

  String get disciplineRank {
    if (weightKg > 0 && monthlyExpenseBudget > 0) return 'TITAN WARRIOR 🏆';
    return 'DISCIPLINE RECRUIT 🛡️';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'fitnessGoal': fitnessGoal,
        'monthlyExpenseBudget': monthlyExpenseBudget,
        'isCloudAccount': isCloudAccount,
        'lastCloudSyncTime': lastCloudSyncTime.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: map['email'] ?? 'titan@getsetgo.app',
        displayName: map['displayName'] ?? 'Titan Athlete',
        avatarEmoji: map['avatarEmoji'] ?? '⚡',
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 72.5,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 178.0,
        fitnessGoal: map['fitnessGoal'] ?? 'Lean Shredding & Peak Athleticism 🔥',
        monthlyExpenseBudget: (map['monthlyExpenseBudget'] as num?)?.toDouble() ?? 25000.0,
        isCloudAccount: map['isCloudAccount'] ?? true,
        lastCloudSyncTime: map['lastCloudSyncTime'] != null
            ? DateTime.tryParse(map['lastCloudSyncTime']) ?? DateTime.now()
            : DateTime.now(),
      );

  AppUser copyWith({
    String? email,
    String? displayName,
    String? avatarEmoji,
    double? weightKg,
    double? heightCm,
    String? fitnessGoal,
    double? monthlyExpenseBudget,
    bool? isCloudAccount,
    DateTime? lastCloudSyncTime,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      monthlyExpenseBudget: monthlyExpenseBudget ?? this.monthlyExpenseBudget,
      isCloudAccount: isCloudAccount ?? this.isCloudAccount,
      lastCloudSyncTime: lastCloudSyncTime ?? this.lastCloudSyncTime,
    );
  }
}

/// Global Authentication & Cloud Account Service
class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String _userPrefKey = 'getsetgo_current_user_data';
  static const String _cloudSyncFlagKey = 'getsetgo_cloud_sync_active';

  late ValueNotifier<AppUser> currentUserNotifier;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userPrefKey);

    if (rawUser != null) {
      try {
        final map = jsonDecode(rawUser) as Map<String, dynamic>;
        currentUserNotifier = ValueNotifier<AppUser>(AppUser.fromMap(map));
      } catch (_) {
        currentUserNotifier = ValueNotifier<AppUser>(_getDefaultUser());
      }
    } else {
      currentUserNotifier = ValueNotifier<AppUser>(_getDefaultUser());
      await _saveUserToPrefs(currentUserNotifier.value);
    }
    _initialized = true;
  }

  AppUser _getDefaultUser() {
    return AppUser(
      id: 'titan_master_1',
      email: 'warrior@getsetgo.app',
      displayName: 'Titan Growth Champion',
      avatarEmoji: '⚡',
      weightKg: 74.0,
      heightCm: 178.0,
      fitnessGoal: 'Hypertrophy, 5KM Endurance & High Discipline 💪',
      monthlyExpenseBudget: 30000.0,
      isCloudAccount: true,
      lastCloudSyncTime: DateTime.now(),
    );
  }

  AppUser get currentUser => _initialized ? currentUserNotifier.value : _getDefaultUser();

  Future<void> _saveUserToPrefs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrefKey, jsonEncode(user.toMap()));
  }

  /// Sign In with Cloud Account
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulating cloud auth response
    final updated = currentUser.copyWith(
      email: email,
      isCloudAccount: true,
      lastCloudSyncTime: DateTime.now(),
    );
    currentUserNotifier.value = updated;
    await _saveUserToPrefs(updated);
    return true;
  }

  /// Sign Up for a new Cloud Account
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required double weightKg,
    required double heightCm,
    required String fitnessGoal,
    required double monthlyBudget,
    String avatarEmoji = '⚡',
  }) async {
    await Future.delayed(const Duration(milliseconds: 750)); // Simulating secure cloud account registration
    final newUser = AppUser(
      id: 'cloud_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      weightKg: weightKg,
      heightCm: heightCm,
      fitnessGoal: fitnessGoal,
      monthlyExpenseBudget: monthlyBudget,
      isCloudAccount: true,
      lastCloudSyncTime: DateTime.now(),
    );
    currentUserNotifier.value = newUser;
    await _saveUserToPrefs(newUser);
    return true;
  }

  /// Update Profile Settings
  Future<void> updateProfile({
    String? displayName,
    String? avatarEmoji,
    double? weightKg,
    double? heightCm,
    String? fitnessGoal,
    double? monthlyBudget,
  }) async {
    final updated = currentUser.copyWith(
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      weightKg: weightKg,
      heightCm: heightCm,
      fitnessGoal: fitnessGoal,
      monthlyExpenseBudget: monthlyBudget,
      lastCloudSyncTime: DateTime.now(),
    );
    currentUserNotifier.value = updated;
    await _saveUserToPrefs(updated);
  }

  /// Sign Out / Switch to Offline Guest
  Future<void> signOut() async {
    final guest = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'offline@guest.local',
      displayName: 'Offline Guest',
      avatarEmoji: '🛡️',
      weightKg: 70.0,
      heightCm: 175.0,
      fitnessGoal: 'Daily Habit Discipline',
      monthlyExpenseBudget: 20000.0,
      isCloudAccount: false,
      lastCloudSyncTime: DateTime.now(),
    );
    currentUserNotifier.value = guest;
    await _saveUserToPrefs(guest);
  }

  /// Mark Cloud Sync Complete
  Future<void> recordCloudSync() async {
    final updated = currentUser.copyWith(lastCloudSyncTime: DateTime.now());
    currentUserNotifier.value = updated;
    await _saveUserToPrefs(updated);
  }
}
