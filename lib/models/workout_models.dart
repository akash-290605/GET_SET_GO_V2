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

/// A single recorded set during a live workout session
class WorkoutSetRecord {
  final int setNumber;
  int reps;
  double weightKg;
  int durationSeconds;
  bool isCompleted;
  final bool isBodyweight;
  final bool isTimeBased;
  DateTime? completedAt;

  WorkoutSetRecord({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.durationSeconds = 0,
    this.isCompleted = false,
    this.isBodyweight = false,
    this.isTimeBased = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
        'durationSeconds': durationSeconds,
        'isCompleted': isCompleted,
        'isBodyweight': isBodyweight,
        'isTimeBased': isTimeBased,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory WorkoutSetRecord.fromMap(Map<String, dynamic> map) => WorkoutSetRecord(
        setNumber: (map['setNumber'] as num?)?.toInt() ?? 1,
        reps: (map['reps'] as num?)?.toInt() ?? 10,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
        isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
        isBodyweight: map['isBodyweight'] == true || map['isBodyweight'] == 1,
        isTimeBased: map['isTimeBased'] == true || map['isTimeBased'] == 1,
        completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
      );

  WorkoutSetRecord copyWith({
    int? setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    bool? isCompleted,
    bool? isBodyweight,
    bool? isTimeBased,
    DateTime? completedAt,
  }) {
    return WorkoutSetRecord(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      isBodyweight: isBodyweight ?? this.isBodyweight,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Exercise definition inside a Workout Template (Plan)
class ExerciseDetail {
  String id;
  String name;
  String targetMuscle;
  String secondaryMuscles;
  String equipment; // 'Barbell', 'Dumbbells', 'Cables', 'Machine', 'Bodyweight'
  bool isBodyweight;
  bool isTimeBased;
  int targetDurationSeconds;
  int sets;
  int reps;
  double weightKg;
  int restSeconds;
  String instructions;
  String photoUrl;
  String? previousPerformance;
  String notes;
  List<bool> completedSets;
  List<WorkoutSetRecord>? actualSetRecords;

  ExerciseDetail({
    String? id,
    required this.name,
    required this.targetMuscle,
    String? secondaryMuscles,
    String? equipment,
    this.isBodyweight = false,
    this.isTimeBased = false,
    this.targetDurationSeconds = 0,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0.0,
    this.restSeconds = 60,
    String? instructions,
    String? photoUrl,
    this.previousPerformance,
    this.notes = '',
    List<bool>? completedSets,
    List<WorkoutSetRecord>? actualSetRecords,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        secondaryMuscles = secondaryMuscles ?? 'Core & Stabilizers',
        equipment = equipment ?? (isBodyweight ? 'Bodyweight' : 'Dumbbells'),
        instructions = instructions ?? 'Keep a tight core and focus on controlled contraction.',
        photoUrl = photoUrl ?? (isTimeBased ? '🧘' : (isBodyweight ? '🤸' : '🏋️')),
        completedSets = completedSets ?? List.generate(sets, (_) => false),
        actualSetRecords = actualSetRecords ??
            List.generate(
              sets,
              (i) => WorkoutSetRecord(
                setNumber: i + 1,
                reps: reps,
                weightKg: weightKg,
                durationSeconds: targetDurationSeconds,
                isCompleted: (completedSets != null && i < completedSets.length) ? completedSets[i] : false,
                isBodyweight: isBodyweight,
                isTimeBased: isTimeBased,
              ),
            );

  int get targetSets => sets;
  int get completedSetsCount => completedSets.where((s) => s == true).length;
  bool get isCompleted => sets > 0 && completedSetsCount >= sets;

  ExerciseDetail copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    String? secondaryMuscles,
    String? equipment,
    bool? isBodyweight,
    bool? isTimeBased,
    int? targetDurationSeconds,
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
    String? instructions,
    String? photoUrl,
    String? previousPerformance,
    String? notes,
    List<bool>? completedSets,
    List<WorkoutSetRecord>? actualSetRecords,
  }) {
    return ExerciseDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      isBodyweight: isBodyweight ?? this.isBodyweight,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      photoUrl: photoUrl ?? this.photoUrl,
      previousPerformance: previousPerformance ?? this.previousPerformance,
      notes: notes ?? this.notes,
      completedSets: completedSets ?? this.completedSets,
      actualSetRecords: actualSetRecords ?? this.actualSetRecords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetMuscle': targetMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'isBodyweight': isBodyweight,
      'isTimeBased': isTimeBased,
      'targetDurationSeconds': targetDurationSeconds,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'restSeconds': restSeconds,
      'instructions': instructions,
      'photoUrl': photoUrl,
      'previousPerformance': previousPerformance,
      'notes': notes,
      'completedSets': jsonEncode(completedSets),
      'actualSetRecords': actualSetRecords != null ? jsonEncode(actualSetRecords!.map((s) => s.toMap()).toList()) : null,
    };
  }

  factory ExerciseDetail.fromMap(Map<String, dynamic> map) {
    final isBw = map['isBodyweight'] == true || map['isBodyweight'] == 1 || (map['equipment']?.toString().toLowerCase().contains('bodyweight') ?? false);
    final isTb = map['isTimeBased'] == true || map['isTimeBased'] == 1;
    final setsCount = (map['sets'] as num?)?.toInt() ?? 3;

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
    if (cSets.length != setsCount) {
      cSets = List.generate(setsCount, (i) => i < cSets.length ? cSets[i] : false);
    }

    List<WorkoutSetRecord>? actualSets;
    if (map['actualSetRecords'] != null) {
      try {
        final decoded = map['actualSetRecords'] is String ? jsonDecode(map['actualSetRecords']) as List : map['actualSetRecords'] as List;
        actualSets = decoded.map((e) => WorkoutSetRecord.fromMap(e)).toList();
      } catch (_) {}
    }

    return ExerciseDetail(
      id: map['id']?.toString(),
      name: map['name'] ?? 'Exercise',
      targetMuscle: map['targetMuscle'] ?? 'General',
      secondaryMuscles: map['secondaryMuscles'],
      equipment: map['equipment'],
      isBodyweight: isBw,
      isTimeBased: isTb,
      targetDurationSeconds: (map['targetDurationSeconds'] as num?)?.toInt() ?? 0,
      sets: setsCount,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
      instructions: map['instructions'],
      photoUrl: map['photoUrl'] ?? map['imageUrl'] ?? (isTb ? '🧘' : (isBw ? '🤸' : '🏋️')),
      previousPerformance: map['previousPerformance'],
      notes: map['notes'] ?? '',
      completedSets: cSets,
      actualSetRecords: actualSets,
    );
  }
}

/// Day-Based Workout Plan Template (Future planned workouts)
class WorkoutDayPlan {
  String id;
  String dayName; // 'Monday', 'Tuesday', etc.
  String workoutName; // 'Push Power', 'Pull Strength', 'Rest Day'
  String muscleGroup; // 'Chest, Shoulders & Triceps'
  WorkoutStatus status;
  int estimatedDurationMinutes;
  String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  List<ExerciseDetail> exercises;
  bool isRestDay;
  int version;
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
    this.isRestDay = false,
    this.version = 1,
    this.completedAt,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);
  int get completedSetsCount => exercises.fold(0, (sum, e) => sum + e.completedSetsCount);
  int get completedExercisesCount => exercises.where((e) => e.isCompleted).length;
  double get progressPercentage {
    if (status == WorkoutStatus.completed) return 1.0;
    if (totalSets == 0) return 0.0;
    return (completedSetsCount / totalSets).clamp(0.0, 1.0);
  }
  bool get isFullyCompleted => status == WorkoutStatus.completed || (totalSets > 0 && completedSetsCount >= totalSets);

  WorkoutDayPlan copyWith({
    String? id,
    String? dayName,
    String? workoutName,
    String? muscleGroup,
    WorkoutStatus? status,
    int? estimatedDurationMinutes,
    String? difficulty,
    List<ExerciseDetail>? exercises,
    bool? isRestDay,
    int? version,
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
      isRestDay: isRestDay ?? this.isRestDay,
      version: version ?? this.version,
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
      'isRestDay': isRestDay ? 1 : 0,
      'version': version,
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

    final isRest = map['isRestDay'] == 1 || map['isRestDay'] == true || (map['workoutName']?.toString().toLowerCase().contains('rest') ?? false);
    WorkoutStatus st = isRest ? WorkoutStatus.restDay : WorkoutStatus.planned;
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
      isRestDay: isRest,
      version: (map['version'] as num?)?.toInt() ?? 1,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
    );
  }
}

/// Actual Exercise Performance recorded inside an immutable WorkoutSession
class ExerciseSessionRecord {
  final String exerciseId;
  final String exerciseName;
  final String targetMuscle;
  final bool isBodyweight;
  final bool isTimeBased;
  final int plannedSets;
  final int plannedReps;
  final double plannedWeightKg;
  final int plannedDurationSeconds;
  final List<WorkoutSetRecord> actualSets;
  final String notes;
  final String? previousPerformanceSummary;
  final double? weightProgression;
  final int? repProgression;

  ExerciseSessionRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetMuscle,
    this.isBodyweight = false,
    this.isTimeBased = false,
    required this.plannedSets,
    required this.plannedReps,
    required this.plannedWeightKg,
    this.plannedDurationSeconds = 0,
    required this.actualSets,
    this.notes = '',
    this.previousPerformanceSummary,
    this.weightProgression,
    this.repProgression,
  });

  int get completedSetsCount => actualSets.where((s) => s.isCompleted).length;
  bool get isCompleted => plannedSets > 0 && completedSetsCount >= plannedSets;
  double get maxWeightLogged => actualSets.where((s) => s.isCompleted).fold(0.0, (max, s) => s.weightKg > max ? s.weightKg : max);
  int get maxRepsLogged => actualSets.where((s) => s.isCompleted).fold(0, (max, s) => s.reps > max ? s.reps : max);
  int get maxDurationLogged => actualSets.where((s) => s.isCompleted).fold(0, (max, s) => s.durationSeconds > max ? s.durationSeconds : max);

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'targetMuscle': targetMuscle,
        'isBodyweight': isBodyweight,
        'isTimeBased': isTimeBased,
        'plannedSets': plannedSets,
        'plannedReps': plannedReps,
        'plannedWeightKg': plannedWeightKg,
        'plannedDurationSeconds': plannedDurationSeconds,
        'actualSets': jsonEncode(actualSets.map((s) => s.toMap()).toList()),
        'notes': notes,
        'previousPerformanceSummary': previousPerformanceSummary,
        'weightProgression': weightProgression,
        'repProgression': repProgression,
      };

