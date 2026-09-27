import 'dart:convert';

enum WorkoutStatus {
  planned,
  inProgress,
  completed,
  skipped,
  restDay,
}

enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced,
}

class ExerciseItem {
  final String id;
  final String name;
  final String muscleGroup;
  final String secondaryMuscle;
  final String equipment;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;
  final String instructions;
  final String photoUrl; // URL or local asset/path
  final bool isCompleted;
  final String notes;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.secondaryMuscle = '',
    this.equipment = 'Bodyweight / Dumbbell',
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0.0,
    this.restSeconds = 60,
    this.instructions = 'Maintain proper posture and steady tempo.',
    this.photoUrl = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
    this.isCompleted = false,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'muscleGroup': muscleGroup,
    'secondaryMuscle': secondaryMuscle,
    'equipment': equipment,
    'sets': sets,
    'reps': reps,
    'weightKg': weightKg,
    'restSeconds': restSeconds,
    'instructions': instructions,
    'photoUrl': photoUrl,
    'isCompleted': isCompleted ? 1 : 0,
    'notes': notes,
  };

  factory ExerciseItem.fromMap(Map<String, dynamic> map) => ExerciseItem(
    id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name']?.toString() ?? 'Exercise',
    muscleGroup: map['muscleGroup']?.toString() ?? 'Full Body',
    secondaryMuscle: map['secondaryMuscle']?.toString() ?? '',
    equipment: map['equipment']?.toString() ?? 'Bodyweight',
    sets: (map['sets'] as num?)?.toInt() ?? 3,
    reps: (map['reps'] as num?)?.toInt() ?? 10,
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
    restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
    instructions: map['instructions']?.toString() ?? '',
    photoUrl: map['photoUrl']?.toString() ?? 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
    isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
    notes: map['notes']?.toString() ?? '',
  );

  String toJson() => json.encode(toMap());

  factory ExerciseItem.fromJson(String source) => ExerciseItem.fromMap(json.decode(source));

  ExerciseItem copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    String? secondaryMuscle,
    String? equipment,
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
    String? instructions,
    String? photoUrl,
    bool? isCompleted,
    String? notes,
  }) {
    return ExerciseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      secondaryMuscle: secondaryMuscle ?? this.secondaryMuscle,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      photoUrl: photoUrl ?? this.photoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}

class DayWorkoutPlan {
  final String id;
  final String dayName; // 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  final String workoutTitle;
  final String primaryMuscle;
  final int durationMinutes;
  final WorkoutDifficulty difficulty;
  final WorkoutStatus status;
  final List<ExerciseItem> exercises;
  final String notes;

  DayWorkoutPlan({
    required this.id,
    required this.dayName,
    required this.workoutTitle,
    required this.primaryMuscle,
    this.durationMinutes = 45,
    this.difficulty = WorkoutDifficulty.intermediate,
    this.status = WorkoutStatus.planned,
    required this.exercises,
    this.notes = '',
  });

  int get totalExercises => exercises.length;
  int get completedExercises => exercises.where((e) => e.isCompleted).length;
  double get completionProgress => totalExercises > 0 ? (completedExercises / totalExercises) : 0.0;
  bool get isRestDay => status == WorkoutStatus.restDay;

  Map<String, dynamic> toMap() => {
    'id': id,
    'dayName': dayName,
    'workoutTitle': workoutTitle,
    'primaryMuscle': primaryMuscle,
    'durationMinutes': durationMinutes,
    'difficulty': difficulty.name,
    'status': status.name,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'notes': notes,
  };

  factory DayWorkoutPlan.fromMap(Map<String, dynamic> map) {
    var rawList = map['exercises'];
    List<ExerciseItem> exList = [];
    if (rawList is List) {
      exList = rawList.map((e) => ExerciseItem.fromMap(Map<String, dynamic>.from(e))).toList();
    } else if (rawList is String) {
      try {
        var decoded = json.decode(rawList);
        if (decoded is List) {
          exList = decoded.map((e) => ExerciseItem.fromMap(Map<String, dynamic>.from(e))).toList();
        }
      } catch (_) {}
    }

    return DayWorkoutPlan(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      dayName: map['dayName']?.toString() ?? 'Monday',
      workoutTitle: map['workoutTitle']?.toString() ?? 'Daily Workout',
      primaryMuscle: map['primaryMuscle']?.toString() ?? 'Full Body',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      difficulty: WorkoutDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => WorkoutDifficulty.intermediate,
      ),
      status: WorkoutStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => WorkoutStatus.planned,
      ),
      exercises: exList,
      notes: map['notes']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DayWorkoutPlan.fromJson(String source) => DayWorkoutPlan.fromMap(json.decode(source));

  DayWorkoutPlan copyWith({
    String? id,
    String? dayName,
    String? workoutTitle,
    String? primaryMuscle,
    int? durationMinutes,
    WorkoutDifficulty? difficulty,
    WorkoutStatus? status,
    List<ExerciseItem>? exercises,
    String? notes,
  }) {
    return DayWorkoutPlan(
      id: id ?? this.id,
      dayName: dayName ?? this.dayName,
      workoutTitle: workoutTitle ?? this.workoutTitle,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}
