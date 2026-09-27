// Workout Template Models for backward compatibility and pre-built routine libraries
export 'workout_models.dart';

class WorkoutTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final int estimatedDurationMinutes;
  final String difficulty;

  WorkoutTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedDurationMinutes,
    required this.difficulty,
  });
}