  factory ExerciseSessionRecord.fromMap(Map<String, dynamic> map) {
    List<WorkoutSetRecord> sets = [];
    if (map['actualSets'] != null) {
      try {
        final decoded = map['actualSets'] is String ? jsonDecode(map['actualSets']) as List : map['actualSets'] as List;
        sets = decoded.map((e) => WorkoutSetRecord.fromMap(e)).toList();
      } catch (_) {}
    }

    return ExerciseSessionRecord(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? 'Exercise',
      targetMuscle: map['targetMuscle'] ?? 'General',
      isBodyweight: map['isBodyweight'] == true || map['isBodyweight'] == 1,
      isTimeBased: map['isTimeBased'] == true || map['isTimeBased'] == 1,
      plannedSets: (map['plannedSets'] as num?)?.toInt() ?? 3,
      plannedReps: (map['plannedReps'] as num?)?.toInt() ?? 10,
      plannedWeightKg: (map['plannedWeightKg'] as num?)?.toDouble() ?? 0.0,
      plannedDurationSeconds: (map['plannedDurationSeconds'] as num?)?.toInt() ?? 0,
      actualSets: sets,
      notes: map['notes'] ?? '',
      previousPerformanceSummary: map['previousPerformanceSummary'],
      weightProgression: (map['weightProgression'] as num?)?.toDouble(),
      repProgression: (map['repProgression'] as num?)?.toInt(),
    );
  }
}

