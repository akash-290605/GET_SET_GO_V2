import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  static const String _profileKey = 'gsg_user_profile_v3';

  String currentUid = '';

  // Profile Fields
  String name = 'Akash K';
  String get userName => name;
  set userName(String v) => name = v;

  int age = 24;
  String gender = 'Male';
  String currencySymbol = '₹';
  double monthlyBudgetCap = 25000.0;

  // Strict Goal Protocol & Daily Telemetry
  String strictGoalTitle = 'Strict 10,000 Steps & Focused Execution Protocol';
  bool isStrictMode = true;
  int dailyStepTarget = 10000;
  int dailyActiveTimeMinutesTarget = 60;
  int dailyWaterIntakeMlTarget = 3000;
  int todaySteps = 7420;
  int todayActiveTimeMinutes = 45;
  int todayWaterIntakeMl = 2250;

  // 7-Day Telemetry History for Graph Visualizations (Mon - Sun)
  List<int> weeklySteps = [8450, 10200, 7800, 9600, 11400, 8900, 7420];
  List<int> weeklyActiveMinutes = [50, 65, 40, 70, 80, 55, 45];
  List<int> weeklyWaterMl = [2750, 3200, 2500, 3000, 3500, 2800, 2250];

  // Dashboard Card Customization
  List<String> dashboardWidgetsOrder = ['goals', 'finance', 'study', 'english'];

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString(_profileKey);
      if (profileStr != null) {
        final map = json.decode(profileStr) as Map<String, dynamic>;
        name = map['name'] ?? name;
        age = (map['age'] as num?)?.toInt() ?? age;
        gender = map['gender'] ?? gender;
        currencySymbol = map['currencySymbol'] ?? currencySymbol;
        monthlyBudgetCap = (map['monthlyBudgetCap'] as num?)?.toDouble() ?? monthlyBudgetCap;
        strictGoalTitle = map['strictGoalTitle'] ?? strictGoalTitle;
        isStrictMode = map['isStrictMode'] ?? isStrictMode;
        dailyStepTarget = (map['dailyStepTarget'] as num?)?.toInt() ?? dailyStepTarget;
        dailyActiveTimeMinutesTarget = (map['dailyActiveTimeMinutesTarget'] as num?)?.toInt() ?? dailyActiveTimeMinutesTarget;
        dailyWaterIntakeMlTarget = (map['dailyWaterIntakeMlTarget'] as num?)?.toInt() ?? dailyWaterIntakeMlTarget;
        todaySteps = (map['todaySteps'] as num?)?.toInt() ?? todaySteps;
        todayActiveTimeMinutes = (map['todayActiveTimeMinutes'] as num?)?.toInt() ?? todayActiveTimeMinutes;
        todayWaterIntakeMl = (map['todayWaterIntakeMl'] as num?)?.toInt() ?? todayWaterIntakeMl;

        if (map['weeklySteps'] != null) {
          weeklySteps = List<int>.from(map['weeklySteps']);
        }
        if (map['weeklyActiveMinutes'] != null) {
          weeklyActiveMinutes = List<int>.from(map['weeklyActiveMinutes']);
        }
        if (map['weeklyWaterMl'] != null) {
          weeklyWaterMl = List<int>.from(map['weeklyWaterMl']);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileService init error: $e');
    }
  }

  Future<void> loadForUser(String uid) async {
    currentUid = uid;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileKey = 'gsg_user_profile_$uid';
      final profileStr = prefs.getString(userProfileKey) ?? prefs.getString(_profileKey);
      if (profileStr != null) {
        final map = json.decode(profileStr) as Map<String, dynamic>;
        name = map['name'] ?? name;
        age = (map['age'] as num?)?.toInt() ?? age;
        gender = map['gender'] ?? gender;
        currencySymbol = map['currencySymbol'] ?? currencySymbol;
        monthlyBudgetCap = (map['monthlyBudgetCap'] as num?)?.toDouble() ?? monthlyBudgetCap;
        strictGoalTitle = map['strictGoalTitle'] ?? strictGoalTitle;
        isStrictMode = map['isStrictMode'] ?? isStrictMode;
        dailyStepTarget = (map['dailyStepTarget'] as num?)?.toInt() ?? dailyStepTarget;
        dailyActiveTimeMinutesTarget = (map['dailyActiveTimeMinutesTarget'] as num?)?.toInt() ?? dailyActiveTimeMinutesTarget;
        dailyWaterIntakeMlTarget = (map['dailyWaterIntakeMlTarget'] as num?)?.toInt() ?? dailyWaterIntakeMlTarget;
        todaySteps = (map['todaySteps'] as num?)?.toInt() ?? todaySteps;
        todayActiveTimeMinutes = (map['todayActiveTimeMinutes'] as num?)?.toInt() ?? todayActiveTimeMinutes;
        todayWaterIntakeMl = (map['todayWaterIntakeMl'] as num?)?.toInt() ?? todayWaterIntakeMl;

        if (map['weeklySteps'] != null) {
          weeklySteps = List<int>.from(map['weeklySteps']);
        }
        if (map['weeklyActiveMinutes'] != null) {
          weeklyActiveMinutes = List<int>.from(map['weeklyActiveMinutes']);
        }
        if (map['weeklyWaterMl'] != null) {
          weeklyWaterMl = List<int>.from(map['weeklyWaterMl']);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileService loadForUser error: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? gender,
  }) async {
    if (name != null) this.name = name;
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    await saveProfile();
    notifyListeners();
  }

  Future<void> updateFinance({
    String? currencySymbol,
    double? monthlyBudgetCap,
  }) async {
    if (currencySymbol != null) this.currencySymbol = currencySymbol;
    if (monthlyBudgetCap != null) this.monthlyBudgetCap = monthlyBudgetCap;
    await saveProfile();
    notifyListeners();
  }

  Future<void> updateStrictGoal({
    String? strictGoalTitle,
    bool? isStrictMode,
    int? dailyStepTarget,
    int? dailyActiveTimeMinutesTarget,
    int? dailyWaterIntakeMlTarget,
  }) async {
    if (strictGoalTitle != null) this.strictGoalTitle = strictGoalTitle;
    if (isStrictMode != null) this.isStrictMode = isStrictMode;
    if (dailyStepTarget != null) this.dailyStepTarget = dailyStepTarget;
    if (dailyActiveTimeMinutesTarget != null) this.dailyActiveTimeMinutesTarget = dailyActiveTimeMinutesTarget;
    if (dailyWaterIntakeMlTarget != null) this.dailyWaterIntakeMlTarget = dailyWaterIntakeMlTarget;
    await saveProfile();
    notifyListeners();
  }

  Future<void> logSteps(int steps) async {
    todaySteps += steps;
    if (weeklySteps.isNotEmpty) {
      weeklySteps[weeklySteps.length - 1] = todaySteps;
    }
    await saveProfile();
    notifyListeners();
  }

  Future<void> logActiveMinutes(int minutes) async {
    todayActiveTimeMinutes += minutes;
    if (weeklyActiveMinutes.isNotEmpty) {
      weeklyActiveMinutes[weeklyActiveMinutes.length - 1] = todayActiveTimeMinutes;
    }
    await saveProfile();
    notifyListeners();
  }

  Future<void> logWater(int ml) async {
    todayWaterIntakeMl += ml;
    if (weeklyWaterMl.isNotEmpty) {
      weeklyWaterMl[weeklyWaterMl.length - 1] = todayWaterIntakeMl;
    }
    await saveProfile();
    notifyListeners();
  }

  Future<void> resetDailyTelemetry() async {
    todaySteps = 0;
    todayActiveTimeMinutes = 0;
    todayWaterIntakeMl = 0;
    await saveProfile();
    notifyListeners();
  }

  Future<void> saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'name': name,
        'age': age,
        'gender': gender,
        'currencySymbol': currencySymbol,
        'monthlyBudgetCap': monthlyBudgetCap,
        'strictGoalTitle': strictGoalTitle,
        'isStrictMode': isStrictMode,
        'dailyStepTarget': dailyStepTarget,
        'dailyActiveTimeMinutesTarget': dailyActiveTimeMinutesTarget,
        'dailyWaterIntakeMlTarget': dailyWaterIntakeMlTarget,
        'todaySteps': todaySteps,
        'todayActiveTimeMinutes': todayActiveTimeMinutes,
        'todayWaterIntakeMl': todayWaterIntakeMl,
        'weeklySteps': weeklySteps,
        'weeklyActiveMinutes': weeklyActiveMinutes,
        'weeklyWaterMl': weeklyWaterMl,
      };
      final userKey = currentUid.isNotEmpty ? 'gsg_user_profile_$currentUid' : _profileKey;
      await prefs.setString(userKey, json.encode(map));
      await prefs.setString(_profileKey, json.encode(map));
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  Future<void> resetToDefaults() async {
    name = 'Akash K';
    age = 24;
    gender = 'Male';
    currencySymbol = '₹';
    monthlyBudgetCap = 25000.0;
    strictGoalTitle = 'Strict 10,000 Steps & Focused Execution Protocol';
    isStrictMode = true;
    dailyStepTarget = 10000;
    dailyActiveTimeMinutesTarget = 60;
    dailyWaterIntakeMlTarget = 3000;
    todaySteps = 7420;
    todayActiveTimeMinutes = 45;
    todayWaterIntakeMl = 2250;
    weeklySteps = [8450, 10200, 7800, 9600, 11400, 8900, 7420];
    weeklyActiveMinutes = [50, 65, 40, 70, 80, 55, 45];
    weeklyWaterMl = [2750, 3200, 2500, 3000, 3500, 2800, 2250];
    await saveProfile();
    notifyListeners();
  }
}
