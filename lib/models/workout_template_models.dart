import 'dart:convert';

/// Single Set for an Exercise with Weight & Reps Tracking
class ExerciseSet {
  int setNumber;
  double weightKg;
  int reps;
  bool isCompleted;

  ExerciseSet({
    required this.setNumber,
    this.weightKg = 20.0,
    this.reps = 10,
    this.isCompleted = false,
  });

  double get volumeTonnage => isCompleted ? (weightKg * reps) : 0.0;

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'weightKg': weightKg,
        'reps': reps,
        'isCompleted': isCompleted ? 1 : 0,
      };

  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
        setNumber: map['setNumber'] ?? 1,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 20.0,
        reps: (map['reps'] as num?)?.toInt() ?? 10,
        isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      );
}

/// Gym Exercise with Sets, Weight Tracking & Progressive Overload
class GymExercise {
  final String id;
  String name;
  String targetMuscle;
  String equipment;
  List<ExerciseSet> sets;
  double personalRecordWeightKg;
  String cue;

  GymExercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    this.equipment = 'Barbell / Dumbbell',
    required this.sets,
    this.personalRecordWeightKg = 0.0,
    this.cue = 'Drive with controlled tempo & peak contraction',
  });

  double get totalTonnage => sets.fold(0.0, (sum, s) => sum + s.volumeTonnage);
  int get completedSets => sets.where((s) => s.isCompleted).length;
  bool get isAllCompleted => sets.isNotEmpty && sets.every((s) => s.isCompleted);
  double get maxWeightLogged => sets.where((s) => s.isCompleted).fold(0.0, (max, s) => s.weightKg > max ? s.weightKg : max);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetMuscle': targetMuscle,
        'equipment': equipment,
        'sets': jsonEncode(sets.map((s) => s.toMap()).toList()),
        'personalRecordWeightKg': personalRecordWeightKg,
        'cue': cue,
      };

  factory GymExercise.fromMap(Map<String, dynamic> map) {
    List<ExerciseSet> parsedSets = [];
    if (map['sets'] != null) {
      try {
        final decoded = map['sets'] is String ? jsonDecode(map['sets']) : map['sets'];
        if (decoded is List) {
          parsedSets = decoded.map((s) => ExerciseSet.fromMap(s as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }
    if (parsedSets.isEmpty) {
      parsedSets = [
        ExerciseSet(setNumber: 1, weightKg: 30, reps: 12),
        ExerciseSet(setNumber: 2, weightKg: 40, reps: 10),
        ExerciseSet(setNumber: 3, weightKg: 50, reps: 8),
      ];
    }

    return GymExercise(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Exercise',
      targetMuscle: map['targetMuscle'] ?? 'General',
      equipment: map['equipment'] ?? 'Dumbbell',
      sets: parsedSets,
      personalRecordWeightKg: (map['personalRecordWeightKg'] as num?)?.toDouble() ?? 0.0,
      cue: map['cue'] ?? 'Controlled tempo & lock core',
    );
  }
}

/// Day-Wise Workout Split Model
class DayWorkoutSplit {
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String title;
  final String muscleFocus;
  final String iconEmoji;
  final String motto;
  List<GymExercise> exercises;

  DayWorkoutSplit({
    required this.dayOfWeek,
    required this.title,
    required this.muscleFocus,
    required this.iconEmoji,
    required this.motto,
    required this.exercises,
  });

  double get totalDayTonnage => exercises.fold(0.0, (sum, e) => sum + e.totalTonnage);
  int get totalCompletedSets => exercises.fold(0, (sum, e) => sum + e.completedSets);
  int get totalTargetSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  double get completionProgress => totalTargetSets > 0 ? (totalCompletedSets / totalTargetSets) : 0.0;
}

/// 7-Day Master Gym Splits Database
class WorkoutSplitTemplates {
  static List<DayWorkoutSplit> getWeeklySplits() {
    return [
      // 1. MONDAY - CHEST & TRICEPS (PUSH)
      DayWorkoutSplit(
        dayOfWeek: 'Monday',
        title: 'Chest & Triceps Power',
        muscleFocus: 'Pectorals, Anterior Deltoids & Triceps',
        iconEmoji: '🛡️',
        motto: 'Build unbreakable upper body pressing strength.',
        exercises: [
          GymExercise(
            id: 'mon_1',
            name: 'Barbell Flat Bench Press',
            targetMuscle: 'Mid-Chest & Triceps',
            equipment: 'Olympic Barbell',
            personalRecordWeightKg: 85.0,
            cue: 'Retract scapulae, touch lower sternum, explode up.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 50.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 65.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 75.0, reps: 8),
              ExerciseSet(setNumber: 4, weightKg: 85.0, reps: 6),
            ],
          ),
          GymExercise(
            id: 'mon_2',
            name: 'Incline Dumbbell Press',
            targetMuscle: 'Upper Chest Clavicular Head',
            equipment: 'Incline Bench (30°) + Dumbbells',
            personalRecordWeightKg: 28.0,
            cue: 'Squeeze upper chest at top without banging dumbbells.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 20.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 24.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 28.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'mon_3',
            name: 'Cable Chest Flyes / Crossovers',
            targetMuscle: 'Sternal Pectoral Contraction',
            equipment: 'Cable Tower',
            personalRecordWeightKg: 15.0,
            cue: 'Slight elbow bend, hug a giant barrel, 2s peak squeeze.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 10.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 12.5, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 15.0, reps: 10),
            ],
          ),
          GymExercise(
            id: 'mon_4',
            name: 'Triceps Rope Pushdowns',
            targetMuscle: 'Triceps Lateral & Medial Heads',
            equipment: 'Cable Machine + Rope',
            personalRecordWeightKg: 25.0,
            cue: 'Keep elbows glued to ribs, flare rope at bottom.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 17.5, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 22.5, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 25.0, reps: 10),
            ],
          ),
          GymExercise(
            id: 'mon_5',
            name: 'Overhead EZ-Bar Skull Crushers',
            targetMuscle: 'Triceps Long Head Hypertrophy',
            equipment: 'EZ-Curl Bar',
            personalRecordWeightKg: 30.0,
            cue: 'Lower bar behind head to stretch long head deeply.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 20.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 25.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 30.0, reps: 8),
            ],
          ),
        ],
      ),

      // 2. TUESDAY - BACK & BICEPS (PULL)
      DayWorkoutSplit(
        dayOfWeek: 'Tuesday',
        title: 'Back & Biceps Heavy Pull',
        muscleFocus: 'Latissimus Dorsi, Rhomboids, Traps & Biceps',
        iconEmoji: '🦅',
        motto: 'Build a wide, dense back that projects authority.',
        exercises: [
          GymExercise(
            id: 'tue_1',
            name: 'Conventional Deadlift / Rack Pulls',
            targetMuscle: 'Posterior Chain & Erector Spinae',
            equipment: 'Olympic Barbell',
            personalRecordWeightKg: 120.0,
            cue: 'Engage lats, brace core, drive floor away with legs.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 70.0, reps: 10),
              ExerciseSet(setNumber: 2, weightKg: 95.0, reps: 8),
              ExerciseSet(setNumber: 3, weightKg: 110.0, reps: 6),
              ExerciseSet(setNumber: 4, weightKg: 120.0, reps: 4),
            ],
          ),
          GymExercise(
            id: 'tue_2',
            name: 'Wide-Grip Lat Pulldowns',
            targetMuscle: 'Upper Lat Width & Taper',
            equipment: 'Lat Pulldown Machine',
            personalRecordWeightKg: 65.0,
            cue: 'Pull with elbows down to hips, pause at collarbone.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 45.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 55.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 65.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'tue_3',
            name: 'Bent-Over Barbell Rows',
            targetMuscle: 'Mid-Back & Rhomboid Thickness',
            equipment: 'Olympic Barbell',
            personalRecordWeightKg: 65.0,
            cue: '45-degree torso, pull barbell to navel, squeeze blades.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 40.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 50.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 65.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'tue_4',
            name: 'Incline Dumbbell Bicep Curls',
            targetMuscle: 'Biceps Long Head Peak',
            equipment: 'Incline Bench + Dumbbells',
            personalRecordWeightKg: 16.0,
            cue: 'Full stretch at bottom, supinate wrists at top.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 10.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 12.5, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 16.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'tue_5',
            name: 'Cross-Body Hammer Curls',
            targetMuscle: 'Brachialis & Forearm Brachioradialis',
            equipment: 'Dumbbells',
            personalRecordWeightKg: 18.0,
            cue: 'Neutral grip, curl across torso for massive arm thickness.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 12.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 15.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 18.0, reps: 8),
            ],
          ),
        ],
      ),

      // 3. WEDNESDAY - LEGS & GLUTES
      DayWorkoutSplit(
        dayOfWeek: 'Wednesday',
        title: 'Legs & Glutes Mastery',
        muscleFocus: 'Quadriceps, Hamstrings, Glutes & Calves',
        iconEmoji: '🦵',
        motto: 'True discipline is forged on heavy leg day.',
        exercises: [
          GymExercise(
            id: 'wed_1',
            name: 'Barbell Back Squats',
            targetMuscle: 'Quads, Glutes & Core Stability',
            equipment: 'Squat Rack + Olympic Bar',
            personalRecordWeightKg: 100.0,
            cue: 'Hit parallel depth, drive knees outward, push through midfoot.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 50.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 75.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 90.0, reps: 8),
              ExerciseSet(setNumber: 4, weightKg: 100.0, reps: 6),
            ],
          ),
          GymExercise(
            id: 'wed_2',
            name: 'Leg Press (Heavy Tonnage)',
            targetMuscle: 'Quad Hypertrophy & Vastus Medialis',
            equipment: '45° Leg Press Machine',
            personalRecordWeightKg: 180.0,
            cue: 'Never lock knees at top, deep knee bend for quad stretch.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 120.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 150.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 180.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'wed_3',
            name: 'Romanian Deadlifts (RDL)',
            targetMuscle: 'Hamstrings & Posterior Glute Tie-In',
            equipment: 'Dumbbells / Barbell',
            personalRecordWeightKg: 70.0,
            cue: 'Push hips back until deep hamstring stretch, neutral spine.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 40.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 55.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 70.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'wed_4',
            name: 'Walking Dumbbell Lunges',
            targetMuscle: 'Unilateral Glutes & Stability',
            equipment: 'Pair of Dumbbells',
            personalRecordWeightKg: 16.0,
            cue: 'Chest tall, 90-degree step, feel glute loading on each stride.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 12.0, reps: 20),
              ExerciseSet(setNumber: 2, weightKg: 16.0, reps: 20),
              ExerciseSet(setNumber: 3, weightKg: 16.0, reps: 20),
            ],
          ),
          GymExercise(
            id: 'wed_5',
            name: 'Standing Calf Raises',
            targetMuscle: 'Gastrocnemius & Soleus',
            equipment: 'Calf Machine or Step',
            personalRecordWeightKg: 60.0,
            cue: 'Full stretch at bottom, 2s hold at peak contraction.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 40.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 50.0, reps: 15),
              ExerciseSet(setNumber: 3, weightKg: 60.0, reps: 12),
            ],
          ),
        ],
      ),

      // 4. THURSDAY - SHOULDERS & CORE
      DayWorkoutSplit(
        dayOfWeek: 'Thursday',
        title: 'Shoulders, Traps & Core',
        muscleFocus: 'Deltoids (Front/Side/Rear), Trapezius & Abs',
        iconEmoji: '⚡',
        motto: 'Build 3D cannonball shoulders and armor-plated core.',
        exercises: [
          GymExercise(
            id: 'thu_1',
            name: 'Standing Overhead Military Press',
            targetMuscle: 'Anterior & Medial Deltoids',
            equipment: 'Olympic Barbell',
            personalRecordWeightKg: 55.0,
            cue: 'Brace glutes & core, press straight up, lock head through.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 30.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 40.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 50.0, reps: 8),
              ExerciseSet(setNumber: 4, weightKg: 55.0, reps: 6),
            ],
          ),
          GymExercise(
            id: 'thu_2',
            name: 'Dumbbell Lateral Raises',
            targetMuscle: 'Lateral Deltoid Width (V-Taper)',
            equipment: 'Dumbbells',
            personalRecordWeightKg: 14.0,
            cue: 'Lead with elbows, tilt pinky up, control the descent.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 8.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 10.0, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 12.5, reps: 10),
              ExerciseSet(setNumber: 4, weightKg: 14.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'thu_3',
            name: 'Rope Face Pulls with External Rotation',
            targetMuscle: 'Rear Deltoids & Rotator Cuff Health',
            equipment: 'Cable Machine',
            personalRecordWeightKg: 25.0,
            cue: 'Pull to eye level, pull thumbs back, squeeze rear delts.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 15.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 20.0, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 25.0, reps: 12),
            ],
          ),
          GymExercise(
            id: 'thu_4',
            name: 'Heavy Dumbbell Shrugs',
            targetMuscle: 'Upper Trapezius',
            equipment: 'Heavy Dumbbells',
            personalRecordWeightKg: 36.0,
            cue: 'Shrug straight up to ears, 2s isometric hold, do not roll shoulders.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 24.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 30.0, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 36.0, reps: 10),
            ],
          ),
          GymExercise(
            id: 'thu_5',
            name: 'Hanging Leg Raises / Captain Chair',
            targetMuscle: 'Lower Rectus Abdominis',
            equipment: 'Pull-up Bar',
            personalRecordWeightKg: 0.0,
            cue: 'Curl pelvis up towards chest, prevent swinging.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 0.0, reps: 15),
              ExerciseSet(setNumber: 3, weightKg: 0.0, reps: 15),
            ],
          ),
        ],
      ),

      // 5. FRIDAY - ARMS & FUNCTIONAL HYPERTROPHY
      DayWorkoutSplit(
        dayOfWeek: 'Friday',
        title: 'Arms & Hypertrophy Finisher',
        muscleFocus: 'Biceps, Triceps, Forearms & Grip',
        iconEmoji: '💪',
        motto: 'Fill out your sleeves with relentless pump.',
        exercises: [
          GymExercise(
            id: 'fri_1',
            name: 'Preacher Barbell Curls',
            targetMuscle: 'Biceps Short Head & Peak Isolation',
            equipment: 'Preacher Bench + EZ Bar',
            personalRecordWeightKg: 35.0,
            cue: 'Lock armpits into pad, strict isolation, no shoulder help.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 20.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 27.5, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 35.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'fri_2',
            name: 'Weighted Triceps Parallel Dips',
            targetMuscle: 'Triceps Mass & Lower Chest',
            equipment: 'Dip Station + Weight Belt',
            personalRecordWeightKg: 20.0,
            cue: 'Keep torso upright to target triceps, lower to 90 degrees.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 10.0, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 20.0, reps: 8),
            ],
          ),
          GymExercise(
            id: 'fri_3',
            name: 'Cable Overhead Rope Extension',
            targetMuscle: 'Long Head Triceps Deep Stretch',
            equipment: 'Cable Machine',
            personalRecordWeightKg: 22.5,
            cue: 'Lean forward, extend elbows straight ahead, flare rope.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 15.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 17.5, reps: 10),
              ExerciseSet(setNumber: 3, weightKg: 22.5, reps: 10),
            ],
          ),
          GymExercise(
            id: 'fri_4',
            name: 'Barbell Reverse Forearm Curls',
            targetMuscle: 'Brachioradialis & Forearm Extensors',
            equipment: 'Straight Barbell',
            personalRecordWeightKg: 25.0,
            cue: 'Overhand grip, curl wrists up, builds crushing grip strength.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 15.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 20.0, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 25.0, reps: 10),
            ],
          ),
        ],
      ),

      // 6. SATURDAY - FULL BODY HIIT & ABS CONDITIONING
      DayWorkoutSplit(
        dayOfWeek: 'Saturday',
        title: 'Full Body HIIT & Cardio Blast',
        muscleFocus: 'Cardiovascular Endurance, Agility & Core',
        iconEmoji: '🔥',
        motto: 'Burn maximum fat and expand anaerobic threshold.',
        exercises: [
          GymExercise(
            id: 'sat_1',
            name: 'Kettlebell Power Swings',
            targetMuscle: 'Hips, Glutes, Hamstrings & Cardio',
            equipment: 'Cast Iron Kettlebell',
            personalRecordWeightKg: 24.0,
            cue: 'Hinge at hips, explode forward, squeeze glutes at top.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 16.0, reps: 20),
              ExerciseSet(setNumber: 2, weightKg: 20.0, reps: 20),
              ExerciseSet(setNumber: 3, weightKg: 24.0, reps: 20),
            ],
          ),
          GymExercise(
            id: 'sat_2',
            name: 'Battle Ropes Alternating Waves',
            targetMuscle: 'Shoulders, Core & Lactate Threshold',
            equipment: 'Heavy Battle Ropes',
            personalRecordWeightKg: 0.0,
            cue: 'Athletic stance, rapid high-intensity wave generation for 30s.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 30),
              ExerciseSet(setNumber: 2, weightKg: 0.0, reps: 30),
              ExerciseSet(setNumber: 3, weightKg: 0.0, reps: 30),
            ],
          ),
          GymExercise(
            id: 'sat_3',
            name: 'Weighted Russian Twists',
            targetMuscle: 'Obliques & Rotational Core Power',
            equipment: 'Medicine Ball / Plate',
            personalRecordWeightKg: 10.0,
            cue: 'Elevate feet, rotate shoulders fully to touch plate to floor.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 5.0, reps: 20),
              ExerciseSet(setNumber: 2, weightKg: 7.5, reps: 20),
              ExerciseSet(setNumber: 3, weightKg: 10.0, reps: 20),
            ],
          ),
          GymExercise(
            id: 'sat_4',
            name: 'Abdominal Wheel Rollouts',
            targetMuscle: 'Deep Core Armor & Anti-Extension',
            equipment: 'Ab Wheel',
            personalRecordWeightKg: 0.0,
            cue: 'Posterior pelvic tilt, roll out slowly without arching lower back.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 12),
              ExerciseSet(setNumber: 2, weightKg: 0.0, reps: 12),
              ExerciseSet(setNumber: 3, weightKg: 0.0, reps: 12),
            ],
          ),
        ],
      ),

      // 7. SUNDAY - ACTIVE RECOVERY & MOBILITY
      DayWorkoutSplit(
        dayOfWeek: 'Sunday',
        title: 'Active Recovery & Joint Mobility',
        muscleFocus: 'Fascia Release, Joint Decompression & Flexibility',
        iconEmoji: '🧘‍♂️',
        motto: 'Restore connective tissues to dominate next week.',
        exercises: [
          GymExercise(
            id: 'sun_1',
            name: '90/90 Hip Flow & Deep Squat Hold',
            targetMuscle: 'Hip Capsule Internal/External Rotation',
            equipment: 'Yoga Mat',
            personalRecordWeightKg: 0.0,
            cue: 'Hold bottom of deep goblet squat for 60s, open hips.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 3),
              ExerciseSet(setNumber: 2, weightKg: 0.0, reps: 3),
            ],
          ),
          GymExercise(
            id: 'sun_2',
            name: 'PVC Pipe Shoulder Dislocates',
            targetMuscle: 'Thoracic Spine & Shoulder Girdle Mobility',
            equipment: 'PVC Pipe / Resistance Band',
            personalRecordWeightKg: 0.0,
            cue: 'Locked elbows, rotate smoothly over head to lower back.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 15),
              ExerciseSet(setNumber: 2, weightKg: 0.0, reps: 15),
            ],
          ),
          GymExercise(
            id: 'sun_3',
            name: 'Full Body Foam Rolling & Trigger Point',
            targetMuscle: 'IT Band, Quads, Lats & Upper Back',
            equipment: 'High-Density Foam Roller',
            personalRecordWeightKg: 0.0,
            cue: 'Spend 90 seconds on tender spots, breathe deeply.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 10),
            ],
          ),
          GymExercise(
            id: 'sun_4',
            name: '30-Min Zone-2 Recovery Walk',
            targetMuscle: 'Parasympathetic Nervous System Recharge',
            equipment: 'Outdoor Trails / Treadmill',
            personalRecordWeightKg: 0.0,
            cue: 'Nasal breathing only, easy conversational pace.',
            sets: [
              ExerciseSet(setNumber: 1, weightKg: 0.0, reps: 30),
            ],
          ),
        ],
      ),
    ];
  }
}
