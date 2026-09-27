class WorkoutHistoryLog {
  final int? id;
  final String date;
  final String dayName;
  final String workoutName;
  final int completedExercisesCount;
  final int totalExercisesCount;
  final int durationMinutes;
  final String? notes;
  final String completedAt;

  const WorkoutHistoryLog({
    this.id,
    required this.date,
    required this.dayName,
    required this.workoutName,
    required this.completedExercisesCount,
    required this.totalExercisesCount,
    this.durationMinutes = 0,
    this.notes,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'dayName': dayName,
      'workoutName': workoutName,
      'completedExercisesCount': completedExercisesCount,
      'totalExercisesCount': totalExercisesCount,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'completedAt': completedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory WorkoutHistoryLog.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryLog(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      dayName: map['dayName'] as String? ?? '',
      workoutName: map['workoutName'] as String? ?? '',
      completedExercisesCount: (map['completedExercisesCount'] as num?)?.toInt() ?? 0,
      totalExercisesCount: (map['totalExercisesCount'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      completedAt: map['completedAt'] as String? ?? '',
    );
  }

  WorkoutHistoryLog copyWith({
    int? id,
    String? date,
    String? dayName,
    String? workoutName,
    int? completedExercisesCount,
    int? totalExercisesCount,
    int? durationMinutes,
    String? notes,
    String? completedAt,
  }) {
    return WorkoutHistoryLog(
      id: id ?? this.id,
      date: date ?? this.date,
      dayName: dayName ?? this.dayName,
      workoutName: workoutName ?? this.workoutName,
      completedExercisesCount: completedExercisesCount ?? this.completedExercisesCount,
      totalExercisesCount: totalExercisesCount ?? this.totalExercisesCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
