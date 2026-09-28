import 'workout_models.dart';
export 'workout_models.dart';

class ExerciseLibraryCategory {
  final String categoryName;
  final String icon;
  final List<ExerciseDetail> exercises;

  ExerciseLibraryCategory({
    required this.categoryName,
    required this.icon,
    required this.exercises,
  });
}

class WorkoutTemplateModels {
  static List<WorkoutDayPlan> getDefault7DayPlan() {
    return WorkoutPresetSplits.getDefaultWeeklyPlan();
  }

  static String getIllustrationForExercise(String name) {
    final clean = name.toLowerCase();
    if (clean.contains('bench') || clean.contains('chest') || clean.contains('push')) return '🏋️';
    if (clean.contains('squat') || clean.contains('leg') || clean.contains('calf') || clean.contains('lunge')) return '🦵';
    if (clean.contains('pull') || clean.contains('row') || clean.contains('lat') || clean.contains('deadlift')) return '🧗';
    if (clean.contains('shoulder') || clean.contains('press') || clean.contains('delt') || clean.contains('raise')) return '💪';
    if (clean.contains('bicep') || clean.contains('curl')) return '💪';
    if (clean.contains('tricep') || clean.contains('dip') || clean.contains('pushdown')) return '⚡';
    if (clean.contains('core') || clean.contains('ab') || clean.contains('plank') || clean.contains('crunch')) return '🧘';
    if (clean.contains('run') || clean.contains('cardio') || clean.contains('hiit') || clean.contains('jump')) return '🏃';
    return '🏋️';
  }

