class WorkoutSplitDay {
  final String dayName;
  final String targetMuscle;
  final String description;
  final List<WorkoutExerciseTemplate> exercises;

  const WorkoutSplitDay({
    required this.dayName,
    required this.targetMuscle,
    required this.description,
    required this.exercises,
  });
}

class WorkoutExerciseTemplate {
  final String name;
  final String muscleGroup;
  final int defaultSets;
  final int defaultReps;
  final String tips;

  const WorkoutExerciseTemplate({
    required this.name,
    required this.muscleGroup,
    this.defaultSets = 4,
    this.defaultReps = 12,
    this.tips = 'Maintain strict form and controlled eccentric cadence.',
  });
}

class WorkoutPresetSplits {
  static const List<WorkoutSplitDay> weeklyHypertrophySplit = [
    WorkoutSplitDay(
      dayName: 'Monday',
      targetMuscle: 'Chest & Triceps (Push Heavy)',
      description: 'Upper body anterior hypertrophy and pressing power',
      exercises: [
        WorkoutExerciseTemplate(name: 'Barbell Flat Bench Press', muscleGroup: 'Chest', defaultSets: 4, defaultReps: 8),
        WorkoutExerciseTemplate(name: 'Incline Dumbbell Press', muscleGroup: 'Upper Chest', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Cable Flyes / Pec Deck', muscleGroup: 'Inner Chest', defaultSets: 3, defaultReps: 15),
        WorkoutExerciseTemplate(name: 'Tricep Rope Pushdowns', muscleGroup: 'Triceps', defaultSets: 4, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Overhead French Press', muscleGroup: 'Triceps Long Head', defaultSets: 3, defaultReps: 12),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Tuesday',
      targetMuscle: 'Back & Biceps (Pull Heavy)',
      description: 'Posterior chain density, lats width and pulling endurance',
      exercises: [
        WorkoutExerciseTemplate(name: 'Lat Pulldowns (Wide Grip)', muscleGroup: 'Lats', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Barbell Bent-Over Rows', muscleGroup: 'Upper Back', defaultSets: 4, defaultReps: 8),
        WorkoutExerciseTemplate(name: 'Seated Cable Rows', muscleGroup: 'Mid Back', defaultSets: 3, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Standing Barbell Curls', muscleGroup: 'Biceps', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Incline Dumbbell Hammer Curls', muscleGroup: 'Brachialis', defaultSets: 3, defaultReps: 12),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Wednesday',
      targetMuscle: 'Shoulders & Core (Boulder Shoulders)',
      description: 'Deltoid 3D capping and rotational core stability',
      exercises: [
        WorkoutExerciseTemplate(name: 'Seated Dumbbell Overhead Press', muscleGroup: 'Front Delts', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Dumbbell Lateral Raises (Strict)', muscleGroup: 'Side Delts', defaultSets: 5, defaultReps: 15),
        WorkoutExerciseTemplate(name: 'Face Pulls with External Rotation', muscleGroup: 'Rear Delts', defaultSets: 4, defaultReps: 15),
        WorkoutExerciseTemplate(name: 'Hanging Knee/Leg Raises', muscleGroup: 'Lower Abs', defaultSets: 4, defaultReps: 15),
        WorkoutExerciseTemplate(name: 'Cable Woodchoppers', muscleGroup: 'Obliques', defaultSets: 3, defaultReps: 12),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Thursday',
      targetMuscle: 'Legs & Calves (Quad Focus)',
      description: 'Anterior lower body strength and explosive power',
      exercises: [
        WorkoutExerciseTemplate(name: 'Barbell Back Squats', muscleGroup: 'Quads / Glutes', defaultSets: 4, defaultReps: 8),
        WorkoutExerciseTemplate(name: 'Leg Press (Moderate Stance)', muscleGroup: 'Quads', defaultSets: 4, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Leg Extensions (Peak Contraction)', muscleGroup: 'Quads', defaultSets: 3, defaultReps: 15),
        WorkoutExerciseTemplate(name: 'Standing Calf Raises', muscleGroup: 'Calves', defaultSets: 5, defaultReps: 20),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Friday',
      targetMuscle: 'Arms & Upper Hypertrophy Blast',
      description: 'Super-set isolation for maximum upper arm and forearm pump',
      exercises: [
        WorkoutExerciseTemplate(name: 'EZ-Bar Preacher Curls', muscleGroup: 'Biceps', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Skullcrushers (Lying Tricep Ext)', muscleGroup: 'Triceps', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Cable Concentration Curls', muscleGroup: 'Biceps Peak', defaultSets: 3, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Dips / Weighted Dips', muscleGroup: 'Triceps / Chest', defaultSets: 3, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Wrist Roller / Reverse Curls', muscleGroup: 'Forearms', defaultSets: 4, defaultReps: 15),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Saturday',
      targetMuscle: 'Hamstrings, Glutes & HIIT Cardio',
      description: 'Posterior lower body development and aerobic conditioning',
      exercises: [
        WorkoutExerciseTemplate(name: 'Romanian Deadlifts (RDL)', muscleGroup: 'Hamstrings', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Lying Leg Curls', muscleGroup: 'Hamstrings', defaultSets: 4, defaultReps: 12),
        WorkoutExerciseTemplate(name: 'Barbell Hip Thrusts', muscleGroup: 'Glutes', defaultSets: 4, defaultReps: 10),
        WorkoutExerciseTemplate(name: 'Treadmill Incline Sprints / HIIT', muscleGroup: 'Cardio Engine', defaultSets: 5, defaultReps: 1),
      ],
    ),
    WorkoutSplitDay(
      dayName: 'Sunday',
      targetMuscle: 'Active Recovery & Mobility',
      description: 'Systemic joint restoration, foam rolling and stretching',
      exercises: [
        WorkoutExerciseTemplate(name: 'Full Body Dynamic Mobility Flow', muscleGroup: 'Mobility', defaultSets: 1, defaultReps: 1),
        WorkoutExerciseTemplate(name: 'Deep Foam Rolling (Posterior/Anterior)', muscleGroup: 'Fascia', defaultSets: 1, defaultReps: 1),
        WorkoutExerciseTemplate(name: '30-Minute Low Heart Rate Nature Walk', muscleGroup: 'Active Recovery', defaultSets: 1, defaultReps: 1),
      ],
    ),
  ];
}
