import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/workout_template_models.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _dayTabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  Map<String, WorkoutDayPlan> _workoutPlans = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (1 = Monday, 7 = Sunday)
    final todayWeekday = (DateTime.now().weekday - 1).clamp(0, 6);
    _dayTabController = TabController(
      length: _days.length,
      initialIndex: todayWeekday,
      vsync: this,
    );
    _loadWorkoutPlans();
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await DBHelper.instance.getWorkoutPlans();
      if (plans.isEmpty) {
        final defaults = WorkoutTemplateModels.getDefault7DayPlan();
        for (var plan in defaults) {
          await DBHelper.instance.saveWorkoutPlan(plan);
        }
        final reloaded = await DBHelper.instance.getWorkoutPlans();
        _workoutPlans = {for (var p in reloaded) p.dayName: p};
      } else {
        _workoutPlans = {for (var p in plans) p.dayName: p};
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  WorkoutDayPlan _getCurrentDayPlan(String dayName) {
    return _workoutPlans[dayName] ??
        WorkoutDayPlan(
          id: 'custom_$dayName',
          dayName: dayName,
          workoutName: '$dayName Workout',
          muscleGroup: 'Full Body',
          status: WorkoutStatus.planned,
          estimatedDurationMinutes: 45,
          difficulty: 'Intermediate',
          exercises: [],
        );
  }

  Future<void> _updateDayStatus(String dayName, WorkoutStatus newStatus) async {
    final current = _getCurrentDayPlan(dayName);
    final updated = current.copyWith(
      status: newStatus,
      completedAt: newStatus == WorkoutStatus.completed ? DateTime.now() : null,
    );
    setState(() {
      _workoutPlans[dayName] = updated;
    });
    await DBHelper.instance.saveWorkoutPlan(updated);

    if (newStatus == WorkoutStatus.completed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Awesome job! $dayName workout marked as Completed!'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openExerciseDetailModal(ExerciseDetail exercise, String dayName, int exerciseIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseDetailSheet(
        exercise: exercise,
        onSave: (updatedExercise) async {
          final plan = _getCurrentDayPlan(dayName);
          final updatedExercises = List<ExerciseDetail>.from(plan.exercises);
          updatedExercises[exerciseIndex] = updatedExercise;
          final updatedPlan = plan.copyWith(exercises: updatedExercises);
          setState(() {
            _workoutPlans[dayName] = updatedPlan;
          });
          await DBHelper.instance.saveWorkoutPlan(updatedPlan);
        },
      ),
    );
  }

  void _editWorkoutHeaderDialog(String dayName) {
    final plan = _getCurrentDayPlan(dayName);
    final nameCtrl = TextEditingController(text: plan.workoutName);
    final muscleCtrl = TextEditingController(text: plan.muscleGroup);
    final durationCtrl = TextEditingController(text: plan.estimatedDurationMinutes.toString());
    String difficulty = plan.difficulty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Edit $dayName Workout', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Workout Title (e.g. Push Power)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: muscleCtrl,
                  decoration: const InputDecoration(labelText: 'Target Muscle Group (e.g. Chest & Triceps)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimated Duration (Minutes)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                  items: ['Beginner', 'Intermediate', 'Advanced'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => difficulty = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final updated = plan.copyWith(
                  workoutName: nameCtrl.text.trim().isEmpty ? plan.workoutName : nameCtrl.text.trim(),
                  muscleGroup: muscleCtrl.text.trim().isEmpty ? plan.muscleGroup : muscleCtrl.text.trim(),
                  estimatedDurationMinutes: int.tryParse(durationCtrl.text) ?? plan.estimatedDurationMinutes,
                  difficulty: difficulty,
                );
                setState(() {
                  _workoutPlans[dayName] = updated;
                });
                await DBHelper.instance.saveWorkoutPlan(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addExerciseDialog(String dayName) {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();
    final equipCtrl = TextEditingController(text: 'Dumbbells / Barbell');
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController(text: '20');
    final restCtrl = TextEditingController(text: '60');
    final instructionsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Exercise Name (e.g. Incline Bench Press)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: muscleCtrl,
                decoration: const InputDecoration(labelText: 'Target Muscle (e.g. Upper Chest)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: equipCtrl,
                decoration: const InputDecoration(labelText: 'Equipment (e.g. Dumbbells / Bodyweight)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sets', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: restCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rest (sec)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Form instructions & cues', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final plan = _getCurrentDayPlan(dayName);
              final newExercise = ExerciseDetail(
                id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                targetMuscle: muscleCtrl.text.trim().isEmpty ? 'General' : muscleCtrl.text.trim(),
                equipment: equipCtrl.text.trim(),
                sets: int.tryParse(setsCtrl.text) ?? 3,
                reps: int.tryParse(repsCtrl.text) ?? 10,
                weightKg: double.tryParse(weightCtrl.text) ?? 0,
                restSeconds: int.tryParse(restCtrl.text) ?? 60,
                instructions: instructionsCtrl.text.trim().isEmpty ? 'Keep a tight core and focus on controlled contraction.' : instructionsCtrl.text.trim(),
                photoUrl: WorkoutTemplateModels.getIllustrationForExercise(name),
              );

              final updatedExercises = List<ExerciseDetail>.from(plan.exercises)..add(newExercise);
              final updatedPlan = plan.copyWith(exercises: updatedExercises);
              setState(() {
                _workoutPlans[dayName] = updatedPlan;
              });
              await DBHelper.instance.saveWorkoutPlan(updatedPlan);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Exercise', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _duplicateWorkoutToAnotherDay(String sourceDay) {
    String targetDay = _days.firstWhere((d) => d != sourceDay);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Duplicate $sourceDay Workout', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Copy exercises, sets, and configuration from $sourceDay to another day:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: targetDay,
                decoration: const InputDecoration(labelText: 'Target Day', border: OutlineInputBorder()),
                items: _days.where((d) => d != sourceDay).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => targetDay = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final sourcePlan = _getCurrentDayPlan(sourceDay);
                final duplicatedPlan = sourcePlan.copyWith(
                  id: 'plan_${targetDay.toLowerCase()}',
                  dayName: targetDay,
                  workoutName: '${sourcePlan.workoutName} (Copy)',
                  status: WorkoutStatus.planned,
                );
                setState(() {
                  _workoutPlans[targetDay] = duplicatedPlan;
                });
                await DBHelper.instance.saveWorkoutPlan(duplicatedPlan);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied workout to $targetDay!'), backgroundColor: AppColors.accentGreen),
                  );
                }
              },
              child: const Text('Duplicate', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _moveWorkoutToAnotherDay(String sourceDay) {
    String targetDay = _days.firstWhere((d) => d != sourceDay);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Move $sourceDay Workout', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move this workout to another day (and make $sourceDay a Rest Day):'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: targetDay,
                decoration: const InputDecoration(labelText: 'Move To Day', border: OutlineInputBorder()),
                items: _days.where((d) => d != sourceDay).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => targetDay = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
              onPressed: () async {
                final sourcePlan = _getCurrentDayPlan(sourceDay);
                final movedPlan = sourcePlan.copyWith(
                  id: 'plan_${targetDay.toLowerCase()}',
                  dayName: targetDay,
                );
                final emptySource = WorkoutDayPlan(
                  id: 'plan_${sourceDay.toLowerCase()}',
                  dayName: sourceDay,
                  workoutName: 'Rest & Active Recovery',
                  muscleGroup: 'Rest Day',
                  status: WorkoutStatus.restDay,
                  estimatedDurationMinutes: 0,
                  difficulty: 'Beginner',
                  exercises: [],
                );

                setState(() {
                  _workoutPlans[targetDay] = movedPlan;
                  _workoutPlans[sourceDay] = emptySource;
                });
                await DBHelper.instance.saveWorkoutPlan(movedPlan);
                await DBHelper.instance.saveWorkoutPlan(emptySource);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Moved workout from $sourceDay to $targetDay!'), backgroundColor: AppColors.accentGreen),
                  );
                }
              },
              child: const Text('Move Workout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekday = (DateTime.now().weekday - 1).clamp(0, 6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Day Workout Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Split',
            onPressed: _loadWorkoutPlans,
          ),
        ],
        bottom: TabBar(
          controller: _dayTabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: _days.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;
            final isToday = idx == todayWeekday;

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.substring(0, 3),
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: isToday ? AppColors.primaryGlow : null,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _dayTabController,
              children: _days.asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                final isToday = idx == todayWeekday;
                final plan = _getCurrentDayPlan(day);
                return _buildDayView(day, plan, isToday);
              }).toList(),
            ),
    );
  }

  Widget _buildDayView(String dayName, WorkoutDayPlan plan, bool isToday) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today badge & day header card
          _buildDayHeaderCard(dayName, plan, isToday),
          const SizedBox(height: 16),

          // Exercise list header with Add Exercise & Reorder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Exercises (${plan.exercises.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                tooltip: 'Add Exercise',
                onPressed: () => _addExerciseDialog(dayName),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Exercises List
          if (plan.exercises.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.bedtime_rounded, size: 48, color: theme.hintColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    plan.status == WorkoutStatus.restDay ? 'Scheduled Rest & Recovery Day' : 'No exercises planned for $dayName',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Add an Exercise', style: TextStyle(color: Colors.white)),
                    onPressed: () => _addExerciseDialog(dayName),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = plan.exercises[index];
                return _buildExerciseCard(exercise, dayName, index, ValueKey(exercise.id));
              },
            ),

          const SizedBox(height: 24),
          // Actions bar: Duplicate / Move / Delete
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Duplicate'),
                  onPressed: () => _duplicateWorkoutToAnotherDay(dayName),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.move_down_rounded, size: 16),
                  label: const Text('Move Day'),
                  onPressed: () => _moveWorkoutToAnotherDay(dayName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDayHeaderCard(String dayName, WorkoutDayPlan plan, bool isToday) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return GlassCard(
      borderRadius: 20,
      border: Border.all(
        color: isToday ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: isToday ? 2 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isToday ? AppColors.primary : AppColors.textSecondary(isDark),
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TODAY', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: Icon(Icons.edit_note_rounded, size: 22, color: AppColors.textSecondary(isDark)),
                tooltip: 'Edit Workout Info',
                onPressed: () => _editWorkoutHeaderDialog(dayName),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.workoutName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.bubble_chart_rounded, size: 14, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 4),
              Text(plan.muscleGroup, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 4),
              Text('~${plan.estimatedDurationMinutes} mins', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Icon(Icons.speed_rounded, size: 14, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 4),
              Text(plan.difficulty, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),

          // Status Selector Chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary(isDark))),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: WorkoutStatus.values.map((st) {
                      final isSelected = plan.status == st;
                      final col = WorkoutModels.getStatusColor(st);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          label: Text(WorkoutModels.getStatusLabel(st), style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : AppColors.textPrimary(isDark), fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: col,
                          onSelected: (val) {
                            if (val) _updateDayStatus(dayName, st);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseDetail exercise, String dayName, int index, Key key) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return GlassCard(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      onTap: () => _openExerciseDetailModal(exercise, dayName, index),
      child: Row(
        children: [
          // Exercise illustration / icon thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              child: Center(
                child: Text(
                  exercise.photoUrl,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.targetMuscle} • ${exercise.equipment}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${exercise.sets} sets × ${exercise.reps} reps',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    if (exercise.weightKg > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${exercise.weightKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      '${exercise.restSeconds}s rest',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
            onPressed: () async {
              final plan = _getCurrentDayPlan(dayName);
              final updatedExercises = List<ExerciseDetail>.from(plan.exercises)..removeAt(index);
              final updatedPlan = plan.copyWith(exercises: updatedExercises);
              setState(() {
                _workoutPlans[dayName] = updatedPlan;
              });
              await DBHelper.instance.saveWorkoutPlan(updatedPlan);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- EXERCISE DETAIL BOTTOM SHEET WITH INTERACTIVE REST TIMER ----------------
class _ExerciseDetailSheet extends StatefulWidget {
  final ExerciseDetail exercise;
  final Function(ExerciseDetail) onSave;

  const _ExerciseDetailSheet({required this.exercise, required this.onSave});

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  late ExerciseDetail _ex;
  Timer? _restTimer;
  int _secondsRemaining = 0;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    _ex = widget.exercise;
    if (_ex.completedSets.length != _ex.sets) {
      _ex = _ex.copyWith(
        completedSets: List.generate(_ex.sets, (i) => i < _ex.completedSets.length ? _ex.completedSets[i] : false),
      );
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int durationSeconds) {
    _restTimer?.cancel();
    setState(() {
      _secondsRemaining = durationSeconds;
      _isTimerActive = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isTimerActive = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏱️ Rest timer complete! Ready for your next set!'),
              backgroundColor: AppColors.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _pauseRestTimer() {
    _restTimer?.cancel();
    setState(() => _isTimerActive = false);
  }

  void _resetRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _secondsRemaining = 0;
      _isTimerActive = false;
    });
  }

  void _toggleSetCompletion(int setIndex) {
    final updated = List<bool>.from(_ex.completedSets);
    updated[setIndex] = !updated[setIndex];
    final newEx = _ex.copyWith(completedSets: updated);
    setState(() => _ex = newEx);
    widget.onSave(newEx);

    if (updated[setIndex]) {
      _startRestTimer(_ex.restSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Illustration & Title
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(_ex.photoUrl, style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ex.name,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                            ),
                            const SizedBox(height: 4),
                            Text('Primary: ${_ex.targetMuscle}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                            if (_ex.secondaryMuscles.isNotEmpty)
                              Text('Secondary: ${_ex.secondaryMuscles}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rest Timer Widget
                  GlassCard(
                    borderRadius: 18,
                    border: Border.all(
                      color: _isTimerActive ? AppColors.accentAmber : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_isTimerActive ? AppColors.accentAmber : AppColors.primary).withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTimerActive ? Icons.timer_outlined : Icons.timer_rounded,
                            color: _isTimerActive ? AppColors.accentAmber : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTimerActive ? 'Resting: ${_secondsRemaining}s' : 'Rest Timer (${_ex.restSeconds}s)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                              ),
                              Text(
                                _isTimerActive ? 'Take deep breaths & prepare.' : 'Auto-starts after each set',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(isDark)),
                              ),
                            ],
                          ),
                        ),
                        if (_isTimerActive) ...[
                          IconButton(
                            icon: Icon(Icons.pause_rounded, color: AppColors.textPrimary(isDark)),
                            onPressed: _pauseRestTimer,
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: AppColors.textPrimary(isDark)),
                            onPressed: _resetRestTimer,
                          ),
                        ] else ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () => _startRestTimer(_ex.restSeconds),
                            child: const Text('Start Rest'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sets Checklist & Weights
                  const Text('Set Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ex.sets,
                    itemBuilder: (context, setIdx) {
                      final isDone = setIdx < _ex.completedSets.length && _ex.completedSets[setIdx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.accentGreen.withValues(alpha: 0.12) : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDone ? AppColors.accentGreen.withValues(alpha: 0.4) : theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Set ${setIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 12),
                                Text(
                                  '${_ex.reps} reps @ ${_ex.weightKg.toStringAsFixed(0)} kg',
                                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isDone ? AppColors.accentGreen : theme.hintColor,
                              ),
                              onPressed: () => _toggleSetCompletion(setIdx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Instructions & Technique cues
                  const Text('Form & Execution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_ex.instructions, style: TextStyle(fontSize: 13.5, color: theme.hintColor, height: 1.4)),
                  ),
                  const SizedBox(height: 20),

                  // Previous & Personal Records
                  if (_ex.previousPerformance != null) ...[
                    const Text('Previous Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(_ex.previousPerformance!, style: TextStyle(fontSize: 13, color: theme.hintColor)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
