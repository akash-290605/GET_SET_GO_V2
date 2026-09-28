import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/workout_template_models.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class WorkoutScreen extends StatefulWidget {
  final int initialTabIndex;
  const WorkoutScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final List<String> _days = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  Map<String, WorkoutDayPlan> _workoutPlans = {};
  List<WorkoutSession> _historySessions = [];
  Map<String, PersonalRecord> _personalRecords = {};
  bool _isLoading = true;

  // Builder selected day (0 = Monday, 6 = Sunday)
  int _selectedBuilderDayIndex = 0;

  // Live Workout Session State
  bool _isLiveSessionActive = false;
  DateTime? _liveSessionStartTime;
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  WorkoutDayPlan? _activeLivePlan;
  List<ExerciseDetail> _activeLiveExercises = [];
  final Map<String, List<WorkoutSetRecord>> _liveSetRecords = {}; // exerciseId -> List<WorkoutSetRecord>

  // Rest Timer State
  Timer? _restCountdownTimer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 60;
  bool _isRestTimerRunning = false;
  String _currentRestingExercise = '';

  @override
  void initState() {
    super.initState();
    final todayWeekday = (DateTime.now().weekday - 1).clamp(0, 6);
    _selectedBuilderDayIndex = todayWeekday;
    _mainTabController = TabController(length: 4, initialIndex: widget.initialTabIndex, vsync: this);
    _loadAllWorkoutData();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _restCountdownTimer?.cancel();
    _mainTabController.dispose();
    super.dispose();
  }

  String get _currentDayName {
    final weekday = (DateTime.now().weekday - 1).clamp(0, 6);
    return _days[weekday];
  }

  String get _formattedTodayDate {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }

  Future<void> _loadAllWorkoutData() async {
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

      final sessions = await DBHelper.instance.getWorkoutSessions();
      final prs = await DBHelper.instance.getPersonalRecords();

      if (mounted) {
        setState(() {
          _historySessions = sessions;
          _personalRecords = prs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  WorkoutDayPlan _getDayPlan(String dayName) {
    return _workoutPlans[dayName] ??
        WorkoutDayPlan(
          id: 'plan_${dayName.toLowerCase()}',
          dayName: dayName,
          workoutName: '$dayName Workout',
          muscleGroup: 'Full Body',
          status: WorkoutStatus.planned,
          estimatedDurationMinutes: 45,
          difficulty: 'Intermediate',
          exercises: [],
        );
  }

  // ================= LIVE WORKOUT EXECUTION =================
  void _startLiveWorkout(WorkoutDayPlan plan) {
    if (plan.isRestDay || plan.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Today is a scheduled Rest Day! Enjoy your recovery.'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Initialize actual set records for each exercise
    _liveSetRecords.clear();
    for (final ex in plan.exercises) {
      _liveSetRecords[ex.id] = List.generate(
        ex.sets,
        (idx) => WorkoutSetRecord(
          setNumber: idx + 1,
          reps: ex.reps,
          weightKg: ex.weightKg,
          durationSeconds: ex.targetDurationSeconds,
          isCompleted: false,
          isBodyweight: ex.isBodyweight,
          isTimeBased: ex.isTimeBased,
        ),
      );
    }

    setState(() {
      _isLiveSessionActive = true;
      _liveSessionStartTime = DateTime.now();
      _elapsedSeconds = 0;
      _activeLivePlan = plan;
      _activeLiveExercises = List<ExerciseDetail>.from(plan.exercises);
    });

    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _pauseResumeStopwatch() {
    if (_stopwatchTimer != null && _stopwatchTimer!.isActive) {
      _stopwatchTimer!.cancel();
      setState(() {});
    } else {
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
      setState(() {});
    }
  }

  String _formatTimerTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return totalSeconds >= 3600 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _startRestCountdown(int seconds, String exerciseName) {
    _restCountdownTimer?.cancel();
    setState(() {
      _restTotalSeconds = seconds > 0 ? seconds : 60;
      _restSecondsRemaining = _restTotalSeconds;
      _isRestTimerRunning = true;
      _currentRestingExercise = exerciseName;
    });

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 1) {
        if (mounted) setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _restSecondsRemaining = 0;
            _isRestTimerRunning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Rest time over for $exerciseName! Next set ready!'),
              backgroundColor: AppColors.accentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _cancelRestCountdown() {
    _restCountdownTimer?.cancel();
    setState(() {
      _isRestTimerRunning = false;
      _restSecondsRemaining = 0;
    });
  }

  void _toggleLiveSetCompletion(String exerciseId, int setIndex, int restSec, String exerciseName) {
    final sets = _liveSetRecords[exerciseId];
    if (sets == null || setIndex >= sets.length) return;

    final cur = sets[setIndex];
    final wasCompleted = cur.isCompleted;
    sets[setIndex] = cur.copyWith(
      isCompleted: !wasCompleted,
      completedAt: !wasCompleted ? DateTime.now() : null,
    );

    setState(() {});

    if (!wasCompleted) {
      _startRestCountdown(restSec, exerciseName);
    }
  }

  // Finish Workout & Calculate Progressive Overload Suggestions
  Future<void> _finishLiveWorkoutPrompt() async {
    final plan = _activeLivePlan;
    if (plan == null) return;

    final durationMins = (_elapsedSeconds / 60).ceil().clamp(1, 999);
    final todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Build immutable session record
    final List<ExerciseSessionRecord> sessionExercises = [];
    final List<ProgressionSuggestion> suggestions = [];

    for (final ex in _activeLiveExercises) {
      final actualSets = _liveSetRecords[ex.id] ?? [];
      final completedSets = actualSets.where((s) => s.isCompleted).toList();

      sessionExercises.add(
        ExerciseSessionRecord(
          exerciseId: ex.id,
          exerciseName: ex.name,
          targetMuscle: ex.targetMuscle,
          isBodyweight: ex.isBodyweight,
          isTimeBased: ex.isTimeBased,
          plannedSets: ex.sets,
          plannedReps: ex.reps,
          plannedWeightKg: ex.weightKg,
          plannedDurationSeconds: ex.targetDurationSeconds,
          actualSets: actualSets,
          notes: ex.notes,
          previousPerformanceSummary: ex.previousPerformance,
        ),
      );

      // Generate Progressive Overload suggestion if sets were completed
      if (completedSets.isNotEmpty) {
        final suggestion = WorkoutTemplateModels.calculateProgressionSuggestion(ex);
        suggestions.add(suggestion);
      }
    }

    final session = WorkoutSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: AuthService.instance.uid,
      date: todayDateStr,
      dayName: plan.dayName,
      workoutTemplateId: plan.id,
      workoutVersion: plan.version,
      workoutName: plan.workoutName,
      muscleGroup: plan.muscleGroup,
      startTime: _liveSessionStartTime ?? DateTime.now(),
      endTime: DateTime.now(),
      durationMinutes: durationMins,
      exercises: sessionExercises,
      status: WorkoutStatus.completed,
      comments: 'Logged live via stopwatch (${_formatTimerTime(_elapsedSeconds)})',
    );

    // Save immutable session record to DB
    await DBHelper.instance.saveWorkoutSession(session);

    // Stop timers
    _stopwatchTimer?.cancel();
    _restCountdownTimer?.cancel();

    setState(() {
      _isLiveSessionActive = false;
      _isRestTimerRunning = false;
      _workoutPlans[plan.dayName] = plan.copyWith(status: WorkoutStatus.completed, completedAt: DateTime.now());
    });

    // Update plan status in database
    await DBHelper.instance.saveWorkoutPlan(_workoutPlans[plan.dayName]!);
    await _loadAllWorkoutData();

    if (!mounted) return;

    // Show Progressive Overload Acceptance Dialog
    _showProgressiveOverloadSummaryModal(session, suggestions);
  }

  void _showProgressiveOverloadSummaryModal(WorkoutSession session, List<ProgressionSuggestion> suggestions) {
    final isDark = ThemeService.instance.isDarkMode(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppColors.accentGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WORKOUT FINISHED!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('Progressive Overload Targets', style: TextStyle(fontSize: 11, color: AppColors.accentAmber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat('Duration', '${session.durationMinutes} min', Icons.timer_outlined, AppColors.primary, isDark),
                        _buildSummaryStat('Sets Done', '${session.totalSetsCompleted}', Icons.fitness_center_rounded, AppColors.accentGreen, isDark),
                        _buildSummaryStat('Exercises', '${session.completedExercisesCount}/${session.totalExercisesCount}', Icons.check_circle_outline, AppColors.secondary, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Smart Next Session Targets:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Would you like to upgrade future templates with these overload targets?',
                    style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),

                  if (suggestions.isEmpty)
                    Text('Great workout logged! Keep maintaining your form.', style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor))
                  else
                    ...suggestions.map((sug) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    sug.exerciseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentAmber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+ PROGRESSION',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next Goal: ${sug.targetDisplay}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sug.reason,
                              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Same'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                // Apply Progressive Overload to future template for this day
                final plan = _getDayPlan(session.dayName);
                final updatedExercises = List<ExerciseDetail>.from(plan.exercises);

                for (final sug in suggestions) {
                  final exIdx = updatedExercises.indexWhere((e) => e.name.toLowerCase() == sug.exerciseName.toLowerCase());
                  if (exIdx != -1) {
                    final old = updatedExercises[exIdx];
                    final oldPerf = 'Last session: ${old.sets} × ${old.reps}${old.weightKg > 0 ? " @ ${old.weightKg.toStringAsFixed(1)} kg" : ""}';
                    updatedExercises[exIdx] = old.copyWith(
                      reps: sug.suggestedReps,
                      weightKg: sug.suggestedWeightKg,
                      targetDurationSeconds: sug.suggestedDurationSeconds,
                      previousPerformance: oldPerf,
                    );
                  }
                }

                final updatedPlan = plan.copyWith(
                  version: plan.version + 1,
                  exercises: updatedExercises,
                );

                await DBHelper.instance.saveWorkoutPlan(updatedPlan);
                await _loadAllWorkoutData();

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚀 ${session.dayName} template upgraded with progressive overload!'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                }
              },
              child: const Text('Accept Next Target (Overload)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10.5, color: Theme.of(context).hintColor)),
      ],
    );
  }

  // ================= MAIN BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Workout & Progressive Overload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Plans',
            onPressed: _loadAllWorkoutData,
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).hintColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded, size: 18), text: "Today's Workout"),
            Tab(icon: Icon(Icons.view_week_rounded, size: 18), text: "7-Day Split"),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: "History"),
            Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: "PRs & Progress"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                TabBarView(
                  controller: _mainTabController,
                  children: [
                    // TAB 1: Today's Auto-Fetched Workout
                    _buildTodayAutoWorkoutTab(isDark),

                    // TAB 2: Workout Builder & 7-Day Plan
                    _buildWorkoutBuilderTab(isDark),

                    // TAB 3: Immutable Workout History Logs
                    _buildWorkoutHistoryTab(isDark),

                    // TAB 4: PRs & Progressive Overload Metrics
                    _buildProgressAndPRsTab(isDark),
                  ],
                ),

                // Floating Rest Timer Widget (if running)
                if (_isRestTimerRunning) _buildFloatingRestTimerOverlay(isDark),
              ],
            ),
    );
  }

  // ================= TAB 1: TODAY'S AUTO WORKOUT =================
  Widget _buildTodayAutoWorkoutTab(bool isDark) {
    final todayDayName = _currentDayName;
    final plan = _getDayPlan(todayDayName);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner: Today Date & Day Info
          GlassCard(
            borderRadius: 20,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.primary.withValues(alpha: 0.22), AppColors.secondary.withValues(alpha: 0.10)]
                  : [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TODAY • ${todayDayName.toUpperCase()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                      ),
                    ),
                    Text(
                      _formattedTodayDate,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plan.workoutName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary(isDark)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(plan.muscleGroup, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('~${plan.estimatedDurationMinutes} mins', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Workout Stopwatch Control Bar
                if (_isLiveSessionActive) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.accentAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LIVE WORKOUT IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                                Text(
                                  _formatTimerTime(_elapsedSeconds),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(_stopwatchTimer != null && _stopwatchTimer!.isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 28, color: AppColors.accentAmber),
                              tooltip: 'Pause / Resume',
                              onPressed: _pauseResumeStopwatch,
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _finishLiveWorkoutPrompt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (plan.isRestDay)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bedtime_rounded, color: AppColors.accentPurple, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Rest Day — Recovery is part of the plan. Hydrate, stretch, and get quality sleep.',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Start Workout Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () => _startLiveWorkout(plan),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Exercise List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises (${plan.exercises.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!_isLiveSessionActive && !plan.isRestDay)
                TextButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Customize in Builder', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _selectedBuilderDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
                      _mainTabController.animateTo(1);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Exercise Cards
          if (plan.exercises.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No exercises configured for $todayDayName.', style: TextStyle(color: Theme.of(context).hintColor)),
              ),
            )
          else
            ...plan.exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final ex = entry.value;
              return _buildTodayExerciseCard(ex, idx, isDark);
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTodayExerciseCard(ExerciseDetail ex, int index, bool isDark) {
    final sets = _liveSetRecords[ex.id] ??
        List.generate(
          ex.sets,
          (i) => WorkoutSetRecord(
            setNumber: i + 1,
            reps: ex.reps,
            weightKg: ex.weightKg,
            durationSeconds: ex.targetDurationSeconds,
            isCompleted: false,
            isBodyweight: ex.isBodyweight,
            isTimeBased: ex.isTimeBased,
          ),
        );

    final completedCount = sets.where((s) => s.isCompleted).length;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    ex.photoUrl.isNotEmpty ? ex.photoUrl : WorkoutTemplateModels.getIllustrationForExercise(ex.name),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${ex.name}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary(isDark)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ex.targetMuscle} • ${ex.equipment}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              if (_isLiveSessionActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: completedCount >= ex.sets
                        ? AppColors.accentGreen.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$completedCount / ${ex.sets} Sets',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: completedCount >= ex.sets ? AppColors.accentGreen : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Previous Performance info (if available)
          if (ex.previousPerformance != null && ex.previousPerformance!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ex.previousPerformance!,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Sets rows (Interactive in Live mode)
          ...sets.asMap().entries.map((setEntry) {
            final setIdx = setEntry.key;
            final setRecord = setEntry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: setRecord.isCompleted
                    ? AppColors.accentGreen.withValues(alpha: isDark ? 0.15 : 0.10)
                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: setRecord.isCompleted
                      ? AppColors.accentGreen.withValues(alpha: 0.35)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set ${setRecord.setNumber}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary(isDark)),
                  ),
                  if (ex.isTimeBased) ...[
                    Text(
                      '${setRecord.durationSeconds > 0 ? setRecord.durationSeconds : ex.targetDurationSeconds} sec duration',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                    ),
                  ] else if (ex.isBodyweight) ...[
                    Text(
                      '${setRecord.reps} reps (Bodyweight)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                    ),
                  ] else ...[
                    Text(
                      '${setRecord.reps} reps @ ${setRecord.weightKg.toStringAsFixed(setRecord.weightKg % 1 == 0 ? 0 : 1)} kg',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (_isLiveSessionActive) ...[
                    InkWell(
                      onTap: () => _toggleLiveSetCompletion(ex.id, setIdx, ex.restSeconds, ex.name),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: setRecord.isCompleted ? AppColors.accentGreen : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: setRecord.isCompleted ? AppColors.accentGreen : Theme.of(context).hintColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          setRecord.isCompleted ? Icons.check : Icons.circle,
                          size: 14,
                          color: setRecord.isCompleted ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: Theme.of(context).hintColor),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= TAB 2: WORKOUT BUILDER & 7-DAY PLAN =================
  Widget _buildWorkoutBuilderTab(bool isDark) {
    final selectedDay = _days[_selectedBuilderDayIndex];
    final plan = _getDayPlan(selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.asMap().entries.map((e) {
                final idx = e.key;
                final day = e.value;
                final isSelected = idx == _selectedBuilderDayIndex;
                final dayPlan = _getDayPlan(day);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(day.substring(0, 3), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                        Text(dayPlan.isRestDay ? 'Rest' : '${dayPlan.exercises.length} ex', style: TextStyle(fontSize: 9.5, color: isSelected ? Colors.white70 : null)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedBuilderDayIndex = idx);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Plan Configuration Card
          GlassCard(
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$selectedDay Configuration',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary(isDark)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit Plan Info',
                      onPressed: () => _editDayPlanHeaderModal(selectedDay),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.workoutName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Focus: ${plan.muscleGroup} • ~${plan.estimatedDurationMinutes} mins • ${plan.difficulty}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Duplicate Day', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _duplicateDayPlanModal(selectedDay),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: plan.isRestDay ? AppColors.primary : AppColors.accentPurple,
                        ),
                        icon: Icon(plan.isRestDay ? Icons.fitness_center_rounded : Icons.bedtime_rounded, size: 15),
                        label: Text(plan.isRestDay ? 'Set as Workout' : 'Set as Rest Day', style: const TextStyle(fontSize: 11.5)),
                        onPressed: () async {
                          final updated = plan.copyWith(
                            isRestDay: !plan.isRestDay,
                            workoutName: !plan.isRestDay ? 'Rest & Recovery' : '$selectedDay Workout',
                            status: !plan.isRestDay ? WorkoutStatus.restDay : WorkoutStatus.planned,
                          );
                          setState(() => _workoutPlans[selectedDay] = updated);
                          await DBHelper.instance.saveWorkoutPlan(updated);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exercise List with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises (${plan.exercises.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Exercise', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _openExerciseLibrarySelector(selectedDay),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reorderable Exercise List
          if (plan.exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(plan.isRestDay ? Icons.bedtime_rounded : Icons.fitness_center_rounded, size: 36, color: Theme.of(context).hintColor),
                    const SizedBox(height: 8),
                    Text(
                      plan.isRestDay ? 'Rest Day — No exercises needed.' : 'No exercises added yet. Tap "Add Exercise" to select from library!',
                      style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...plan.exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final ex = entry.value;
              return _buildBuilderExerciseTile(ex, idx, selectedDay, isDark);
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBuilderExerciseTile(ExerciseDetail ex, int index, String dayName, bool isDark) {
    final plan = _getDayPlan(dayName);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(ex.photoUrl, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(
                  ex.isTimeBased
                      ? '${ex.sets} sets × ${ex.targetDurationSeconds}s • ${ex.equipment}'
                      : ex.isBodyweight
                          ? '${ex.sets} sets × ${ex.reps} reps (Bodyweight)'
                          : '${ex.sets} sets × ${ex.reps} reps @ ${ex.weightKg.toStringAsFixed(ex.weightKg % 1 == 0 ? 0 : 1)} kg',
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          // Move Up / Down
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
            tooltip: 'Move Up',
            onPressed: index > 0
                ? () async {
                    final list = List<ExerciseDetail>.from(plan.exercises);
                    final temp = list[index];
                    list[index] = list[index - 1];
                    list[index - 1] = temp;
                    final updated = plan.copyWith(exercises: list);
                    setState(() => _workoutPlans[dayName] = updated);
                    await DBHelper.instance.saveWorkoutPlan(updated);
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
            tooltip: 'Move Down',
            onPressed: index < plan.exercises.length - 1
                ? () async {
                    final list = List<ExerciseDetail>.from(plan.exercises);
                    final temp = list[index];
                    list[index] = list[index + 1];
                    list[index + 1] = temp;
                    final updated = plan.copyWith(exercises: list);
                    setState(() => _workoutPlans[dayName] = updated);
                    await DBHelper.instance.saveWorkoutPlan(updated);
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
            tooltip: 'Delete',
            onPressed: () async {
              final list = List<ExerciseDetail>.from(plan.exercises)..removeAt(index);
              final updated = plan.copyWith(exercises: list);
              setState(() => _workoutPlans[dayName] = updated);
              await DBHelper.instance.saveWorkoutPlan(updated);
            },
          ),
        ],
      ),
    );
  }

  // Exercise Library Picker Dialog
  void _openExerciseLibrarySelector(String dayName) {
    final categories = WorkoutTemplateModels.getExerciseLibrary();
    final customNameCtrl = TextEditingController();
    final customMuscleCtrl = TextEditingController();
    final customSetsCtrl = TextEditingController(text: '3');
    final customRepsCtrl = TextEditingController(text: '10');
    final customWeightCtrl = TextEditingController(text: '20');
    bool isCustomBw = false;
    bool isCustomTb = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Exercise Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Custom Exercise Quick Builder
                    ExpansionTile(
                      leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      title: const Text('Create Custom Exercise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: customNameCtrl,
                                decoration: const InputDecoration(labelText: 'Exercise Name', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: customMuscleCtrl,
                                decoration: const InputDecoration(labelText: 'Target Muscle', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: customSetsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Sets', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: customRepsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: customWeightCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(value: isCustomBw, onChanged: (v) => setSheetState(() => isCustomBw = v ?? false)),
                                  const Text('Bodyweight', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 16),
                                  Checkbox(value: isCustomTb, onChanged: (v) => setSheetState(() => isCustomTb = v ?? false)),
                                  const Text('Time-based', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () async {
                                  final name = customNameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  final newEx = ExerciseDetail(
                                    id: 'custom_ex_${DateTime.now().millisecondsSinceEpoch}',
                                    name: name,
                                    targetMuscle: customMuscleCtrl.text.trim().isNotEmpty ? customMuscleCtrl.text.trim() : 'General',
                                    sets: int.tryParse(customSetsCtrl.text) ?? 3,
                                    reps: int.tryParse(customRepsCtrl.text) ?? 10,
                                    weightKg: double.tryParse(customWeightCtrl.text) ?? 0.0,
                                    isBodyweight: isCustomBw,
                                    isTimeBased: isCustomTb,
                                    photoUrl: WorkoutTemplateModels.getIllustrationForExercise(name),
                                  );

                                  final plan = _getDayPlan(dayName);
                                  final updated = plan.copyWith(exercises: List.from(plan.exercises)..add(newEx));
                                  setState(() => _workoutPlans[dayName] = updated);
                                  await DBHelper.instance.saveWorkoutPlan(updated);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Add Custom Exercise', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Categorized Library
                    ...categories.map((cat) {
                      return ExpansionTile(
                        leading: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                        title: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('${cat.exercises.length} exercises', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                        children: cat.exercises.map((libEx) {
                          return ListTile(
                            title: Text(libEx.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: Text('${libEx.targetMuscle} • ${libEx.equipment} • ${libEx.sets}×${libEx.reps}', style: const TextStyle(fontSize: 11.5)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () async {
                                final plan = _getDayPlan(dayName);
                                final copyEx = libEx.copyWith(id: 'ex_${DateTime.now().millisecondsSinceEpoch}');
                                final updated = plan.copyWith(exercises: List.from(plan.exercises)..add(copyEx));
                                setState(() => _workoutPlans[dayName] = updated);
                                await DBHelper.instance.saveWorkoutPlan(updated);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added ${libEx.name} to $dayName!'), duration: const Duration(seconds: 1)),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editDayPlanHeaderModal(String dayName) {
    final plan = _getDayPlan(dayName);
    final nameCtrl = TextEditingController(text: plan.workoutName);
    final muscleCtrl = TextEditingController(text: plan.muscleGroup);
    final durCtrl = TextEditingController(text: plan.estimatedDurationMinutes.toString());
    String diff = plan.difficulty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $dayName Workout Info', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Workout Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'Muscle Group', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Mins)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final updated = plan.copyWith(
                workoutName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : plan.workoutName,
                muscleGroup: muscleCtrl.text.trim().isNotEmpty ? muscleCtrl.text.trim() : plan.muscleGroup,
                estimatedDurationMinutes: int.tryParse(durCtrl.text) ?? plan.estimatedDurationMinutes,
              );
              setState(() => _workoutPlans[dayName] = updated);
              await DBHelper.instance.saveWorkoutPlan(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _duplicateDayPlanModal(String sourceDay) {
    String targetDay = _days.firstWhere((d) => d != sourceDay);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Duplicate $sourceDay to another day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: targetDay,
                decoration: const InputDecoration(labelText: 'Target Day', border: OutlineInputBorder()),
                items: _days.where((d) => d != sourceDay).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => targetDay = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final source = _getDayPlan(sourceDay);
                final duplicated = source.copyWith(
                  id: 'plan_${targetDay.toLowerCase()}',
                  dayName: targetDay,
                  workoutName: source.workoutName,
                );
                setState(() => _workoutPlans[targetDay] = duplicated);
                await DBHelper.instance.saveWorkoutPlan(duplicated);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $sourceDay workout to $targetDay!'), backgroundColor: AppColors.accentGreen),
                  );
                }
              },
              child: const Text('Copy Plan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 3: IMMUTABLE WORKOUT HISTORY =================
  Widget _buildWorkoutHistoryTab(bool isDark) {
    if (_historySessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              const Text('No workout sessions logged yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Complete a live workout to record your immutable session history.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _historySessions.length,
      itemBuilder: (context, index) {
        final session = _historySessions[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 14),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${session.dayName.toUpperCase()} • ${session.date}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                    ),
                  ),
                  Text('${session.durationMinutes} min duration', style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.workoutName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(session.muscleGroup, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(height: 10),
              Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              const SizedBox(height: 8),
              ...session.exercises.map((ex) {
                final completedSets = ex.actualSets.where((s) => s.isCompleted).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.exerciseName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),
                      Text(
                        '${completedSets.length}/${ex.plannedSets} sets (${completedSets.isNotEmpty ? "${completedSets.first.reps} reps" : ""}${completedSets.isNotEmpty && completedSets.first.weightKg > 0 ? " @ ${completedSets.first.weightKg}kg" : ""})',
                        style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ================= TAB 4: PRs & PROGRESS =================
  Widget _buildProgressAndPRsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PR Trophy Banner
          GlassCard(
            borderRadius: 18,
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.accentAmber.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.1)]
                  : [AppColors.accentAmber.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PERSONAL RECORD VAULT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.1)),
                      Text('Auto-calculated lifetime maximums from actual workouts.', style: TextStyle(fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_personalRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Complete live workouts to unlock your personal records!', style: TextStyle(color: Theme.of(context).hintColor)),
              ),
            )
          else
            ..._personalRecords.values.map((pr) {
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pr.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (pr.heaviestWeightKg > 0)
                            Text('Max Weight: ${pr.heaviestWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                          if (pr.maxReps > 0)
                            Text('Max Reps: ${pr.maxReps} reps', style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.military_tech_rounded, color: AppColors.accentAmber, size: 24),
                  ],
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Floating Rest Timer
  Widget _buildFloatingRestTimerOverlay(bool isDark) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentAmber, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.accentAmber, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Resting: ${_restSecondsRemaining}s remaining', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text('Exercise: $_currentRestingExercise', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _cancelRestCountdown,
                child: const Text('Skip Rest', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

