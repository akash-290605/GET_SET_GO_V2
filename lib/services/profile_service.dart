import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightLogEntry {
  final DateTime date;
  final double weightKg;

  WeightLogEntry({required this.date, required this.weightKg});

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
  };

  factory WeightLogEntry.fromMap(Map<String, dynamic> map) => WeightLogEntry(
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
  );
}

class UserProfile {
  final String name;
  final int age;
  final String gender; // 'Male', 'Female', 'Other'
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final String fitnessGoal; // 'Weight Loss', 'Muscle Gain', 'Endurance', 'Maintenance'
  final String activityLevel; // 'Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'
  final String availableEquipment; // 'Full Gym', 'Dumbbells & Bands', 'Home / Bodyweight'
  final String currencySymbol; // '₹', '$', '€', '£'
  final double monthlyBudget;
  final List<WeightLogEntry> weightHistory;

  UserProfile({
    this.name = 'Akash K',
    this.age = 22,
    this.gender = 'Male',
    this.heightCm = 175.0,
    this.currentWeightKg = 72.5,
    this.targetWeightKg = 68.0,
    this.fitnessGoal = 'Muscle Gain',
    this.activityLevel = 'Moderately Active',
    this.availableEquipment = 'Full Gym',
    this.currencySymbol = '₹',
    this.monthlyBudget = 25000.0,
    List<WeightLogEntry>? weightHistory,
  }) : weightHistory = weightHistory ?? [
         WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 30)), weightKg: 75.0),
         WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 20)), weightKg: 74.2),
         WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 10)), weightKg: 73.1),
         WeightLogEntry(date: DateTime.now(), weightKg: 72.5),
       ];

  // Calculated Metrics
  double get bmi {
    if (heightCm <= 0) return 0;
    final hMeter = heightCm / 100;
    return currentWeightKg / (hMeter * hMeter);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Healthy / Optimal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  // BMR using Mifflin-St Jeor
  double get bmr {
    if (gender.toLowerCase() == 'female') {
      return (10 * currentWeightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return (10 * currentWeightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }

  // TDEE
  double get tdee {
    double mult = 1.2;
    switch (activityLevel.toLowerCase()) {
      case 'lightly active':
        mult = 1.375;
        break;
      case 'moderately active':
        mult = 1.55;
        break;
      case 'very active':
        mult = 1.725;
        break;
    }
    return bmr * mult;
  }

  // Target Daily Calories
  double get targetCalories {
    switch (fitnessGoal.toLowerCase()) {
      case 'weight loss':
      case 'fat loss':
        return (tdee - 450).clamp(1200, 4000);
      case 'muscle gain':
        return (tdee + 300).clamp(1500, 5000);
      default:
        return tdee;
    }
  }

  // Recommended Daily Protein (g)
  double get targetProteinGrams => currentWeightKg * 2.0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'gender': gender,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'fitnessGoal': fitnessGoal,
    'activityLevel': activityLevel,
    'availableEquipment': availableEquipment,
    'currencySymbol': currencySymbol,
    'monthlyBudget': monthlyBudget,
    'weightHistory': weightHistory.map((w) => w.toMap()).toList(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    var rawWh = map['weightHistory'];
    List<WeightLogEntry> wh = [];
    if (rawWh is List) {
      wh = rawWh.map((e) => WeightLogEntry.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return UserProfile(
      name: map['name']?.toString() ?? 'Akash K',
      age: (map['age'] as num?)?.toInt() ?? 22,
      gender: map['gender']?.toString() ?? 'Male',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 175.0,
      currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble() ?? 72.5,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 68.0,
      fitnessGoal: map['fitnessGoal']?.toString() ?? 'Muscle Gain',
      activityLevel: map['activityLevel']?.toString() ?? 'Moderately Active',
      availableEquipment: map['availableEquipment']?.toString() ?? 'Full Gym',
      currencySymbol: map['currencySymbol']?.toString() ?? '₹',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 25000.0,
      weightHistory: wh.isNotEmpty ? wh : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    String? fitnessGoal,
    String? activityLevel,
    String? availableEquipment,
    String? currencySymbol,
    double? monthlyBudget,
    List<WeightLogEntry>? weightHistory,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }
}

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  static ProfileService get instance => _instance;
  ProfileService._internal();

  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_profile_data');
      if (saved != null) {
        _profile = UserProfile.fromJson(saved);
      }
    } catch (e) {
      debugPrint('ProfileService init error: $e');
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_data', _profile.toJson());
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  Future<void> logNewWeight(double newWeightKg) async {
    final updatedHistory = List<WeightLogEntry>.from(_profile.weightHistory)
      ..add(WeightLogEntry(date: DateTime.now(), weightKg: newWeightKg));
    
    _profile = _profile.copyWith(
      currentWeightKg: newWeightKg,
      weightHistory: updatedHistory,
    );
    notifyListeners();
    await updateProfile(_profile);
  }
}