/// Immutable historical Workout Session (Past executed workouts)
class WorkoutSession {
  final String id;
  final String userId;
  final String date; // 'yyyy-MM-dd'
  final String dayName; // 'Monday', 'Tuesday', ...
  final String? workoutTemplateId;
  final int workoutVersion;
  final String workoutName;
  final String muscleGroup;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final List<ExerciseSessionRecord> exercises;
  final WorkoutStatus status;
  final String comments;
  final DateTime createdAt;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.dayName,
    this.workoutTemplateId,
    this.workoutVersion = 1,
    required this.workoutName,
    required this.muscleGroup,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.exercises,
    this.status = WorkoutStatus.completed,
    this.comments = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get completedExercisesCount => exercises.where((e) => e.isCompleted).length;
  int get totalExercisesCount => exercises.length;
  int get totalSetsCompleted => exercises.fold(0, (sum, e) => sum + e.completedSetsCount);

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date,
        'dayName': dayName,
        'workoutTemplateId': workoutTemplateId,
        'workoutVersion': workoutVersion,
        'workoutName': workoutName,
        'muscleGroup': muscleGroup,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
        'status': status.name,
        'comments': comments,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    List<ExerciseSessionRecord> exList = [];
    if (map['exercises'] != null) {
      try {
        final decoded = map['exercises'] is String ? jsonDecode(map['exercises']) as List : map['exercises'] as List;
        exList = decoded.map((e) => ExerciseSessionRecord.fromMap(e)).toList();
      } catch (_) {}
    }

