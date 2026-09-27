import 'dart:async';
import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../services/theme_service.dart';
import '../models/workout_models.dart';
import '../widgets/titan_ai_sheet.dart';

class WorkoutPlannerScreen extends StatefulWidget {
  const WorkoutPlannerScreen({super.key});

  @override
  State<WorkoutPlannerScreen> createState() => _WorkoutPlannerScreenState();
}

class _WorkoutPlannerScreenState extends State<WorkoutPlannerScreen> {
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = WorkoutService.instance.currentDayName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workoutService = WorkoutService.instance;

    return AnimatedBuilder(
      animation: workoutService,
      builder: (context, _) {
        final plan = workoutService.plans[_selectedDay] ??
            DayWorkoutPlan(
              id: 'new_$_selectedDay',
              dayName: _selectedDay,
              workoutTitle: 'Rest / Custom Plan',
              primaryMuscle: 'Full Body',
              exercises: [],
            );

        return Scaffold(
          appBar: AppBar(
            title: const Text('7-Day Workout Planner'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Duplicate to another day',
                onPressed: () => _showDuplicateDialog(context, _selectedDay),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Exercise',
                onPressed: () => _showExerciseEditor(context, _selectedDay),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                tooltip: 'AI Coach Advice',
                onPressed: () => TitanAiSheet.show(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // 7-Day Horizontal Selector
              _buildDaySelector(isDark),

              // Active Day Workout Details & Exercise List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Day Overview Card
                    _buildDayHeaderCard(plan, isDark),
                    const SizedBox(height: 16),

                    // Rest Day View or Exercise List
                    if (plan.isRestDay)
                      _buildRestDayPlaceholder(isDark)
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXERCISES (${plan.exercises.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${plan.completedExercises}/${plan.totalExercises} Completed',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeService.primaryEmerald),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (plan.exercises.isEmpty)
                        _buildEmptyExerciseState(isDark)
                      else
                        ...plan.exercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return _buildExerciseCard(exercise, plan, index, isDark);
                        }),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: ThemeService.primaryCyan,
            onPressed: () => _showExerciseEditor(context, _selectedDay),
          ),
        );
      },
    );
  }

  // 1. 7-Day Horizontal Selector
  Widget _buildDaySelector(bool isDark) {
    final currentDay = WorkoutService.instance.currentDayName;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: WorkoutService.weekDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = WorkoutService.weekDays[index];
          final isSelected = day == _selectedDay;
          final isToday = day == currentDay;
          final plan = WorkoutService.instance.plans[day];
          final isDone = plan?.status == WorkoutStatus.completed;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? ThemeService.primaryCyan
                    : isToday
                        ? ThemeService.primaryCyan.withValues(alpha: 0.15)
                        : isDark
                            ? const Color(0xFF0D1117)
                            : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? ThemeService.primaryCyan
                      : isToday
                          ? ThemeService.primaryCyan
                          : isDark
                              ? const Color(0xFF30363D)
                              : const Color(0xFFE2E8F0),
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.black
                              : isToday
                                  ? ThemeService.primaryCyan
                                  : isDark
                                      ? const Color(0xFFF0F6FC)
                                      : const Color(0xFF0F172A),
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: isSelected ? Colors.black : ThemeService.primaryEmerald,
                        ),
                      ],
                    ],
                  ),
                  if (isToday)
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.black87 : ThemeService.primaryCyan,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Day Header Card with Status Dropdown
  Widget _buildDayHeaderCard(DayWorkoutPlan plan, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.workoutTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.primaryMuscle} • ${plan.durationMinutes} mins • ${plan.difficulty.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Status selector pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WorkoutStatus>(
                    value: plan.status,
                    isDense: true,
                    items: WorkoutStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        WorkoutService.instance.setDayStatus(_selectedDay, newStatus);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (plan.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan.notes,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Exercise Card with Integrated Photo
  Widget _buildExerciseCard(ExerciseItem exercise, DayWorkoutPlan plan, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exercise.isCompleted
              ? ThemeService.primaryEmerald.withValues(alpha: 0.5)
              : isDark
                  ? const Color(0xFF30363D)
                  : const Color(0xFFE2E8F0),
          width: exercise.isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showExerciseDetailModal(context, exercise, plan),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Exercise Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 68,
                  height: 68,
                  color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                  child: Image.network(
                    exercise.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 28, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Sets/Reps
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: exercise.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.sets} sets × ${exercise.reps} reps  •  ${exercise.weightKg > 0 ? "${exercise.weightKg}kg" : "BW"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ThemeService.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.muscleGroup} • Rest ${exercise.restSeconds}s',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Complete Toggle Button
              IconButton(
                icon: Icon(
                  exercise.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: exercise.isCompleted ? ThemeService.primaryEmerald : Colors.grey,
                  size: 26,
                ),
                onPressed: () {
                  WorkoutService.instance.toggleExerciseCompletion(plan.dayName, exercise.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Exercise Detail View Modal with Rest Countdown Timer
  void _showExerciseDetailModal(BuildContext context, ExerciseItem exercise, DayWorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseDetailSheet(exercise: exercise, plan: plan),
    );
  }

  // 5. Exercise Editor / Creator Modal
  void _showExerciseEditor(BuildContext context, String dayName, [ExerciseItem? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final muscleCtrl = TextEditingController(text: existing?.muscleGroup ?? 'Chest');
    final equipCtrl = TextEditingController(text: existing?.equipment ?? 'Dumbbells');
    final setsCtrl = TextEditingController(text: existing?.sets.toString() ?? '3');
    final repsCtrl = TextEditingController(text: existing?.reps.toString() ?? '10');
    final weightCtrl = TextEditingController(text: existing?.weightKg.toString() ?? '20.0');
    final restCtrl = TextEditingController(text: existing?.restSeconds.toString() ?? '60');
    final instCtrl = TextEditingController(text: existing?.instructions ?? '');
    final photoCtrl = TextEditingController(text: existing?.photoUrl ?? 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing != null ? 'Edit Exercise' : 'Add Exercise to $dayName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'Muscle Group'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: equipCtrl, decoration: const InputDecoration(labelText: 'Equipment'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: setsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sets'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: restCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rest (s)'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: instCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions / Form Cues')),
                const SizedBox(height: 10),
                TextField(controller: photoCtrl, decoration: const InputDecoration(labelText: 'Photo / Image URL')),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    final item = ExerciseItem(
                      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Exercise',
                      muscleGroup: muscleCtrl.text.trim(),
                      equipment: equipCtrl.text.trim(),
                      sets: int.tryParse(setsCtrl.text) ?? 3,
                      reps: int.tryParse(repsCtrl.text) ?? 10,
                      weightKg: double.tryParse(weightCtrl.text) ?? 0.0,
                      restSeconds: int.tryParse(restCtrl.text) ?? 60,
                      instructions: instCtrl.text.trim(),
                      photoUrl: photoCtrl.text.trim(),
                    );

                    if (existing != null) {
                      WorkoutService.instance.updateExercise(dayName, item);
                    } else {
                      WorkoutService.instance.addExerciseToDay(dayName, item);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(existing != null ? 'Update Exercise' : 'Save to $dayName'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDuplicateDialog(BuildContext context, String currentDay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Duplicate $currentDay Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WorkoutService.weekDays.where((d) => d != currentDay).map((targetDay) {
            return ListTile(
              title: Text('Copy to $targetDay'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                WorkoutService.instance.duplicateDayPlan(currentDay, targetDay);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied $currentDay plan to $targetDay!')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRestDayPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.nightlight_round, size: 48, color: ThemeService.primaryCyan.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          const Text('Rest & Recovery Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Muscles grow during rest. Focus on clean protein intake, hydration, and sleep.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExerciseState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('No exercises added yet. Tap "Add Exercise" to customize this workout.'),
      ),
    );
  }

  Color _getStatusColor(WorkoutStatus s) {
    switch (s) {
      case WorkoutStatus.completed:
        return ThemeService.primaryEmerald;
      case WorkoutStatus.inProgress:
        return ThemeService.primaryCyan;
      case WorkoutStatus.skipped:
        return Colors.redAccent;
      case WorkoutStatus.restDay:
        return Colors.orangeAccent;
      case WorkoutStatus.planned:
        return Colors.grey;
    }
  }
}

// Interactive Exercise Detail Sheet with Rest Timer
class _ExerciseDetailSheet extends StatefulWidget {
  final ExerciseItem exercise;
  final DayWorkoutPlan plan;

  const _ExerciseDetailSheet({required this.exercise, required this.plan});

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.exercise.restSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        t.cancel();
        setState(() {
          _isTimerRunning = false;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = widget.exercise.restSeconds;
      _isTimerRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ex = widget.exercise;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Exercise Photo Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      ex.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                        child: const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Name & Target Muscle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${ex.muscleGroup} ${ex.secondaryMuscle.isNotEmpty ? "• Secondary: ${ex.secondaryMuscle}" : ""}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        WorkoutService.instance.deleteExercise(widget.plan.dayName, ex.id);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Specs Matrix
                Row(
                  children: [
                    _specBadge('Sets', '${ex.sets}', isDark),
                    const SizedBox(width: 8),
                    _specBadge('Reps', '${ex.reps}', isDark),
                    const SizedBox(width: 8),
                    _specBadge('Weight', ex.weightKg > 0 ? '${ex.weightKg} kg' : 'BW', isDark),
                    const SizedBox(width: 8),
                    _specBadge('Equipment', ex.equipment, isDark),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Instructions
                const Text('FORM INSTRUCTIONS & BIOMECHANICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    ex.instructions.isNotEmpty ? ex.instructions : 'Perform reps smoothly through a full range of motion. Keep tension continuous without locking joints abruptly.',
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
                const SizedBox(height: 20),

                // Rest Countdown Timer Widget
                const Text('INTER-SET REST COUNTDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ThemeService.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_secondsLeft}s',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ThemeService.primaryCyan),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_isTimerRunning ? Icons.pause_circle : Icons.play_circle, size: 36, color: ThemeService.primaryCyan),
                        onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                      ),
                      IconButton(
                        icon: const Icon(Icons.restart_alt, size: 28),
                        onPressed: _resetTimer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specBadge(String label, String val, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
