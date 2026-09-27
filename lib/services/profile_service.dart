import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_models.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  static const String _profileKey = 'gsg_user_profile_v3';
  static const String _nutritionTargetKey = 'gsg_nutrition_target_v3';
  static const String _weightHistoryKey = 'gsg_weight_history_v3';

  // Profile Fields
  String name = 'Akash K';
  String get userName => name;
  set userName(String v) => name = v;

  int age = 24;
  double heightCm = 175.0;
  double weightKg = 72.5;
  double targetWeightKg = 70.0;
  String fitnessGoal = 'Muscle Gain & Hypertrophy';
  String activityLevel = 'Moderately Active (3-5 days)';
  String availableEquipment = 'Full Gym (Barbells, Dumbbells, Cables, Machines)';
  String currencySymbol = '₹';
  double monthlyBudgetCap = 25000.0;
  String preferredUnit = 'kg';

  // Strict Goal Protocol & Daily Telemetry
  String strictGoalTitle = 'Strict 10,000 Steps & Lean Hypertrophy Protocol';
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

  // Daily Nutrition Targets
  DailyNutritionTarget nutritionTarget = DailyNutritionTarget(
    calorieTarget: 2200.0,
    proteinTargetGrams: 140.0,
    carbTargetGrams: 250.0,
    fatTargetGrams: 65.0,
    fiberTargetGrams: 30.0,
  );

  // Weight History
  List<Map<String, dynamic>> weightHistory = [];

  // Dashboard Card Customization
  List<String> dashboardWidgetsOrder = ['fitness', 'nutrition', 'finance'];

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString(_profileKey);
      if (profileStr != null) {
        final map = json.decode(profileStr) as Map<String, dynamic>;
        name = map['name'] ?? name;
        age = (map['age'] as num?)?.toInt() ?? age;
        heightCm = (map['heightCm'] as num?)?.toDouble() ?? heightCm;
        weightKg = (map['weightKg'] as num?)?.toDouble() ?? weightKg;
        targetWeightKg = (map['targetWeightKg'] as num?)?.toDouble() ?? targetWeightKg;
        fitnessGoal = map['fitnessGoal'] ?? fitnessGoal;
        activityLevel = map['activityLevel'] ?? activityLevel;
        availableEquipment = map['availableEquipment'] ?? availableEquipment;
        currencySymbol = map['currencySymbol'] ?? currencySymbol;
        monthlyBudgetCap = (map['monthlyBudgetCap'] as num?)?.toDouble() ?? monthlyBudgetCap;
        preferredUnit = map['preferredUnit'] ?? preferredUnit;
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

      final targetStr = prefs.getString(_nutritionTargetKey);
      if (targetStr != null) {
        nutritionTarget = DailyNutritionTarget.fromMap(json.decode(targetStr));
      }

      final historyStr = prefs.getString(_weightHistoryKey);
      if (historyStr != null) {
        weightHistory = List<Map<String, dynamic>>.from(json.decode(historyStr));
      } else {
        weightHistory = [
          {'date': DateTime.now().subtract(const Duration(days: 21)).toIso8601String(), 'weight': 74.0},
          {'date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(), 'weight': 73.2},
          {'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(), 'weight': 72.8},
          {'date': DateTime.now().toIso8601String(), 'weight': 72.5},
        ];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileService init error: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? fitnessGoal,
    String? activityLevel,
    String? availableEquipment,
    String? preferredUnit,
  }) async {
    if (name != null) this.name = name;
    if (age != null) this.age = age;
    if (heightCm != null) this.heightCm = heightCm;
    if (weightKg != null) {
      this.weightKg = weightKg;
      await logWeight(weightKg);
    }
    if (targetWeightKg != null) this.targetWeightKg = targetWeightKg;
    if (fitnessGoal != null) this.fitnessGoal = fitnessGoal;
    if (activityLevel != null) this.activityLevel = activityLevel;
    if (availableEquipment != null) this.availableEquipment = availableEquipment;
    if (preferredUnit != null) this.preferredUnit = preferredUnit;

    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateFinance({
    String? currencySymbol,
    double? monthlyBudgetCap,
  }) async {
    if (currencySymbol != null) this.currencySymbol = currencySymbol;
    if (monthlyBudgetCap != null) this.monthlyBudgetCap = monthlyBudgetCap;

    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateNutritionTarget(DailyNutritionTarget newTarget) async {
    nutritionTarget = newTarget;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nutritionTargetKey, json.encode(newTarget.toMap()));
    } catch (e) {
      debugPrint('Error saving nutrition target: $e');
    }
    notifyListeners();
  }

  Future<void> logWeight(double weight) async {
    weightKg = weight;
    weightHistory.add({
      'date': DateTime.now().toIso8601String(),
      'weight': weight,
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weightHistoryKey, json.encode(weightHistory));
    } catch (e) {
      debugPrint('Error saving weight history: $e');
    }
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateStrictGoal({
    String? strictGoalTitle,
    bool? isStrictMode,
    int? dailyStepTarget,
    int? dailyActiveTimeMinutesTarget,
    int? dailyWaterIntakeMlTarget,
    double? targetWeightKg,
  }) async {
    if (strictGoalTitle != null) this.strictGoalTitle = strictGoalTitle;
    if (isStrictMode != null) this.isStrictMode = isStrictMode;
    if (dailyStepTarget != null) this.dailyStepTarget = dailyStepTarget;
    if (dailyActiveTimeMinutesTarget != null) this.dailyActiveTimeMinutesTarget = dailyActiveTimeMinutesTarget;
    if (dailyWaterIntakeMlTarget != null) this.dailyWaterIntakeMlTarget = dailyWaterIntakeMlTarget;
    if (targetWeightKg != null) this.targetWeightKg = targetWeightKg;

    await _saveProfile();
    notifyListeners();
  }

  Future<void> logSteps(int delta) async {
    todaySteps = (todaySteps + delta).clamp(0, 100000);
    if (weeklySteps.isNotEmpty) weeklySteps[weeklySteps.length - 1] = todaySteps;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setSteps(int steps) async {
    todaySteps = steps.clamp(0, 100000);
    if (weeklySteps.isNotEmpty) weeklySteps[weeklySteps.length - 1] = todaySteps;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> logActiveMinutes(int delta) async {
    todayActiveTimeMinutes = (todayActiveTimeMinutes + delta).clamp(0, 1440);
    if (weeklyActiveMinutes.isNotEmpty) weeklyActiveMinutes[weeklyActiveMinutes.length - 1] = todayActiveTimeMinutes;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setActiveMinutes(int minutes) async {
    todayActiveTimeMinutes = minutes.clamp(0, 1440);
    if (weeklyActiveMinutes.isNotEmpty) weeklyActiveMinutes[weeklyActiveMinutes.length - 1] = todayActiveTimeMinutes;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> logWater(int deltaMl) async {
    todayWaterIntakeMl = (todayWaterIntakeMl + deltaMl).clamp(0, 10000);
    if (weeklyWaterMl.isNotEmpty) weeklyWaterMl[weeklyWaterMl.length - 1] = todayWaterIntakeMl;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setWater(int ml) async {
    todayWaterIntakeMl = ml.clamp(0, 10000);
    if (weeklyWaterMl.isNotEmpty) weeklyWaterMl[weeklyWaterMl.length - 1] = todayWaterIntakeMl;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateWaterTarget(int targetMl) async {
    dailyWaterIntakeMlTarget = targetMl.clamp(500, 10000);
    await _saveProfile();
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'fitnessGoal': fitnessGoal,
        'activityLevel': activityLevel,
        'availableEquipment': availableEquipment,
        'currencySymbol': currencySymbol,
        'monthlyBudgetCap': monthlyBudgetCap,
        'preferredUnit': preferredUnit,
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
      await prefs.setString(_profileKey, json.encode(map));
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }
}
