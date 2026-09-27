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

class BodyPhotoEntry {
  final String id;
  final DateTime date;
  final String imageBase64; // Base64 string for cross-platform web and mobile storage
  final double weightKg;
  final double bmi;
  final String notes;

  BodyPhotoEntry({
    required this.id,
    required this.date,
    required this.imageBase64,
    required this.weightKg,
    required this.bmi,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'imageBase64': imageBase64,
    'weightKg': weightKg,
    'bmi': bmi,
    'notes': notes,
  };

  factory BodyPhotoEntry.fromMap(Map<String, dynamic> map) => BodyPhotoEntry(
    id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    imageBase64: map['imageBase64']?.toString() ?? '',
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
    bmi: (map['bmi'] as num?)?.toDouble() ?? 22.5,
    notes: map['notes']?.toString() ?? '',
  );
}

class WeeklyHealthReport {
  final DateTime startDate;
  final DateTime endDate;
  final double startWeight;
  final double endWeight;
  final double weightChange;
  final double currentBmi;
  final String bmiCategory;
  final double bmiDelta;
  final int totalSteps;
  final int dailyAverageSteps;
  final double stepComplianceRate;
  final int totalActiveMinutes;
  final int workoutsCompleted;
  final int totalWorkoutsPlanned;
  final double workoutAdherenceRate;
  final BodyPhotoEntry? latestPhoto;
  final String aiCoachGrade;
  final String aiEvaluation;
  final List<String> keyWins;
  final List<String> recommendations;

  WeeklyHealthReport({
    required this.startDate,
    required this.endDate,
    required this.startWeight,
    required this.endWeight,
    required this.weightChange,
    required this.currentBmi,
    required this.bmiCategory,
    required this.bmiDelta,
    required this.totalSteps,
    required this.dailyAverageSteps,
    required this.stepComplianceRate,
    required this.totalActiveMinutes,
    required this.workoutsCompleted,
    required this.totalWorkoutsPlanned,
    required this.workoutAdherenceRate,
    this.latestPhoto,
    required this.aiCoachGrade,
    required this.aiEvaluation,
    required this.keyWins,
    required this.recommendations,
  });
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