    WorkoutStatus st = WorkoutStatus.completed;
    final stStr = map['status'] as String?;
    if (stStr != null) {
      for (var s in WorkoutStatus.values) {
        if (s.name.toLowerCase() == stStr.toLowerCase()) {
          st = s;
          break;
        }
      }
    }

    return WorkoutSession(
      id: map['id'] ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['userId'] ?? 'guest',
      date: map['date'] ?? '',
      dayName: map['dayName'] ?? 'Monday',
      workoutTemplateId: map['workoutTemplateId'],
      workoutVersion: (map['workoutVersion'] as num?)?.toInt() ?? 1,
      workoutName: map['workoutName'] ?? 'Workout',
      muscleGroup: map['muscleGroup'] ?? 'General',
      startTime: map['startTime'] != null ? DateTime.tryParse(map['startTime']) ?? DateTime.now() : DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime']) : null,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      exercises: exList,
      status: st,
      comments: map['comments'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : DateTime.now(),
    );
  }
}

/// Personal Record model computed from actual workout sessions
class PersonalRecord {
  final String exerciseName;
  final double heaviestWeightKg;
  final DateTime? heaviestWeightDate;
  final int maxReps;
  final double maxRepsWeightKg;
  final DateTime? maxRepsDate;
  final int maxDurationSeconds;
  final DateTime? maxDurationDate;

  PersonalRecord({
    required this.exerciseName,
    this.heaviestWeightKg = 0.0,
    this.heaviestWeightDate,
    this.maxReps = 0,
    this.maxRepsWeightKg = 0.0,
    this.maxRepsDate,
    this.maxDurationSeconds = 0,
    this.maxDurationDate,
  });

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        'heaviestWeightKg': heaviestWeightKg,
        'heaviestWeightDate': heaviestWeightDate?.toIso8601String(),
        'maxReps': maxReps,
        'maxRepsWeightKg': maxRepsWeightKg,
        'maxRepsDate': maxRepsDate?.toIso8601String(),
        'maxDurationSeconds': maxDurationSeconds,
        'maxDurationDate': maxDurationDate?.toIso8601String(),
      };

  factory PersonalRecord.fromMap(Map<String, dynamic> map) => PersonalRecord(
        exerciseName: map['exerciseName'] ?? '',
        heaviestWeightKg: (map['heaviestWeightKg'] as num?)?.toDouble() ?? 0.0,
        heaviestWeightDate: map['heaviestWeightDate'] != null ? DateTime.tryParse(map['heaviestWeightDate']) : null,
        maxReps: (map['maxReps'] as num?)?.toInt() ?? 0,
        maxRepsWeightKg: (map['maxRepsWeightKg'] as num?)?.toDouble() ?? 0.0,
        maxRepsDate: map['maxRepsDate'] != null ? DateTime.tryParse(map['maxRepsDate']) : null,
        maxDurationSeconds: (map['maxDurationSeconds'] as num?)?.toInt() ?? 0,
        maxDurationDate: map['maxDurationDate'] != null ? DateTime.tryParse(map['maxDurationDate']) : null,
      );
}

/// Smart Progression Suggestion for Next Session
class ProgressionSuggestion {
  final String exerciseName;
  final int currentReps;
  final double currentWeightKg;
  final int currentDurationSeconds;
  final bool isBodyweight;
  final bool isTimeBased;
  final int suggestedReps;
  final double suggestedWeightKg;
  final int suggestedDurationSeconds;
  final String progressionType; // 'weight', 'reps', 'duration', 'maintain'
  final String reason;

  ProgressionSuggestion({
    required this.exerciseName,
    required this.currentReps,
    required this.currentWeightKg,
    this.currentDurationSeconds = 0,
    this.isBodyweight = false,
    this.isTimeBased = false,
    required this.suggestedReps,
    required this.suggestedWeightKg,
    this.suggestedDurationSeconds = 0,
    required this.progressionType,
    required this.reason,
  });

  String get targetDisplay {
    if (isTimeBased) {
      return '$suggestedDurationSeconds seconds';
    } else if (isBodyweight) {
      return '$suggestedReps reps (Bodyweight)';
    } else {
      return '$suggestedReps reps @ ${suggestedWeightKg.toStringAsFixed(suggestedWeightKg % 1 == 0 ? 0 : 1)} kg';
    }
  }
}

