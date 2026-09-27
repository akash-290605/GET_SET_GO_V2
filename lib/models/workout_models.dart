import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

enum WorkoutStatus {
  planned,
  inProgress,
  completed,
  skipped,
  restDay;

  String get label => WorkoutModels.getStatusLabel(this);
  Color get color => WorkoutModels.getStatusColor(this);
}

class WorkoutModels {
  static String getStatusLabel(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.planned:
        return 'Planned';
      case WorkoutStatus.inProgress:
        return 'In Progress';
      case WorkoutStatus.completed:
        return 'Completed';
      case WorkoutStatus.skipped:
        return 'Skipped';
      case WorkoutStatus.restDay:
        return 'Rest Day';
    }
  }

  static Color getStatusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.planned:
        return AppColors.secondary;
      case WorkoutStatus.inProgress:
        return AppColors.accentAmber;
      case WorkoutStatus.completed:
        return AppColors.accentGreen;
      case WorkoutStatus.skipped:
        return AppColors.accentRose;
      case WorkoutStatus.restDay:
        return AppColors.accentPurple;
    }
  }
}

class ExerciseDetail {
  String id;
  String name;
  String targetMuscle;
  String secondaryMuscles;
  String equipment; // 'Barbell', 'Dumbbells', 'Cables', 'Machine', 'Bodyweight'
  int sets;
  int reps;
  double weightKg;
  int restSeconds;
  String instructions;
  String photoUrl;
  String? previousPerformance;
  String notes;
  List<bool> completedSets;

  ExerciseDetail({
    String? id,
    required this.name,
    required this.targetMuscle,
    String? secondaryMuscles,
    String? equipment,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0.0,
    this.restSeconds = 60,
    String? instructions,
    String? photoUrl,
    this.previousPerformance,
    this.notes = '',
    List<bool>? completedSets,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        secondaryMuscles = secondaryMuscles ?? 'Core & Stabilizers',
        equipment = equipment ?? 'Dumbbells',
        instructions = instructions ?? 'Keep a tight core and focus on controlled contraction.',
        photoUrl = photoUrl ?? '🏋️',
        completedSets = completedSets ?? List.generate(sets, (_) => false);

  ExerciseDetail copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    String? secondaryMuscles,
    String? equipment,
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
    String? instructions,
    String? photoUrl,
    String? previousPerformance,
    String? notes,
    List<bool>? completedSets,
  }) {
    return ExerciseDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      photoUrl: photoUrl ?? this.photoUrl,
      previousPerformance: previousPerformance ?? this.previousPerformance,
      notes: notes ?? this.notes,
      completedSets: completedSets ?? this.completedSets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetMuscle': targetMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'restSeconds': restSeconds,
      'instructions': instructions,
      'photoUrl': photoUrl,
      'previousPerformance': previousPerformance,
      'notes': notes,
      'completedSets': jsonEncode(completedSets),
    };
  }

  factory ExerciseDetail.fromMap(Map<String, dynamic> map) {
    List<bool> cSets = [];
    if (map['completedSets'] != null) {
      if (map['completedSets'] is String) {
        try {
          final decoded = jsonDecode(map['completedSets']) as List;
          cSets = decoded.map((e) => e == true || e == 1).toList();
        } catch (_) {}
      } else if (map['completedSets'] is List) {
        cSets = (map['completedSets'] as List).map((e) => e == true || e == 1).toList();
      }
    }

    final setsCount = (map['sets'] as num?)?.toInt() ?? 3;
    if (cSets.length != setsCount) {
      cSets = List.generate(setsCount, (i) => i < cSets.length ? cSets[i] : false);
    }

    return ExerciseDetail(
      id: map['id']?.toString(),
      name: map['name'] ?? 'Exercise',
      targetMuscle: map['targetMuscle'] ?? 'General',
      secondaryMuscles: map['secondaryMuscles'],
      equipment: map['equipment'],
      sets: setsCount,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
      instructions: map['instructions'],
      photoUrl: map['photoUrl'] ?? map['imageUrl'] ?? '🏋️',
      previousPerformance: map['previousPerformance'],
      notes: map['notes'] ?? '',
      completedSets: cSets,
    );
  }
}

class WorkoutDayPlan {
  String id;
  String dayName; // 'Monday', 'Tuesday', etc.
  String workoutName; // 'Push Power', 'Pull Strength'
  String muscleGroup; // 'Chest, Shoulders & Triceps'
  WorkoutStatus status;
  int estimatedDurationMinutes;
  String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  List<ExerciseDetail> exercises;
  DateTime? completedAt;

  WorkoutDayPlan({
    required this.id,
    required this.dayName,
    required this.workoutName,
    required this.muscleGroup,
    this.status = WorkoutStatus.planned,
    this.estimatedDurationMinutes = 45,
    this.difficulty = 'Intermediate',
    required this.exercises,
    this.completedAt,
  });

  WorkoutDayPlan copyWith({
    String? id,
    String? dayName,
    String? workoutName,
    String? muscleGroup,
    WorkoutStatus? status,
    int? estimatedDurationMinutes,
    String? difficulty,
    List<ExerciseDetail>? exercises,
    DateTime? completedAt,
  }) {
    return WorkoutDayPlan(
      id: id ?? this.id,
      dayName: dayName ?? this.dayName,
      workoutName: workoutName ?? this.workoutName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      status: status ?? this.status,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      difficulty: difficulty ?? this.difficulty,
      exercises: exercises ?? this.exercises,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayName': dayName,
      'workoutName': workoutName,
      'muscleGroup': muscleGroup,
      'status': status.name,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'difficulty': difficulty,
      'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory WorkoutDayPlan.fromMap(Map<String, dynamic> map) {
    List<ExerciseDetail> exList = [];
    if (map['exercises'] != null) {
      if (map['exercises'] is String) {
        try {
          final decoded = jsonDecode(map['exercises']) as List;
          exList = decoded.map((e) => ExerciseDetail.fromMap(e)).toList();
        } catch (_) {}
      } else if (map['exercises'] is List) {
        exList = (map['exercises'] as List).map((e) => ExerciseDetail.fromMap(e)).toList();
      }
    }

    WorkoutStatus st = WorkoutStatus.planned;
    final stStr = map['status'] as String?;
    if (stStr != null) {
      for (var s in WorkoutStatus.values) {
        if (s.name.toLowerCase() == stStr.toLowerCase()) {
          st = s;
          break;
        }
      }
    }

    return WorkoutDayPlan(
      id: map['id']?.toString() ?? 'plan_${DateTime.now().millisecondsSinceEpoch}',
      dayName: map['dayName'] ?? 'Monday',
      workoutName: map['workoutName'] ?? 'Workout',
      muscleGroup: map['muscleGroup'] ?? 'General',
      status: st,
      estimatedDurationMinutes: (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 45,
      difficulty: map['difficulty'] ?? 'Intermediate',
      exercises: exList,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
    );
  }
}