  /// Categorized Exercise Library for Workout Builder
  static List<ExerciseLibraryCategory> getExerciseLibrary() {
    return [
      ExerciseLibraryCategory(
        categoryName: 'Chest',
        icon: '🏋️',
        exercises: [
          ExerciseDetail(name: 'Barbell Flat Bench Press', targetMuscle: 'Mid Chest', secondaryMuscles: 'Triceps, Front Delts', equipment: 'Barbell & Bench', sets: 3, reps: 10, weightKg: 20.0, restSeconds: 90, instructions: 'Retract scapula, lower bar with control to mid-chest, press up explosively.'),
          ExerciseDetail(name: 'Incline Dumbbell Press', targetMuscle: 'Upper Chest', secondaryMuscles: 'Front Delts, Triceps', equipment: 'Dumbbells & 30° Bench', sets: 3, reps: 10, weightKg: 12.0, restSeconds: 75, instructions: 'Press dumbbells up in a slight arc, squeezing upper chest at peak contraction.'),
          ExerciseDetail(name: 'Push-ups', targetMuscle: 'Chest & Core', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Bodyweight', isBodyweight: true, sets: 3, reps: 15, weightKg: 0.0, restSeconds: 60, instructions: 'Keep rigid plank posture and descend until chest nearly touches floor.'),
          ExerciseDetail(name: 'Dumbbell Chest Flyes', targetMuscle: 'Inner Chest', secondaryMuscles: 'Front Deltoids', equipment: 'Dumbbells & Flat Bench', sets: 3, reps: 12, weightKg: 10.0, restSeconds: 60, instructions: 'Maintain slight elbow bend and hug an imaginary wide barrel on the way up.'),
          ExerciseDetail(name: 'Dips (Chest Focus)', targetMuscle: 'Lower Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Parallel Bars', isBodyweight: true, sets: 3, reps: 10, weightKg: 0.0, restSeconds: 75, instructions: 'Lean torso forward 30 degrees to shift maximum tension to pectorals.'),
          ExerciseDetail(name: 'Cable Pec Crossover', targetMuscle: 'Pectoral Squeeze', secondaryMuscles: 'Serratus Anterior', equipment: 'Dual Cable Pulley', sets: 3, reps: 15, weightKg: 12.5, restSeconds: 60, instructions: 'Bring cable attachments together with constant peak tension.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Back',
        icon: '🧗',
        exercises: [
          ExerciseDetail(name: 'Pull-ups', targetMuscle: 'Latissimus Dorsi', secondaryMuscles: 'Biceps, Upper Back', equipment: 'Bodyweight / Pull-up Bar', isBodyweight: true, sets: 3, reps: 8, weightKg: 0.0, restSeconds: 90, instructions: 'Overhand grip, pull elbows down towards hips until chin clears bar.'),
          ExerciseDetail(name: 'Lat Pulldown', targetMuscle: 'Upper Lats & V-Taper', secondaryMuscles: 'Biceps, Rear Delts', equipment: 'Lat Pulldown Cable', sets: 3, reps: 10, weightKg: 45.0, restSeconds: 75, instructions: 'Slight backward torso angle, drive elbows down into back pockets.'),
          ExerciseDetail(name: 'Barbell Bent-Over Row', targetMuscle: 'Mid-Back & Rhomboids', secondaryMuscles: 'Lats, Biceps, Erector Spinae', equipment: 'Olympic Barbell', sets: 3, reps: 10, weightKg: 40.0, restSeconds: 75, instructions: 'Hinge hips back at 45 degrees, pull barbell to lower ribcage.'),
          ExerciseDetail(name: 'Seated Cable Row', targetMuscle: 'Back Thickness', secondaryMuscles: 'Lower Lats, Forearms', equipment: 'Cable Row Machine', sets: 3, reps: 12, weightKg: 40.0, restSeconds: 60, instructions: 'Sit tall, pull V-handle to abdomen while retracting scapulae.'),
          ExerciseDetail(name: 'Conventional Deadlift', targetMuscle: 'Posterior Chain', secondaryMuscles: 'Glutes, Hamstrings, Traps', equipment: 'Olympic Barbell & Plates', sets: 3, reps: 6, weightKg: 80.0, restSeconds: 120, instructions: 'Hinge at hips with braced neutral spine, stand tall through heels.'),
          ExerciseDetail(name: 'Single-Arm Dumbbell Row', targetMuscle: 'Lats & Obliques', secondaryMuscles: 'Biceps', equipment: 'Single Dumbbell & Bench', sets: 3, reps: 10, weightKg: 16.0, restSeconds: 60, instructions: 'Pull dumbbell towards hip pocket with flat supportive posture.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Legs',
        icon: '🦵',
        exercises: [
          ExerciseDetail(name: 'Barbell Back Squats', targetMuscle: 'Quadriceps & Glutes', secondaryMuscles: 'Hamstrings, Core', equipment: 'Squat Rack & Barbell', sets: 3, reps: 10, weightKg: 50.0, restSeconds: 90, instructions: 'Descend under control below parallel, drive explosively through midfoot.'),
          ExerciseDetail(name: 'Bodyweight Squats', targetMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Calves', equipment: 'Bodyweight', isBodyweight: true, sets: 3, reps: 20, weightKg: 0.0, restSeconds: 45, instructions: 'Full range of motion squats focusing on tempo and knee tracking.'),
          ExerciseDetail(name: 'Romanian Deadlift (RDL)', targetMuscle: 'Hamstrings & Glute-Ham Tie-in', secondaryMuscles: 'Lower Back', equipment: 'Barbell or Dumbbells', sets: 3, reps: 10, weightKg: 40.0, restSeconds: 75, instructions: 'Push hips backwards maintaining slight knee bend until deep hamstring stretch.'),
          ExerciseDetail(name: 'Leg Press', targetMuscle: 'Quadriceps', secondaryMuscles: 'Glutes', equipment: 'Leg Press Machine', sets: 3, reps: 12, weightKg: 100.0, restSeconds: 75, instructions: 'Lower carriage with knees tracking toes without lifting lower back off pad.'),
          ExerciseDetail(name: 'Walking Lunges', targetMuscle: 'Quads & Glutes', secondaryMuscles: 'Hamstrings, Stabilizers', equipment: 'Dumbbells / Bodyweight', sets: 3, reps: 12, weightKg: 10.0, restSeconds: 60, instructions: 'Step forward landing smoothly, lowering rear knee towards floor.'),
          ExerciseDetail(name: 'Lying Leg Curls', targetMuscle: 'Hamstring Flexion', secondaryMuscles: 'Calves', equipment: 'Leg Curl Machine', sets: 3, reps: 12, weightKg: 30.0, restSeconds: 60, instructions: 'Curl pads toward glutes and control 2-second negative.'),
          ExerciseDetail(name: 'Standing Calf Raises', targetMuscle: 'Gastrocnemius', secondaryMuscles: 'Soleus, Achilles', equipment: 'Calf Block / Dumbbell', sets: 4, reps: 15, weightKg: 20.0, restSeconds: 45, instructions: 'Full ankle extension at top with deep 2-second stretch at bottom.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Shoulders',
        icon: '💪',
        exercises: [
          ExerciseDetail(name: 'Seated Overhead Dumbbell Press', targetMuscle: 'Front & Side Deltoids', secondaryMuscles: 'Triceps, Upper Traps', equipment: 'Dumbbells & Bench', sets: 3, reps: 10, weightKg: 14.0, restSeconds: 75, instructions: 'Press overhead in smooth arc without slamming dumbbells together.'),
          ExerciseDetail(name: 'Standing Overhead Barbell Press', targetMuscle: 'Deltoids & Upper Chest', secondaryMuscles: 'Core, Triceps', equipment: 'Olympic Barbell', sets: 3, reps: 8, weightKg: 30.0, restSeconds: 90, instructions: 'Brace glutes and core tightly, press bar straight upwards overhead.'),
          ExerciseDetail(name: 'Dumbbell Lateral Raises', targetMuscle: 'Side Deltoids (Width)', secondaryMuscles: 'Traps', equipment: 'Pair of Dumbbells', sets: 4, reps: 12, weightKg: 8.0, restSeconds: 45, instructions: 'Lead with elbows slightly forward in scapular plane, pause at shoulder height.'),
          ExerciseDetail(name: 'Face Pulls', targetMuscle: 'Rear Delts & Rotator Cuff', secondaryMuscles: 'Rhomboids, Trapezius', equipment: 'Cable Pulley & Rope', sets: 3, reps: 15, weightKg: 15.0, restSeconds: 45, instructions: 'Pull rope toward eye level while rotating hands outward.'),
          ExerciseDetail(name: 'Dumbbell Front Raises', targetMuscle: 'Anterior Deltoids', secondaryMuscles: 'Upper Chest', equipment: 'Dumbbells', sets: 3, reps: 12, weightKg: 7.5, restSeconds: 45, instructions: 'Raise dumbbells to eye height with controlled momentum.'),
          ExerciseDetail(name: 'Rear Delt Dumbbell Flyes', targetMuscle: 'Posterior Deltoids', secondaryMuscles: 'Upper Back', equipment: 'Dumbbells & Bench', sets: 3, reps: 15, weightKg: 6.0, restSeconds: 45, instructions: 'Hinge forward and raise arms wide to focus on posterior delts.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Arms',
        icon: '⚡',
        exercises: [
          ExerciseDetail(name: 'Standing Barbell Bicep Curl', targetMuscle: 'Biceps Brachii', secondaryMuscles: 'Brachialis, Forearms', equipment: 'EZ-Bar / Barbell', sets: 3, reps: 10, weightKg: 20.0, restSeconds: 60, instructions: 'Lock elbows by sides, curl upwards and squeeze biceps peak.'),
          ExerciseDetail(name: 'Dumbbell Hammer Curls', targetMuscle: 'Brachialis & Forearms', secondaryMuscles: 'Outer Bicep', equipment: 'Dumbbells', sets: 3, reps: 12, weightKg: 10.0, restSeconds: 60, instructions: 'Maintain neutral grip (palms facing inward) throughout curl.'),
          ExerciseDetail(name: 'Incline Dumbbell Curl', targetMuscle: 'Bicep Long Head Stretch', secondaryMuscles: 'Forearms', equipment: 'Dumbbells & 45° Bench', sets: 3, reps: 10, weightKg: 8.0, restSeconds: 60, instructions: 'Let arms hang vertically behind torso for maximum long-head stretch.'),
          ExerciseDetail(name: 'Tricep Rope Pushdowns', targetMuscle: 'Triceps Lateral & Medial Head', secondaryMuscles: 'Forearms', equipment: 'Cable & Rope', sets: 3, reps: 12, weightKg: 17.5, restSeconds: 60, instructions: 'Spread rope apart at the bottom lockout for maximal tricep engagement.'),
          ExerciseDetail(name: 'Overhead Dumbbell Tricep Extension', targetMuscle: 'Triceps Long Head', secondaryMuscles: 'Shoulders', equipment: 'Single Dumbbell', sets: 3, reps: 12, weightKg: 14.0, restSeconds: 60, instructions: 'Lower weight behind head with elbows pointing straight forward.'),
          ExerciseDetail(name: 'Tricep Bench Dips', targetMuscle: 'Triceps', secondaryMuscles: 'Chest, Shoulders', equipment: 'Bench / Bodyweight', isBodyweight: true, sets: 3, reps: 15, weightKg: 0.0, restSeconds: 45, instructions: 'Lower hips just past bench edge until arms form 90 degrees.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Core & Mobility',
        icon: '🧘',
        exercises: [
          ExerciseDetail(name: 'Plank Hold', targetMuscle: 'Deep Core & Transverse Abdominis', secondaryMuscles: 'Shoulders, Glutes', equipment: 'Yoga Mat', isTimeBased: true, targetDurationSeconds: 45, sets: 3, reps: 1, weightKg: 0.0, restSeconds: 45, instructions: 'Maintain straight line from head to heels with engaged core and glutes.'),
          ExerciseDetail(name: 'Hanging Leg Raises', targetMuscle: 'Lower Abs', secondaryMuscles: 'Hip Flexors, Grip', equipment: 'Pull-up Bar', isBodyweight: true, sets: 3, reps: 12, weightKg: 0.0, restSeconds: 60, instructions: 'Curl pelvis upwards towards chest without excessive swinging.'),
          ExerciseDetail(name: 'Cable Woodchoppers', targetMuscle: 'Obliques & Core Rotation', secondaryMuscles: 'Shoulders', equipment: 'Cable Pulley', sets: 3, reps: 12, weightKg: 12.5, restSeconds: 45, instructions: 'Rotate torso diagonally downwards driving from hips and core.'),
          ExerciseDetail(name: 'Ab Roller / Wheel Rollout', targetMuscle: 'Rectus Abdominis Anti-Extension', secondaryMuscles: 'Lats, Shoulders', equipment: 'Ab Wheel', isBodyweight: true, sets: 3, reps: 10, weightKg: 0.0, restSeconds: 60, instructions: 'Roll wheel out keeping posterior pelvic tilt, pull back with core.'),
          ExerciseDetail(name: 'Deadbug Core Activation', targetMuscle: 'Core Stability', secondaryMuscles: 'Pelvic Floor', equipment: 'Yoga Mat', isBodyweight: true, sets: 3, reps: 12, weightKg: 0.0, restSeconds: 30, instructions: 'Press lower back into floor while alternating opposite arm and leg extensions.'),
        ],
      ),
      ExerciseLibraryCategory(
        categoryName: 'Cardio & Conditioning',
        icon: '🏃',
        exercises: [
          ExerciseDetail(name: 'Jump Rope / Skipping', targetMuscle: 'Cardiovascular & Calves', secondaryMuscles: 'Forearms, Core', equipment: 'Jump Rope', isTimeBased: true, targetDurationSeconds: 180, sets: 3, reps: 1, weightKg: 0.0, restSeconds: 60, instructions: 'Stay on balls of feet with quick wrist rotations.'),
          ExerciseDetail(name: 'HIIT Burpees', targetMuscle: 'Full Body Conditioning', secondaryMuscles: 'Chest, Quads, Lungs', equipment: 'Bodyweight', isBodyweight: true, sets: 3, reps: 15, weightKg: 0.0, restSeconds: 60, instructions: 'Drop into chest-to-floor pushup, snap feet forward and jump with hands overhead.'),
          ExerciseDetail(name: 'Mountain Climbers', targetMuscle: 'Core & Heart Rate', secondaryMuscles: 'Shoulders, Hip Flexors', equipment: 'Bodyweight', isTimeBased: true, targetDurationSeconds: 45, sets: 3, reps: 1, weightKg: 0.0, restSeconds: 45, instructions: 'Sprint knees alternately towards chest in push-up position.'),
        ],
      ),
    ];
  }

  /// Calculates a smart Progressive Overload target for next session
  static ProgressionSuggestion calculateProgressionSuggestion(ExerciseDetail current) {
    if (current.isTimeBased) {
      final curSec = current.targetDurationSeconds > 0 ? current.targetDurationSeconds : 30;
      final nextSec = curSec + 15;
      return ProgressionSuggestion(
        exerciseName: current.name,
        currentReps: 1,
        currentWeightKg: 0.0,
        currentDurationSeconds: curSec,
        isTimeBased: true,
        suggestedReps: 1,
        suggestedWeightKg: 0.0,
        suggestedDurationSeconds: nextSec,
        progressionType: 'duration',
        reason: 'You successfully conquered $curSec sec! Progressing target to $nextSec sec.',
      );
    } else if (current.isBodyweight) {
      final curReps = current.reps;
      final nextReps = curReps + 2;
      return ProgressionSuggestion(
        exerciseName: current.name,
        currentReps: curReps,
        currentWeightKg: 0.0,
        isBodyweight: true,
        suggestedReps: nextReps,
        suggestedWeightKg: 0.0,
        progressionType: 'reps',
        reason: 'Completed all $curReps planned bodyweight reps! Increasing target to $nextReps reps.',
      );
    } else {
      // Weight or Rep progression
      final curWeight = current.weightKg;
      final curReps = current.reps;
      if (curReps < 12) {
        // Increase reps first
        final nextReps = curReps + 2;
        return ProgressionSuggestion(
          exerciseName: current.name,
          currentReps: curReps,
          currentWeightKg: curWeight,
          suggestedReps: nextReps,
          suggestedWeightKg: curWeight,
          progressionType: 'reps',
          reason: 'Solid performance! Increase volume to $nextReps reps before jumping weight.',
        );
      } else {
        // Increase weight by 2.5 kg and reset reps to 8-10
        final nextWeight = curWeight + 2.5;
        final nextReps = 8;
        return ProgressionSuggestion(
          exerciseName: current.name,
          currentReps: curReps,
          currentWeightKg: curWeight,
          suggestedReps: nextReps,
          suggestedWeightKg: nextWeight,
          progressionType: 'weight',
          reason: 'Hit peak rep range ($curReps reps)! Time for Progressive Overload: +2.5 kg ($nextWeight kg @ 8 reps).',
        );
      }
    }
  }
}

class WorkoutPresetSplits {
  static List<WorkoutDayPlan> getDefaultWeeklyPlan() {
    return [
      WorkoutDayPlan(
        id: 'plan_monday',
        dayName: 'Monday',
        workoutName: 'Chest + Triceps',
        muscleGroup: 'Chest, Triceps & Front Delts',
        estimatedDurationMinutes: 45,
        difficulty: 'Intermediate',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'mon_ex_1',
            name: 'Bench Press',
            targetMuscle: 'Mid Chest',
            secondaryMuscles: 'Triceps, Shoulders',
            equipment: 'Barbell & Bench',
            sets: 3,
            reps: 10,
            weightKg: 20.0,
            restSeconds: 90,
            instructions: 'Lower bar with control to mid-chest, drive up explosively.',
            photoUrl: '🏋️',
            previousPerformance: 'Last time: 3 × 8 @ 20 kg',
          ),
          ExerciseDetail(
            id: 'mon_ex_2',
            name: 'Incline Dumbbell Press',
            targetMuscle: 'Upper Chest',
            secondaryMuscles: 'Front Deltoids',
            equipment: 'Dumbbells & 30° Bench',
            sets: 3,
            reps: 10,
            weightKg: 8.0,
            restSeconds: 75,
            instructions: 'Press dumbbells up in controlled arc.',
            photoUrl: '🏋️',
            previousPerformance: 'Last time: 3 × 10 @ 8 kg',
          ),
          ExerciseDetail(
            id: 'mon_ex_3',
            name: 'Push-ups',
            targetMuscle: 'Chest & Core',
            secondaryMuscles: 'Triceps',
            equipment: 'Bodyweight',
            isBodyweight: true,
            sets: 3,
            reps: 12,
            weightKg: 0.0,
            restSeconds: 60,
            instructions: 'Keep core tight, lower chest to floor.',
            photoUrl: '🤸',
            previousPerformance: 'Last time: 3 × 12 (Bodyweight)',
          ),
          ExerciseDetail(
            id: 'mon_ex_4',
            name: 'Tricep Dips',
            targetMuscle: 'Triceps',
            secondaryMuscles: 'Chest, Shoulders',
            equipment: 'Parallel Bars / Bench',
            isBodyweight: true,
            sets: 3,
            reps: 10,
            weightKg: 0.0,
            restSeconds: 60,
            instructions: 'Lower body until elbows reach 90 degrees.',
            photoUrl: '⚡',
            previousPerformance: 'Last time: 3 × 10 (Bodyweight)',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_tuesday',
        dayName: 'Tuesday',
        workoutName: 'Back + Biceps',
        muscleGroup: 'Lats, Rhomboids, Biceps',
        estimatedDurationMinutes: 45,
        difficulty: 'Intermediate',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'tue_ex_1',
            name: 'Lat Pulldown',
            targetMuscle: 'Lats & V-Taper',
            secondaryMuscles: 'Biceps',
            equipment: 'Cable Machine',
            sets: 3,
            reps: 10,
            weightKg: 40.0,
            restSeconds: 75,
            instructions: 'Pull bar to upper chest squeezing lats.',
            photoUrl: '🧗',
            previousPerformance: 'Last time: 3 × 10 @ 40 kg',
          ),
          ExerciseDetail(
            id: 'tue_ex_2',
            name: 'Pull-ups',
            targetMuscle: 'Upper Back',
            secondaryMuscles: 'Biceps, Forearms',
            equipment: 'Bodyweight',
            isBodyweight: true,
            sets: 3,
            reps: 8,
            weightKg: 0.0,
            restSeconds: 90,
            instructions: 'Pull chin above bar with controlled negative.',
            photoUrl: '🧗',
            previousPerformance: 'Last time: 3 × 8 (Bodyweight)',
          ),
          ExerciseDetail(
            id: 'tue_ex_3',
            name: 'Seated Cable Row',
            targetMuscle: 'Mid-Back Thickness',
            secondaryMuscles: 'Biceps',
            equipment: 'Cable Machine',
            sets: 3,
            reps: 10,
            weightKg: 35.0,
            restSeconds: 60,
            instructions: 'Pull handle to waist with upright posture.',
            photoUrl: '🧗',
            previousPerformance: 'Last time: 3 × 10 @ 35 kg',
          ),
          ExerciseDetail(
            id: 'tue_ex_4',
            name: 'Bicep Curls',
            targetMuscle: 'Biceps Brachii',
            secondaryMuscles: 'Forearms',
            equipment: 'Dumbbells / Barbell',
            sets: 3,
            reps: 12,
            weightKg: 10.0,
            restSeconds: 60,
            instructions: 'Lock elbows and curl with 2-second negative.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 3 × 12 @ 10 kg',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_wednesday',
        dayName: 'Wednesday',
        workoutName: 'Legs',
        muscleGroup: 'Quads, Hamstrings, Glutes & Calves',
        estimatedDurationMinutes: 50,
        difficulty: 'Advanced',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'wed_ex_1',
            name: 'Squats',
            targetMuscle: 'Quadriceps & Glutes',
            secondaryMuscles: 'Hamstrings, Core',
            equipment: 'Barbell / Rack',
            sets: 3,
            reps: 10,
            weightKg: 40.0,
            restSeconds: 90,
            instructions: 'Squat below parallel and drive through heels.',
            photoUrl: '🦵',
            previousPerformance: 'Last time: 3 × 10 @ 40 kg',
          ),
          ExerciseDetail(
            id: 'wed_ex_2',
            name: 'Lunges',
            targetMuscle: 'Quads & Glutes',
            secondaryMuscles: 'Hamstrings, Calves',
            equipment: 'Dumbbells / Bodyweight',
            sets: 3,
            reps: 12,
            weightKg: 8.0,
            restSeconds: 60,
            instructions: 'Step forward landing knee 1 inch off floor.',
            photoUrl: '🦵',
            previousPerformance: 'Last time: 3 × 12 @ 8 kg',
          ),
          ExerciseDetail(
            id: 'wed_ex_3',
            name: 'Leg Press',
            targetMuscle: 'Quadriceps',
            secondaryMuscles: 'Glutes',
            equipment: 'Leg Press Machine',
            sets: 3,
            reps: 12,
            weightKg: 90.0,
            restSeconds: 75,
            instructions: 'Press through midfoot with knees tracking toes.',
            photoUrl: '🦵',
            previousPerformance: 'Last time: 3 × 12 @ 90 kg',
          ),
          ExerciseDetail(
            id: 'wed_ex_4',
            name: 'Calf Raises',
            targetMuscle: 'Calves',
            secondaryMuscles: 'Achilles',
            equipment: 'Dumbbell / Machine',
            sets: 4,
            reps: 15,
            weightKg: 25.0,
            restSeconds: 45,
            instructions: 'Full stretch at bottom and 2-second peak squeeze.',
            photoUrl: '🦵',
            previousPerformance: 'Last time: 4 × 15 @ 25 kg',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_thursday',
        dayName: 'Thursday',
        workoutName: 'Shoulders',
        muscleGroup: 'Deltoids, Traps, Upper Back',
        estimatedDurationMinutes: 40,
        difficulty: 'Intermediate',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'thu_ex_1',
            name: 'Shoulder Press',
            targetMuscle: 'Anterior & Side Deltoids',
            secondaryMuscles: 'Triceps',
            equipment: 'Dumbbells / Barbell',
            sets: 3,
            reps: 10,
            weightKg: 12.0,
            restSeconds: 75,
            instructions: 'Press overhead without locking elbows.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 3 × 10 @ 12 kg',
          ),
          ExerciseDetail(
            id: 'thu_ex_2',
            name: 'Lateral Raise',
            targetMuscle: 'Side Deltoids',
            secondaryMuscles: 'Traps',
            equipment: 'Dumbbells',
            sets: 4,
            reps: 12,
            weightKg: 6.0,
            restSeconds: 45,
            instructions: 'Lead with elbows slightly forward.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 4 × 12 @ 6 kg',
          ),
          ExerciseDetail(
            id: 'thu_ex_3',
            name: 'Front Raise',
            targetMuscle: 'Front Deltoids',
            secondaryMuscles: 'Upper Chest',
            equipment: 'Dumbbells',
            sets: 3,
            reps: 12,
            weightKg: 6.0,
            restSeconds: 45,
            instructions: 'Raise dumbbells to eye height with control.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 3 × 12 @ 6 kg',
          ),
          ExerciseDetail(
            id: 'thu_ex_4',
            name: 'Rear Delt Fly',
            targetMuscle: 'Rear Deltoids',
            secondaryMuscles: 'Rhomboids',
            equipment: 'Dumbbells',
            sets: 3,
            reps: 15,
            weightKg: 5.0,
            restSeconds: 45,
            instructions: 'Hinge forward and raise arms out wide.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 3 × 15 @ 5 kg',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_friday',
        dayName: 'Friday',
        workoutName: 'Full Body',
        muscleGroup: 'Chest, Back, Legs & Core',
        estimatedDurationMinutes: 45,
        difficulty: 'Intermediate',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'fri_ex_1',
            name: 'Incline Bench Press',
            targetMuscle: 'Upper Chest',
            secondaryMuscles: 'Shoulders, Triceps',
            equipment: 'Barbell & Bench',
            sets: 3,
            reps: 10,
            weightKg: 20.0,
            restSeconds: 75,
            instructions: 'Press bar up in controlled path.',
            photoUrl: '🏋️',
            previousPerformance: 'Last time: 3 × 10 @ 20 kg',
          ),
          ExerciseDetail(
            id: 'fri_ex_2',
            name: 'Barbell Row',
            targetMuscle: 'Mid-Back',
            secondaryMuscles: 'Biceps',
            equipment: 'Barbell',
            sets: 3,
            reps: 10,
            weightKg: 35.0,
            restSeconds: 75,
            instructions: 'Pull bar to abdomen keeping flat spine.',
            photoUrl: '🧗',
            previousPerformance: 'Last time: 3 × 10 @ 35 kg',
          ),
          ExerciseDetail(
            id: 'fri_ex_3',
            name: 'Squats',
            targetMuscle: 'Quadriceps',
            secondaryMuscles: 'Glutes',
            equipment: 'Barbell / Dumbbells',
            sets: 3,
            reps: 10,
            weightKg: 35.0,
            restSeconds: 75,
            instructions: 'Squat deep with proud chest.',
            photoUrl: '🦵',
            previousPerformance: 'Last time: 3 × 10 @ 35 kg',
          ),
          ExerciseDetail(
            id: 'fri_ex_4',
            name: 'Bicep Curl',
            targetMuscle: 'Biceps',
            secondaryMuscles: 'Forearms',
            equipment: 'Dumbbells',
            sets: 3,
            reps: 12,
            weightKg: 10.0,
            restSeconds: 60,
            instructions: 'Controlled eccentric contraction.',
            photoUrl: '💪',
            previousPerformance: 'Last time: 3 × 12 @ 10 kg',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_saturday',
        dayName: 'Saturday',
        workoutName: 'Cardio + Core',
        muscleGroup: 'Abs, Obliques & Cardiovascular',
        estimatedDurationMinutes: 35,
        difficulty: 'Beginner',
        status: WorkoutStatus.planned,
        isRestDay: false,
        version: 1,
        exercises: [
          ExerciseDetail(
            id: 'sat_ex_1',
            name: 'Plank',
            targetMuscle: 'Core & Abdominals',
            secondaryMuscles: 'Glutes, Shoulders',
            equipment: 'Bodyweight / Mat',
            isTimeBased: true,
            targetDurationSeconds: 45,
            sets: 3,
            reps: 1,
            weightKg: 0.0,
            restSeconds: 45,
            instructions: 'Hold rigid torso position without dipping hips.',
            photoUrl: '🧘',
            previousPerformance: 'Last time: 3 × 30s',
          ),
          ExerciseDetail(
            id: 'sat_ex_2',
            name: 'Push-ups',
            targetMuscle: 'Chest & Core',
            secondaryMuscles: 'Triceps',
            equipment: 'Bodyweight',
            isBodyweight: true,
            sets: 3,
            reps: 15,
            weightKg: 0.0,
            restSeconds: 45,
            instructions: 'Quick cadence push-ups.',
            photoUrl: '🤸',
            previousPerformance: 'Last time: 3 × 12 (Bodyweight)',
          ),
          ExerciseDetail(
            id: 'sat_ex_3',
            name: 'Mountain Climbers',
            targetMuscle: 'Core & Conditioning',
            secondaryMuscles: 'Shoulders',
            equipment: 'Bodyweight',
            isTimeBased: true,
            targetDurationSeconds: 40,
            sets: 3,
            reps: 1,
            weightKg: 0.0,
            restSeconds: 45,
            instructions: 'Drive knees rhythmically to chest.',
            photoUrl: '🏃',
            previousPerformance: 'Last time: 3 × 30s',
          ),
        ],
      ),
      WorkoutDayPlan(
        id: 'plan_sunday',
        dayName: 'Sunday',
        workoutName: 'Rest',
        muscleGroup: 'Full Body Recovery',
        estimatedDurationMinutes: 0,
        difficulty: 'Recovery',
        status: WorkoutStatus.restDay,
        isRestDay: true,
        version: 1,
        exercises: [],
      ),
    ];
  }
}