  // Strict Goal & Telemetry Settings
  final String strictGoalTitle;
  final bool isStrictMode;
  final int dailyStepTarget;
  final int todaySteps;
  final int dailyActiveTimeMinutesTarget;
  final int todayActiveTimeMinutes;
  final List<BodyPhotoEntry> bodyPhotos;

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
    this.strictGoalTitle = 'Strict 10,000 Steps & Lean Hypertrophy Protocol',
    this.isStrictMode = true,
    this.dailyStepTarget = 10000,
    this.todaySteps = 8450,
    this.dailyActiveTimeMinutesTarget = 60,
    this.todayActiveTimeMinutes = 45,
    List<BodyPhotoEntry>? bodyPhotos,
  })  : weightHistory = weightHistory ?? [
          WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 30)), weightKg: 75.0),
          WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 20)), weightKg: 74.2),
          WeightLogEntry(date: DateTime.now().subtract(const Duration(days: 10)), weightKg: 73.1),
          WeightLogEntry(date: DateTime.now(), weightKg: 72.5),
        ],
        bodyPhotos = bodyPhotos ?? [];

  // Deterministic BMI Calculation
  double get bmi {
    if (heightCm <= 0) return 0;
    final hMeter = heightCm / 100;
    return currentWeightKg / (hMeter * hMeter);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Optimal / Healthy';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  double get stepsProgressRatio {
    if (dailyStepTarget <= 0) return 1.0;
    return (todaySteps / dailyStepTarget).clamp(0.0, 1.0);
  }

  double get activeTimeProgressRatio {
    if (dailyActiveTimeMinutesTarget <= 0) return 1.0;
    return (todayActiveTimeMinutes / dailyActiveTimeMinutesTarget).clamp(0.0, 1.0);
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
    'strictGoalTitle': strictGoalTitle,
    'isStrictMode': isStrictMode,
    'dailyStepTarget': dailyStepTarget,
    'todaySteps': todaySteps,
    'dailyActiveTimeMinutesTarget': dailyActiveTimeMinutesTarget,
    'todayActiveTimeMinutes': todayActiveTimeMinutes,
    'bodyPhotos': bodyPhotos.map((p) => p.toMap()).toList(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    var rawWh = map['weightHistory'];
    List<WeightLogEntry> wh = [];
    if (rawWh is List) {
      wh = rawWh.map((e) => WeightLogEntry.fromMap(Map<String, dynamic>.from(e))).toList();
    }

    var rawPhotos = map['bodyPhotos'];
    List<BodyPhotoEntry> photos = [];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => BodyPhotoEntry.fromMap(Map<String, dynamic>.from(e))).toList();
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
      strictGoalTitle: map['strictGoalTitle']?.toString() ?? 'Strict 10,000 Steps & Lean Hypertrophy Protocol',
      isStrictMode: map['isStrictMode'] as bool? ?? true,
      dailyStepTarget: (map['dailyStepTarget'] as num?)?.toInt() ?? 10000,
      todaySteps: (map['todaySteps'] as num?)?.toInt() ?? 8450,
      dailyActiveTimeMinutesTarget: (map['dailyActiveTimeMinutesTarget'] as num?)?.toInt() ?? 60,
      todayActiveTimeMinutes: (map['todayActiveTimeMinutes'] as num?)?.toInt() ?? 45,
      bodyPhotos: photos,
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
    String? strictGoalTitle,
    bool? isStrictMode,
    int? dailyStepTarget,
    int? todaySteps,
    int? dailyActiveTimeMinutesTarget,
    int? todayActiveTimeMinutes,
    List<BodyPhotoEntry>? bodyPhotos,
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
      strictGoalTitle: strictGoalTitle ?? this.strictGoalTitle,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      dailyStepTarget: dailyStepTarget ?? this.dailyStepTarget,
      todaySteps: todaySteps ?? this.todaySteps,
      dailyActiveTimeMinutesTarget: dailyActiveTimeMinutesTarget ?? this.dailyActiveTimeMinutesTarget,
      todayActiveTimeMinutes: todayActiveTimeMinutes ?? this.todayActiveTimeMinutes,
      bodyPhotos: bodyPhotos ?? this.bodyPhotos,
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

  Future<void> updateStrictGoal({
    String? strictGoalTitle,
    bool? isStrictMode,
    int? dailyStepTarget,
    int? dailyActiveTimeMinutesTarget,
    double? targetWeightKg,
  }) async {
    _profile = _profile.copyWith(
      strictGoalTitle: strictGoalTitle,
      isStrictMode: isStrictMode,
      dailyStepTarget: dailyStepTarget,
      dailyActiveTimeMinutesTarget: dailyActiveTimeMinutesTarget,
      targetWeightKg: targetWeightKg,
    );
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> logSteps(int steps) async {
    _profile = _profile.copyWith(todaySteps: steps.clamp(0, 100000));
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> addSteps(int delta) async {
    final newSteps = (_profile.todaySteps + delta).clamp(0, 100000);
    _profile = _profile.copyWith(todaySteps: newSteps);
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> logActiveTime(int minutes) async {
    _profile = _profile.copyWith(todayActiveTimeMinutes: minutes.clamp(0, 1440));
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> addActiveTime(int deltaMinutes) async {
    final newMins = (_profile.todayActiveTimeMinutes + deltaMinutes).clamp(0, 1440);
    _profile = _profile.copyWith(todayActiveTimeMinutes: newMins);
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> addBodyPhoto(BodyPhotoEntry photo) async {
    final updated = List<BodyPhotoEntry>.from(_profile.bodyPhotos)..insert(0, photo);
    _profile = _profile.copyWith(bodyPhotos: updated);
    notifyListeners();
    await updateProfile(_profile);
  }

  Future<void> deleteBodyPhoto(String photoId) async {
    final updated = _profile.bodyPhotos.where((p) => p.id != photoId).toList();
    _profile = _profile.copyWith(bodyPhotos: updated);
    notifyListeners();
    await updateProfile(_profile);
  }

  WeeklyHealthReport generateWeeklyHealthReport({
    required int workoutsCompleted,
    required int totalWorkoutsPlanned,
  }) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final history = _profile.weightHistory;
    final startWeight = history.isNotEmpty ? history.first.weightKg : _profile.currentWeightKg;
    final endWeight = _profile.currentWeightKg;
    final weightChange = endWeight - startWeight;

    final curBmi = _profile.bmi;
    final hM = _profile.heightCm / 100;
    final startBmi = hM > 0 ? startWeight / (hM * hM) : curBmi;
    final bmiDelta = curBmi - startBmi;

    final estimatedWeekSteps = (_profile.todaySteps * 6.8).round();
    final avgDailySteps = (estimatedWeekSteps / 7).round();
    final stepCompliance = _profile.dailyStepTarget > 0
        ? (avgDailySteps / _profile.dailyStepTarget).clamp(0.0, 1.5)
        : 1.0;

    final totalActiveMins = _profile.todayActiveTimeMinutes * 6 + 30;
    final adherenceRate = totalWorkoutsPlanned > 0
        ? (workoutsCompleted / totalWorkoutsPlanned).clamp(0.0, 1.0)
        : 1.0;

    BodyPhotoEntry? latestPhoto = _profile.bodyPhotos.isNotEmpty ? _profile.bodyPhotos.first : null;

    // AI Coaching Assessment & Grade
    String grade;
    String evaluation;
    List<String> wins = [];
    List<String> recs = [];

    if (stepCompliance >= 0.9 && adherenceRate >= 0.8) {
      grade = 'Grade A+ (Elite Compliance)';
      evaluation = 'Outstanding discipline across step volume and training consistency. BMI is tracking steadily toward your target goal.';
      wins.add('Hit ${((stepCompliance) * 100).toStringAsFixed(0)}% of your weekly step volume target.');
      wins.add('Completed $workoutsCompleted/$totalWorkoutsPlanned prescribed workout splits.');
      recs.add('Maintain progressive overload while keeping hydration above 3.0L.');
    } else if (stepCompliance >= 0.75 || adherenceRate >= 0.6) {
      grade = 'Grade B+ (Solid Execution)';
      evaluation = 'Solid weekly foundation with strong activity. Increasing daily movement on non-training days will accelerate your BMI optimization.';
      wins.add('Accumulated $totalActiveMins total minutes of cardiovascular and strength stimulus.');
      recs.add('Aim for an extra 1,500 steps during evening walks to lock in daily step targets.');
    } else {
      grade = 'Grade B (Re-alignment Opportunity)';
      evaluation = 'Good start, but room for stricter adherence. Re-commit to your daily step baseline and schedule workouts at consistent times.';
      recs.add('Set a reminder for midday movement sessions to guarantee daily active minutes.');
    }

    return WeeklyHealthReport(
      startDate: start,
      endDate: now,
      startWeight: startWeight,
      endWeight: endWeight,
      weightChange: weightChange,
      currentBmi: curBmi,
      bmiCategory: _profile.bmiCategory,
      bmiDelta: bmiDelta,
      totalSteps: estimatedWeekSteps,
      dailyAverageSteps: avgDailySteps,
      stepComplianceRate: stepCompliance,
      totalActiveMinutes: totalActiveMins,
      workoutsCompleted: workoutsCompleted,
      totalWorkoutsPlanned: totalWorkoutsPlanned,
      workoutAdherenceRate: adherenceRate,
      latestPhoto: latestPhoto,
      aiCoachGrade: grade,
      aiEvaluation: evaluation,
      keyWins: wins,
      recommendations: recs,
    );
  }
}
