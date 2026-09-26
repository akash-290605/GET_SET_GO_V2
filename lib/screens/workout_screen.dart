import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/workout_template_models.dart';
import '../widgets/titan_ai_sheet.dart';

/// Complete Day-Wise Gym Workout & Body Analytics Screen
class WorkoutAndPhotosScreen extends StatefulWidget {
  const WorkoutAndPhotosScreen({super.key});

  @override
  State<WorkoutAndPhotosScreen> createState() => _WorkoutAndPhotosScreenState();
}

class _WorkoutAndPhotosScreenState extends State<WorkoutAndPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _face;
  XFile? _front;
  XFile? _side;

  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  final _walkController = TextEditingController(text: '${WorkoutState.walkMins}');
  final _jogController = TextEditingController(text: '${WorkoutState.jogMins}');
  final _walkKmController = TextEditingController(text: WorkoutState.walkDistanceKm.toStringAsFixed(1));
  final _jogKmController = TextEditingController(text: WorkoutState.jogDistanceKm.toStringAsFixed(1));
  final _gymController = TextEditingController(text: '${WorkoutState.gymMins}');

  // 7-Day Splits Data
  late List<DayWorkoutSplit> _weeklySplits;
  late int _selectedDayIndex;

  final List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _weeklySplits = WorkoutSplitTemplates.getWeeklySplits();

    // Auto-select current day of week (Monday=0, Sunday=6)
    final todayWeekday = DateTime.now().weekday; // 1 (Mon) to 7 (Sun)
    _selectedDayIndex = (todayWeekday - 1).clamp(0, 6);

    _weightCtrl.text = HealthState.weightKg > 0 ? '${HealthState.weightKg}' : '';
    _targetWeightCtrl.text = HealthState.targetWeightKg > 0 ? '${HealthState.targetWeightKg}' : '';
    _heightCtrl.text = HealthState.heightCm > 0 ? '${HealthState.heightCm}' : '';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _heightCtrl.dispose();
    _walkController.dispose();
    _jogController.dispose();
    _walkKmController.dispose();
    _jogKmController.dispose();
    _gymController.dispose();
    super.dispose();
  }

  DayWorkoutSplit get _activeSplit => _weeklySplits[_selectedDayIndex];

  void _saveHealthMetrics() {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final tw = double.tryParse(_targetWeightCtrl.text.trim()) ?? 0.0;
    final h = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;

    if (w > 0 && h > 0) {
      setState(() {
        HealthState.weightKg = w;
        HealthState.targetWeightKg = tw;
        HealthState.heightCm = h;
        HealthState.lastWeightLogDate = DateTime.now();
        HealthState.monthlyWeightHistory.add(w);
      });

      DisciplineFeedback.showCelebration(
        context: context,
        title: '⚖️ Biometrics & BMI Updated!',
        message: 'Weight: $w kg | Height: $h cm | BMI: ${HealthState.bmi.toStringAsFixed(1)} (${HealthState.bmiCategory}).',
        disciplineQuote: 'Take care of your body. It\'s the only place you have to live.',
        color: HealthState.bmiColor,
        icon: Icons.monitor_weight_rounded,
      );
    }
  }

  void _updateCardioMinutes() {
    final wMins = int.tryParse(_walkController.text.trim()) ?? 0;
    final jMins = int.tryParse(_jogController.text.trim()) ?? 0;
    final gMins = int.tryParse(_gymController.text.trim()) ?? 0;

    setState(() {
      WorkoutState.walkMins = wMins;
      WorkoutState.jogMins = jMins;
      WorkoutState.gymMins = gMins;
      WorkoutState.updateDistance(walkMinutes: wMins, jogMinutes: jMins);
      _walkKmController.text = WorkoutState.walkDistanceKm.toStringAsFixed(1);
      _jogKmController.text = WorkoutState.jogDistanceKm.toStringAsFixed(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('🏃 Cardio synced: ${WorkoutState.totalDistanceKm.toStringAsFixed(1)} km total!', style: const TextStyle(color: AppColors.accentBlue)),
      ),
    );
  }

  void _toggleSetCompletion(GymExercise ex, ExerciseSet s) {
    setState(() {
      s.isCompleted = !s.isCompleted;
    });

    if (s.isCompleted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Set ${s.setNumber} Done: ${s.weightKg}kg × ${s.reps}r (+${s.volumeTonnage.toInt()}kg volume!)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _editSetDetails(GymExercise ex, ExerciseSet s) {
    final weightCtrl = TextEditingController(text: '${s.weightKg}');
    final repsCtrl = TextEditingController(text: '${s.reps}');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.secondary, width: 1.2)),
        title: Row(
          children: [
            const Icon(Icons.fitness_center_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Edit Set ${s.setNumber} • ${ex.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.line_weight_rounded, size: 16)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Reps', prefixIcon: Icon(Icons.repeat_rounded, size: 16)),
            ),
            const SizedBox(height: 8),
            const Text('💡 Progressive Overload: Aim to increase weight by +1-2.5 kg or reps by +1 each week!', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(weightCtrl.text.trim()) ?? s.weightKg;
              final r = int.tryParse(repsCtrl.text.trim()) ?? s.reps;
              setState(() {
                s.weightKg = w;
                s.reps = r;
                if (w > ex.personalRecordWeightKg) {
                  ex.personalRecordWeightKg = w;
                }
              });
              Navigator.pop(dialogCtx);
            },
            child: const Text('Update Set'),
          ),
        ],
      ),
    );
  }

  void _addNewSet(GymExercise ex) {
    setState(() {
      final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
      final newSetNum = ex.sets.length + 1;
      final newWeight = lastSet?.weightKg ?? 25.0;
      final newReps = lastSet?.reps ?? 10;
      ex.sets.add(ExerciseSet(setNumber: newSetNum, weightKg: newWeight, reps: newReps));
    });
  }

  void _removeLastSet(GymExercise ex) {
    if (ex.sets.length > 1) {
      setState(() {
        ex.sets.removeLast();
      });
    }
  }

  void _showAddCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController(text: _activeSplit.muscleFocus.split(',').first);
    final equipCtrl = TextEditingController(text: 'Dumbbells / Barbell');
    final weightCtrl = TextEditingController(text: '20.0');
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '12');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.primary, width: 1.2)),
        title: Row(
          children: [
            const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Add Exercise to ${_activeSplit.dayOfWeek}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name (e.g. Incline Flyes)')),
              const SizedBox(height: 10),
              TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'Target Muscle')),
              const SizedBox(height: 10),
              TextField(controller: equipCtrl, decoration: const InputDecoration(labelText: 'Equipment')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: setsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sets'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final w = double.tryParse(weightCtrl.text.trim()) ?? 20.0;
              final numSets = int.tryParse(setsCtrl.text.trim()) ?? 3;
              final numReps = int.tryParse(repsCtrl.text.trim()) ?? 12;

              if (name.isNotEmpty) {
                final newEx = GymExercise(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  targetMuscle: muscleCtrl.text.trim(),
                  equipment: equipCtrl.text.trim(),
                  personalRecordWeightKg: w,
                  sets: List.generate(
                    numSets,
                    (i) => ExerciseSet(setNumber: i + 1, weightKg: w, reps: numReps),
                  ),
                );
                setState(() {
                  _activeSplit.exercises.add(newEx);
                });
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }

  void _askAIForSplitStrategy() {
    final prompt = 'Recommend progressive overload, warm-up sets, and mind-muscle cues for my ${_activeSplit.dayOfWeek} split focusing on ${_activeSplit.muscleFocus}.';
    TitanAICoachSheet.show(context, initialPrompt: prompt);
  }

  void _finishDayWorkout() {
    final totalTonnage = _activeSplit.totalDayTonnage;
    final completedSets = _activeSplit.totalCompletedSets;
    final totalSets = _activeSplit.totalTargetSets;

    DisciplineFeedback.showCelebration(
      context: context,
      title: '🏆 ${_activeSplit.title} Conquered!',
      message: 'Moved ${totalTonnage.toInt()} KG total weight volume across $completedSets/$totalSets sets today!\nYour physical engine is built through relentless consistency.',
      disciplineQuote: 'The iron never lies to you. 200 pounds is always 200 pounds.',
      color: AppColors.primary,
      icon: Icons.fitness_center_rounded,
    );
  }

  Future<void> _uploadPhoto(String angle) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null && mounted) {
        setState(() {
          if (angle == 'Face') _face = photo;
          if (angle == 'Front') _front = photo;
          if (angle == 'Side') _side = photo;
        });
        DisciplineFeedback.showCelebration(
          context: context,
          title: '📸 Physique Check Logged!',
          message: '$angle profile photo saved! Visual records prove transformation.',
          disciplineQuote: 'Discipline is the bridge between goals and accomplishment.',
          color: AppColors.secondary,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final split = _activeSplit;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 7-DAY DAY SELECTOR HORIZONTAL BAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weeklySplits.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isSelected = _selectedDayIndex == idx;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDayIndex = idx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                              : null,
                          color: isSelected ? null : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.borderLight,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8)]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.iconEmoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.dayOfWeek.substring(0, 3).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : AppColors.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  s.title.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white70 : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. ACTIVE SPLIT SUMMARY BANNER & METRICS
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1538), Color(0xFF121E33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 14),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(split.iconEmoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${split.dayOfWeek.toUpperCase()} • ${split.title}',
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  split.muscleFocus,
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 20),
                      tooltip: 'Ask Titan AI for Split Strategy',
                      onPressed: _askAIForSplitStrategy,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${split.motto}"',
                  style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFFFED7AA)),
                ),
                const SizedBox(height: 14),

                // Volume & Sets Metrics Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text('DAY VOLUME MOVED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 3),
                            Text('${split.totalDayTonnage.toInt()} KG', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text('SETS COMPLETED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 3),
                            Text('${split.totalCompletedSets} / ${split.totalTargetSets}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accentGreen)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: split.completionProgress,
                    minHeight: 7,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. EXERCISE LIST FOR THE ACTIVE DAY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${split.dayOfWeek.toUpperCase()} EXERCISES (${split.exercises.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                onPressed: _showAddCustomExerciseDialog,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryGlow),
                label: const Text('+ Add Custom Lift', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...split.exercises.map((ex) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ex.isAllCompleted ? AppColors.accentGreen.withValues(alpha: 0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ex.isAllCompleted ? AppColors.accentGreen.withValues(alpha: 0.5) : AppColors.borderLight,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + PR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: ex.isAllCompleted ? AppColors.accentGreen : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ex.equipment} • ${ex.targetMuscle}',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (ex.personalRecordWeightKg > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'PR: ${ex.personalRecordWeightKg.toInt()}kg 🏆',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 Cue: ${ex.cue}',
                    style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.white54),
                  ),
                  const SizedBox(height: 10),

                  // Sets Chips Row with Weight & Reps
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ex.sets.map((s) {
                      return InkWell(
                        onTap: () => _toggleSetCompletion(ex, s),
                        onLongPress: () => _editSetDetails(ex, s),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: s.isCompleted ? AppColors.accentGreen.withValues(alpha: 0.25) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: s.isCompleted ? AppColors.accentGreen : AppColors.borderLight,
                              width: s.isCompleted ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                s.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 13,
                                color: s.isCompleted ? AppColors.accentGreen : Colors.white38,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Set ${s.setNumber}: ${s.weightKg}kg × ${s.reps}r',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: s.isCompleted ? Colors.white : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Actions: Add Set / Remove Set / Edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total Volume: ${ex.totalTonnage.toInt()} kg',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _addNewSet(ex),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text('+ Set', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                        ),
                      ),
                      if (ex.sets.length > 1) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeLastSet(ex),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('- Set', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _finishDayWorkout,
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              label: Text('Finish ${_activeSplit.dayOfWeek} Workout & Log Tonnage', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const Divider(height: 32, color: AppColors.borderLight),

          // 4. DAILY CARDIO & DISTANCE SYNC
          const Text('🏃 Daily Cardio & Walking Track', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _walkController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Walk (Mins)', prefixIcon: Icon(Icons.directions_walk_rounded, size: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _jogController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jog (Mins)', prefixIcon: Icon(Icons.directions_run_rounded, size: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _updateCardioMinutes,
                    child: const Text('Update Cardio Minutes & Distance'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32, color: AppColors.borderLight),

          // 5. BIOMETRICS & WEIGHT TRACKER
          const Text('⚖️ Biometrics & Weekly Weigh-In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _targetWeightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target (kg)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                    onPressed: _saveHealthMetrics,
                    child: const Text('Save Biometrics & Compute BMI'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32, color: AppColors.borderLight),

          // 6. DAILY PHYSIQUE PHOTOS (3 ANGLES)
          const Text('📸 Daily Physique Photos (3 Angles)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              _photoUploadBox('Face', _face),
              const SizedBox(width: 8),
              _photoUploadBox('Front', _front),
              const SizedBox(width: 8),
              _photoUploadBox('Side', _side),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoUploadBox(String title, XFile? f) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _uploadPhoto(title),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: f != null ? AppColors.accentGreen : AppColors.borderLight, width: 1.2),
            image: f != null && !kIsWeb
                ? DecorationImage(image: FileImage(File(f.path)), fit: BoxFit.cover)
                : null,
          ),
          child: f != null
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '$title ✅',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_rounded, size: 24, color: AppColors.secondary),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const Text('Gallery', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
        ),
      ),
    );
  }
}
