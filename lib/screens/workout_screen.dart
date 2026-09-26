import 'package:flutter/material.dart';
import '../models/workout_template_models.dart';
import '../services/gemini_service.dart';
import '../main.dart';

class WorkoutScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const WorkoutScreen({super.key, this.onBack});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<WorkoutSplitDay> _splits = WorkoutPresetSplits.weeklyHypertrophySplit;
  final Map<String, Set<String>> _completedExercisesByDay = {};
  bool _isAiOptimizing = false;

  @override
  void initState() {
    super.initState();
    // Default to today's weekday index (0 = Monday, ..., 6 = Sunday)
    final todayIdx = (DateTime.now().weekday - 1) % 7;
    _tabController = TabController(length: 7, vsync: this, initialIndex: todayIdx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleExercise(String dayName, String exerciseName) {
    setState(() {
      final set = _completedExercisesByDay.putIfAbsent(dayName, () => <String>{});
      if (set.contains(exerciseName)) {
        set.remove(exerciseName);
      } else {
        set.add(exerciseName);
      }
    });
  }

  Future<void> _askAiForSplitOptimization(WorkoutSplitDay day) async {
    setState(() {
      _isAiOptimizing = true;
    });

    final prompt = '''
As Titan Head Strength Coach, analyze and optimize this training routine:
Day: ${day.dayName}
Target Muscle: ${day.targetMuscle}
Description: ${day.description}
Exercises: ${day.exercises.map((e) => "${e.name} (${e.defaultSets}x${e.defaultReps})").join(', ')}

Please provide:
1. Warmup & Activation Protocol (3 min)
2. Progressive Overload Strategy for peak hypertrophy
3. Form Cues & Eccentric Tempo advice
4. Post-workout recovery tip
Keep it crisp, actionable, and formatted with bullet points.
''';

    final advice = await GeminiService.instance.askAi(prompt);
    if (mounted) {
      setState(() {
        _isAiOptimizing = false;
      });
      _showAiAdviceDialog(day.dayName, advice);
    }
  }

  void _showAiAdviceDialog(String dayName, String advice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primaryGlow, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Routine: $dayName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            advice,
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.45),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Execute Routine 💪', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          '7-DAY GYM SPLITS & VOLUME',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mon • Chest'),
            Tab(text: 'Tue • Back'),
            Tab(text: 'Wed • Shoulders'),
            Tab(text: 'Thu • Legs'),
            Tab(text: 'Fri • Arms'),
            Tab(text: 'Sat • Hamstrings'),
            Tab(text: 'Sun • Recovery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _splits.map((day) => _buildDayView(day)).toList(),
      ),
    );
  }

  Widget _buildDayView(WorkoutSplitDay day) {
    final completedSet = _completedExercisesByDay[day.dayName] ?? <String>{};
    final total = day.exercises.length;
    final done = completedSet.length;
    final progress = total > 0 ? done / total : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Day Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentBlue.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.dayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.targetMuscle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.accentBlue,
                      side: const BorderSide(color: AppColors.accentBlue, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _isAiOptimizing ? null : () => _askAiForSplitOptimization(day),
                    icon: _isAiOptimizing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('AI Optimizer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                day.description,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$done of $total Exercises Completed',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% Done',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentBlue),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'EXERCISE PROTOCOLS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),

        // List of exercises
        ...day.exercises.map((ex) {
          final isDone = completedSet.contains(ex.name);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDone ? AppColors.accentBlue.withValues(alpha: 0.1) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone ? AppColors.accentBlue.withValues(alpha: 0.6) : AppColors.borderLight,
                width: isDone ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: GestureDetector(
                onTap: () => _toggleExercise(day.dayName, ex.name),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.accentBlue : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? AppColors.accentBlue : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              title: Text(
                ex.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDone ? Colors.white70 : Colors.white,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                '${ex.defaultSets} Sets × ${ex.defaultReps} Reps • ${ex.muscleGroup}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '${ex.defaultSets * ex.defaultReps} Reps',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
