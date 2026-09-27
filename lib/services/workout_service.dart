import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_models.dart';

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  static WorkoutService get instance => _instance;
  WorkoutService._internal();

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, DayWorkoutPlan> _plans = {};
  int _currentStreakDays = 5;
  int _totalWorkoutsCompleted = 28;

  Map<String, DayWorkoutPlan> get plans => _plans;
  int get currentStreakDays => _currentStreakDays;
  int get totalWorkoutsCompleted => _totalWorkoutsCompleted;

  String get currentDayName {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[now.weekday - 1];
  }

  DayWorkoutPlan? get todayPlan => _plans[currentDayName];

  double get weeklyCompletionRate {
    if (_plans.isEmpty) return 0.0;
    int completedDays = _plans.values.where((p) => p.status == WorkoutStatus.completed || p.status == WorkoutStatus.restDay).length;
    return (completedDays / 7.0).clamp(0.0, 1.0);
  }

  Map<String, int> get muscleDistribution {
    final dist = <String, int>{};
    for (var plan in _plans.values) {
      if (!plan.isRestDay) {
        dist[plan.primaryMuscle] = (dist[plan.primaryMuscle] ?? 0) + 1;
      }
    }
    return dist;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('workout_7day_plans');
      if (savedJson != null) {
        final Map<String, dynamic> decoded = json.decode(savedJson);
        _plans = decoded.map((key, val) => MapEntry(key, DayWorkoutPlan.fromMap(Map<String, dynamic>.from(val))));
      } else {
        _plans = _getDefault7DayPlan();
        await _savePlans();
      }

      _currentStreakDays = prefs.getInt('workout_streak_days') ?? 5;
      _totalWorkoutsCompleted = prefs.getInt('workout_total_completed') ?? 28;
    } catch (e) {
      debugPrint('WorkoutService init error: $e');
      _plans = _getDefault7DayPlan();
    }
    notifyListeners();
  }

  Future<void> updatePlan(DayWorkoutPlan plan) async {
    _plans[plan.dayName] = plan;
    notifyListeners();
    await _savePlans();
  }

  Future<void> setDayStatus(String dayName, WorkoutStatus status) async {
    final existing = _plans[dayName];
    if (existing == null) return;
    
    _plans[dayName] = existing.copyWith(status: status);
    if (status == WorkoutStatus.completed) {
      _totalWorkoutsCompleted++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('workout_total_completed', _totalWorkoutsCompleted);
    }
    notifyListeners();
    await _savePlans();
  }

  Future<void> toggleExerciseCompletion(String dayName, String exerciseId) async {
    final plan = _plans[dayName];
    if (plan == null) return;

    final updatedExercises = plan.exercises.map((ex) {
      if (ex.id == exerciseId) {
        return ex.copyWith(isCompleted: !ex.isCompleted);
      }
      return ex;
    }).toList();

    bool allDone = updatedExercises.isNotEmpty && updatedExercises.every((e) => e.isCompleted);
    final newStatus = allDone ? WorkoutStatus.completed : WorkoutStatus.inProgress;

    _plans[dayName] = plan.copyWith(
      exercises: updatedExercises,
      status: newStatus,
    );
    notifyListeners();
    await _savePlans();
  }

  Future<void> addExerciseToDay(String dayName, ExerciseItem exercise) async {
    final plan = _plans[dayName];
    if (plan == null) return;

    final updated = List<ExerciseItem>.from(plan.exercises)..add(exercise);
    _plans[dayName] = plan.copyWith(exercises: updated);
    notifyListeners();
    await _savePlans();
  }

  Future<void> updateExercise(String dayName, ExerciseItem updatedExercise) async {
    final plan = _plans[dayName];
    if (plan == null) return;

    final updatedList = plan.exercises.map((e) => e.id == updatedExercise.id ? updatedExercise : e).toList();
    _plans[dayName] = plan.copyWith(exercises: updatedList);
    notifyListeners();
    await _savePlans();
  }

  Future<void> deleteExercise(String dayName, String exerciseId) async {
    final plan = _plans[dayName];
    if (plan == null) return;

    final updated = plan.exercises.where((e) => e.id != exerciseId).toList();
    _plans[dayName] = plan.copyWith(exercises: updated);
    notifyListeners();
    await _savePlans();
  }

  Future<void> reorderExercises(String dayName, int oldIndex, int newIndex) async {
    final plan = _plans[dayName];
    if (plan == null) return;

    final list = List<ExerciseItem>.from(plan.exercises);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    _plans[dayName] = plan.copyWith(exercises: list);
    notifyListeners();
    await _savePlans();
  }

  Future<void> duplicateDayPlan(String fromDay, String toDay) async {
    final source = _plans[fromDay];
    if (source == null) return;

    final duplicated = DayWorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dayName: toDay,
      workoutTitle: source.workoutTitle,
      primaryMuscle: source.primaryMuscle,
      durationMinutes: source.durationMinutes,
      difficulty: source.difficulty,
      status: WorkoutStatus.planned,
      exercises: source.exercises.map((e) => e.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${e.id}',
        isCompleted: false,
      )).toList(),
      notes: source.notes,
    );

    _plans[toDay] = duplicated;
    notifyListeners();
    await _savePlans();
  }

  Future<void> resetAllToDefaults() async {
    _plans = _getDefault7DayPlan();
    notifyListeners();
    await _savePlans();
  }

  Future<void> _savePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = _plans.map((k, v) => MapEntry(k, v.toMap()));
      await prefs.setString('workout_7day_plans', json.encode(mapData));
    } catch (e) {
      debugPrint('Error saving workout plans: $e');
    }
  }

  // Pre-configured rich 7-day science-backed split
  Map<String, DayWorkoutPlan> _getDefault7DayPlan() {
    return {
      'Monday': DayWorkoutPlan(
        id: 'w_mon',
        dayName: 'Monday',
        workoutTitle: 'Chest & Triceps Hypertrophy',
        primaryMuscle: 'Chest & Triceps',
        durationMinutes: 50,
        difficulty: WorkoutDifficulty.intermediate,
        status: WorkoutStatus.completed,
        exercises: [
          ExerciseItem(
            id: 'ex_1',
            name: 'Incline Dumbbell Bench Press',
            muscleGroup: 'Upper Chest',
            secondaryMuscle: 'Front Delts, Triceps',
            equipment: 'Dumbbells & Bench',
            sets: 4,
            reps: 10,
            weightKg: 24.0,
            restSeconds: 90,
            instructions: 'Lower dumbbells smoothly to upper chest line, drive upward with controlled contraction.',
            photoUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
            isCompleted: true,
          ),
          ExerciseItem(
            id: 'ex_2',
            name: 'Flat Barbell Bench Press',
            muscleGroup: 'Mid Chest',
            secondaryMuscle: 'Triceps',
            equipment: 'Barbell & Bench',
            sets: 3,
            reps: 8,
            weightKg: 65.0,
            restSeconds: 120,
            instructions: 'Retract scapulae, touch lower sternum, flare elbows at 45-degree angle.',
            photoUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
            isCompleted: true,
          ),
          ExerciseItem(
            id: 'ex_3',
            name: 'Triceps Cable Rope Pushdown',
            muscleGroup: 'Triceps (Lateral Head)',
            secondaryMuscle: 'Forearms',
            equipment: 'Cable Machine',
            sets: 3,
            reps: 12,
            weightKg: 22.5,
            restSeconds: 60,
            instructions: 'Pin elbows to ribs, spread rope outward at the bottom for peak lock.',
            photoUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
            isCompleted: true,
          ),
        ],
      ),
      'Tuesday': DayWorkoutPlan(
        id: 'w_tue',
        dayName: 'Tuesday',
        workoutTitle: 'Back & Biceps Power Pull',
        primaryMuscle: 'Back & Biceps',
        durationMinutes: 55,
        difficulty: WorkoutDifficulty.advanced,
        status: WorkoutStatus.inProgress,
        exercises: [
          ExerciseItem(
            id: 'ex_4',
            name: 'Barbell Bent-Over Row',
            muscleGroup: 'Lats & Rhomboids',
            secondaryMuscle: 'Posterior Delts, Biceps',
            equipment: 'Barbell',
            sets: 4,
            reps: 8,
            weightKg: 55.0,
            restSeconds: 90,
            instructions: 'Hinge at 45 degrees, pull bar towards belly button, squeeze shoulder blades.',
            photoUrl: 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=600',
            isCompleted: true,
          ),
          ExerciseItem(
            id: 'ex_5',
            name: 'Wide-Grip Lat Pulldown',
            muscleGroup: 'Latissimus Dorsi',
            secondaryMuscle: 'Biceps',
            equipment: 'Cable Pulldown Machine',
            sets: 3,
            reps: 12,
            weightKg: 45.0,
            restSeconds: 75,
            instructions: 'Pull elbows downward towards pockets, lean back slightly at 10 degrees.',
            photoUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
            isCompleted: false,
          ),
          ExerciseItem(
            id: 'ex_6',
            name: 'Incline Dumbbell Biceps Curls',
            muscleGroup: 'Biceps (Long Head)',
            secondaryMuscle: 'Brachialis',
            equipment: 'Dumbbells',
            sets: 3,
            reps: 12,
            weightKg: 12.0,
            restSeconds: 60,
            instructions: 'Full stretch at bottom, supinate wrists actively on the concentric ascent.',
            photoUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
            isCompleted: false,
          ),
        ],
      ),
      'Wednesday': DayWorkoutPlan(
        id: 'w_wed',
        dayName: 'Wednesday',
        workoutTitle: 'Legs & Calves Hypertrophy',
        primaryMuscle: 'Quadriceps & Hamstrings',
        durationMinutes: 60,
        difficulty: WorkoutDifficulty.advanced,
        status: WorkoutStatus.planned,
        exercises: [
          ExerciseItem(
            id: 'ex_7',
            name: 'Barbell Back Squats',
            muscleGroup: 'Quads & Glutes',
            secondaryMuscle: 'Hamstrings, Core',
            equipment: 'Barbell & Squat Rack',
            sets: 4,
            reps: 8,
            weightKg: 75.0,
            restSeconds: 120,
            instructions: 'Brace core, squat below parallel with knees tracking over second toe.',
            photoUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600',
            isCompleted: false,
          ),
          ExerciseItem(
            id: 'ex_8',
            name: 'Romanian Deadlifts (RDL)',
            muscleGroup: 'Hamstrings & Glutes',
            secondaryMuscle: 'Erectors',
            equipment: 'Barbell / Dumbbells',
            sets: 3,
            reps: 10,
            weightKg: 60.0,
            restSeconds: 90,
            instructions: 'Push hips backward until deep hamstring stretch, keep spine neutral.',
            photoUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
            isCompleted: false,
          ),
        ],
      ),
      'Thursday': DayWorkoutPlan(
        id: 'w_thu',
        dayName: 'Thursday',
        workoutTitle: 'Active Recovery & Mobility',
        primaryMuscle: 'Core & Mobility',
        durationMinutes: 30,
        difficulty: WorkoutDifficulty.beginner,
        status: WorkoutStatus.restDay,
        exercises: [],
        notes: 'Dedicated active rest day for central nervous system recuperation.',
      ),
      'Friday': DayWorkoutPlan(
        id: 'w_fri',
        dayName: 'Friday',
        workoutTitle: 'Shoulders & Core Sculpt',
        primaryMuscle: 'Shoulders & Abs',
        durationMinutes: 45,
        difficulty: WorkoutDifficulty.intermediate,
        status: WorkoutStatus.planned,
        exercises: [
          ExerciseItem(
            id: 'ex_9',
            name: 'Dumbbell Overhead Shoulder Press',
            muscleGroup: 'Anterior & Lateral Delts',
            secondaryMuscle: 'Triceps',
            equipment: 'Dumbbells',
            sets: 4,
            reps: 10,
            weightKg: 18.0,
            restSeconds: 90,
            instructions: 'Press upwards in slight arc, avoid arching lower lumbar spine.',
            photoUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
            isCompleted: false,
          ),
          ExerciseItem(
            id: 'ex_10',
            name: 'Side Lateral Raises',
            muscleGroup: 'Lateral Deltoids',
            secondaryMuscle: 'Traps',
            equipment: 'Dumbbells',
            sets: 4,
            reps: 15,
            weightKg: 8.0,
            restSeconds: 60,
            instructions: 'Lead with elbows, slight forward torso angle to isolate side delt.',
            photoUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
            isCompleted: false,
          ),
        ],
      ),
      'Saturday': DayWorkoutPlan(
        id: 'w_sat',
        dayName: 'Saturday',
        workoutTitle: 'Arms & High-Intensity Conditioning',
        primaryMuscle: 'Full Upper Body',
        durationMinutes: 45,
        difficulty: WorkoutDifficulty.intermediate,
        status: WorkoutStatus.planned,
        exercises: [
          ExerciseItem(
            id: 'ex_11',
            name: 'EZ-Bar Skull Crushers',
            muscleGroup: 'Triceps',
            secondaryMuscle: 'Forearms',
            equipment: 'EZ Curl Bar',
            sets: 3,
            reps: 12,
            weightKg: 20.0,
            restSeconds: 75,
            instructions: 'Keep upper arms fixed at slight backward angle to maintain tension.',
            photoUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
            isCompleted: false,
          ),
        ],
      ),
      'Sunday': DayWorkoutPlan(
        id: 'w_sun',
        dayName: 'Sunday',
        workoutTitle: 'Total Rest & Weekly Refuel',
        primaryMuscle: 'Rest & Recovery',
        durationMinutes: 0,
        difficulty: WorkoutDifficulty.beginner,
        status: WorkoutStatus.restDay,
        exercises: [],
        notes: 'Full rest day. Meal prep, hydrate, and prepare for the upcoming week.',
      ),
    };
  }
}
