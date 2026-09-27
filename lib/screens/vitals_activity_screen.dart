import 'dart:async';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class DailyActivityAndVitalsScreen extends StatefulWidget {
  final int initialTabIndex;

  const DailyActivityAndVitalsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DailyActivityAndVitalsScreen> createState() => _DailyActivityAndVitalsScreenState();
}

class _DailyActivityAndVitalsScreenState extends State<DailyActivityAndVitalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active Timer State
  Timer? _activityStopwatchTimer;
  int _stopwatchElapsedSeconds = 0;
  bool _isStopwatchRunning = false;
  String _selectedActivityType = 'Strength Training';

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    ProfileService.instance.addListener(_onProfileUpdated);
  }

  @override
  void dispose() {
    _activityStopwatchTimer?.cancel();
    _tabController.dispose();
    ProfileService.instance.removeListener(_onProfileUpdated);
    super.dispose();
  }

  void _onProfileUpdated() {
    if (mounted) setState(() {});
  }

  void _startStopwatch() {
    setState(() => _isStopwatchRunning = true);
    _activityStopwatchTimer?.cancel();
    _activityStopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _stopwatchElapsedSeconds++;
        });
      }
    });
  }

  void _pauseStopwatch() {
    _activityStopwatchTimer?.cancel();
    setState(() => _isStopwatchRunning = false);
  }

  void _resetStopwatch() {
    _activityStopwatchTimer?.cancel();
    setState(() {
      _stopwatchElapsedSeconds = 0;
      _isStopwatchRunning = false;
    });
  }

  void _saveStopwatchSession() async {
    final minutes = (_stopwatchElapsedSeconds / 60).ceil();
    if (minutes > 0) {
      await ProfileService.instance.logActiveMinutes(minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged $minutes minutes of $_selectedActivityType! 🔥'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    _resetStopwatch();
  }

  String _formatTimerTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showCustomNumberInputDialog({
    required String title,
    required String label,
    required String initialVal,
    required String suffix,
    required ValueChanged<String> onSaved,
  }) {
    final ctrl = TextEditingController(text: initialVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onSaved(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditTargetsDialog() {
    final profile = ProfileService.instance;
    final stepCtrl = TextEditingController(text: profile.dailyStepTarget.toString());
    final activeCtrl = TextEditingController(text: profile.dailyActiveTimeMinutesTarget.toString());
    final waterCtrl = TextEditingController(text: profile.dailyWaterIntakeMlTarget.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.primaryGlow),
            SizedBox(width: 8),
            Text('Edit Daily Vitals Targets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stepCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Step Target', suffixText: 'Steps', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: activeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Active Target', suffixText: 'Minutes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waterCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Water Target', suffixText: 'ml', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final steps = int.tryParse(stepCtrl.text);
              final active = int.tryParse(activeCtrl.text);
              final water = int.tryParse(waterCtrl.text);
              Navigator.pop(ctx);

              await profile.updateStrictGoal(
                dailyStepTarget: steps,
                dailyActiveTimeMinutesTarget: active,
                dailyWaterIntakeMlTarget: water,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vitals targets updated!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Update Targets'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity, Vitals & Hydration', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            tooltip: 'Customize Targets',
            onPressed: _showEditTargetsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: const [
            Tab(icon: Icon(Icons.directions_walk_rounded), text: 'Steps'),
            Tab(icon: Icon(Icons.timer_rounded), text: 'Active Hrs'),
            Tab(icon: Icon(Icons.water_drop_rounded), text: 'Water'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStepsTab(theme),
          _buildActiveHoursTab(theme),
          _buildWaterIntakeTab(theme),
          _buildAnalysisTab(theme),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: STEPS & WALKING
  // ==========================================
  Widget _buildStepsTab(ThemeData theme) {
    final profile = ProfileService.instance;
    final progress = (profile.dailyStepTarget > 0 ? profile.todaySteps / profile.dailyStepTarget : 0.0).clamp(0.0, 1.0);
    final distanceKm = (profile.todaySteps * 0.00078).toStringAsFixed(2);
    final caloriesKcal = (profile.todaySteps * 0.04).toStringAsFixed(0);
    final walkingMins = (profile.todaySteps / 110).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular / Hero Progress Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_walk_rounded, color: AppColors.accentAmber, size: 22),
                        SizedBox(width: 8),
                        Text('DAILY STEP PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1.1)),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showCustomNumberInputDialog(
                        title: 'Set Today Steps',
                        label: 'Total Steps',
                        initialVal: profile.todaySteps.toString(),
                        suffix: 'Steps',
                        onSaved: (val) {
                          final v = int.tryParse(val);
                          if (v != null) profile.setSteps(v);
                        },
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Counter & Target
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${profile.todaySteps}',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.accentAmber),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ ${profile.dailyStepTarget} Steps',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% of your daily movement goal achieved',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentAmber),
                  ),
                ),
                const SizedBox(height: 18),

                // Sub-metrics (Distance, Calories, Walking Time)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric(icon: Icons.place_outlined, label: 'Distance', value: '$distanceKm km', color: AppColors.accentBlue),
                    _buildSubMetric(icon: Icons.local_fire_department_outlined, label: 'Burned', value: '$caloriesKcal kcal', color: AppColors.accentRose),
                    _buildSubMetric(icon: Icons.schedule_rounded, label: 'Walk Time', value: '$walkingMins mins', color: AppColors.accentGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Log Buttons
          Text('Quick Add Steps', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickStepChip('+500', 500, profile),
              const SizedBox(width: 8),
              _buildQuickStepChip('+1,000', 1000, profile),
              const SizedBox(width: 8),
              _buildQuickStepChip('+2,500', 2500, profile),
              const SizedBox(width: 8),
              _buildQuickStepChip('+5,000', 5000, profile),
            ],
          ),
          const SizedBox(height: 20),

          // 7-Day Interactive Step Graph
          _buildWeeklyBarChart(
            title: '7-Day Step Progression Graph',
            subtitle: 'Daily step count vs 10,000 benchmark',
            data: profile.weeklySteps,
            targetValue: profile.dailyStepTarget.toDouble(),
            unit: 'Steps',
            barColor: AppColors.accentAmber,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Steps Pacing & Cadence Advice Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentAmber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Non-Exercise Activity (NEAT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Maintaining 10k daily steps burns ~400 kcal effortlessly, prevents metabolic slowdown, and boosts cognitive alertness.',
                        style: TextStyle(fontSize: 11.5, color: theme.hintColor, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStepChip(String label, int delta, ProfileService profile) {
    return Expanded(
      child: InkWell(
        onTap: () => profile.logSteps(delta),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: ACTIVE HOURS & ENERGY
  // ==========================================
  Widget _buildActiveHoursTab(ThemeData theme) {
    final profile = ProfileService.instance;
    final progress = (profile.dailyActiveTimeMinutesTarget > 0 ? profile.todayActiveTimeMinutes / profile.dailyActiveTimeMinutesTarget : 0.0).clamp(0.0, 1.0);
    final hours = (profile.todayActiveTimeMinutes / 60.0).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Minutes Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_rounded, color: AppColors.accentBlue, size: 22),
                        SizedBox(width: 8),
                        Text('ACTIVE TIME & EXERTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue, letterSpacing: 1.1)),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showCustomNumberInputDialog(
                        title: 'Set Active Minutes',
                        label: 'Minutes',
                        initialVal: profile.todayActiveTimeMinutes.toString(),
                        suffix: 'mins',
                        onSaved: (val) {
                          final v = int.tryParse(val);
                          if (v != null) profile.setActiveMinutes(v);
                        },
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${profile.todayActiveTimeMinutes}',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.accentBlue),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mins ($hours hrs) / ${profile.dailyActiveTimeMinutesTarget}m Target',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% of recommended cardiovascular exertion achieved',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  ),
                ),
                const SizedBox(height: 18),

                // Intensity Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric(icon: Icons.fitness_center_rounded, label: 'High Strain', value: '${(profile.todayActiveTimeMinutes * 0.6).round()}m', color: AppColors.primary),
                    _buildSubMetric(icon: Icons.directions_bike_rounded, label: 'Moderate', value: '${(profile.todayActiveTimeMinutes * 0.4).round()}m', color: AppColors.accentAmber),
                    _buildSubMetric(icon: Icons.self_improvement_rounded, label: 'Rest Ratio', value: '4:1', color: AppColors.accentGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Log Activity Chips
          Text('Quick Add Active Time', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickActiveChip('+15m', 15, profile),
              const SizedBox(width: 8),
              _buildQuickActiveChip('+30m', 30, profile),
              const SizedBox(width: 8),
              _buildQuickActiveChip('+45m', 45, profile),
              const SizedBox(width: 8),
              _buildQuickActiveChip('+60m', 60, profile),
            ],
          ),
          const SizedBox(height: 20),

          // Live Workout / Activity Stopwatch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryGlow, size: 20),
                        SizedBox(width: 8),
                        Text('Live Activity Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedActivityType,
                      underline: const SizedBox(),
                      isDense: true,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                      items: ['Strength Training', 'Brisk Walking', 'Cycling', 'HIIT Session', 'Sports / Yoga']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedActivityType = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Center(
                  child: Text(
                    _formatTimerTime(_stopwatchElapsedSeconds),
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: AppColors.primaryGlow),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isStopwatchRunning)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_stopwatchElapsedSeconds > 0 ? 'Resume' : 'Start Session'),
                        onPressed: _startStopwatch,
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber, foregroundColor: Colors.black),
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause'),
                        onPressed: _pauseStopwatch,
                      ),
                    const SizedBox(width: 10),
                    if (_stopwatchElapsedSeconds > 0) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Save Active Time'),
                        onPressed: _saveStopwatchSession,
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Reset timer',
                        onPressed: _resetStopwatch,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 7-Day Active Minutes Graph
          _buildWeeklyBarChart(
            title: '7-Day Active Hours Graph',
            subtitle: 'Daily high/moderate exertion vs 60m target',
            data: profile.weeklyActiveMinutes,
            targetValue: profile.dailyActiveTimeMinutesTarget.toDouble(),
            unit: 'Mins',
            barColor: AppColors.accentBlue,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActiveChip(String label, int delta, ProfileService profile) {
    return Expanded(
      child: InkWell(
        onTap: () => profile.logActiveMinutes(delta),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: WATER INTAKE & HYDRATION
  // ==========================================
  Widget _buildWaterIntakeTab(ThemeData theme) {
    final profile = ProfileService.instance;
    final targetMl = profile.dailyWaterIntakeMlTarget;
    final currentMl = profile.todayWaterIntakeMl;
    final progress = (targetMl > 0 ? currentMl / targetMl : 0.0).clamp(0.0, 1.0);
    final liters = (currentMl / 1000.0).toStringAsFixed(2);
    final targetLiters = (targetMl / 1000.0).toStringAsFixed(1);
    final glasses = (currentMl / 250.0).toStringAsFixed(1);
    final targetGlasses = (targetMl / 250.0).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hydration Hero Reservoir Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_rounded, color: AppColors.accentBlue, size: 22),
                        SizedBox(width: 8),
                        Text('DAILY HYDRATION RESERVOIR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue, letterSpacing: 1.1)),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showCustomNumberInputDialog(
                        title: 'Set Today Water Intake',
                        label: 'Total ml',
                        initialVal: currentMl.toString(),
                        suffix: 'ml',
                        onSaved: (val) {
                          final v = int.tryParse(val);
                          if (v != null) profile.setWater(v);
                        },
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Liter Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$liters L',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.accentBlue),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ $targetLiters L ($currentMl / $targetMl ml)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Approx. $glasses / $targetGlasses Standard Glasses (250ml each)',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  ),
                ),
                const SizedBox(height: 18),

                // Sub-metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric(icon: Icons.battery_charging_full_rounded, label: 'Hydration', value: '${(progress * 100).toStringAsFixed(0)}%', color: AppColors.accentGreen),
                    _buildSubMetric(icon: Icons.opacity_rounded, label: 'Remaining', value: '${(targetMl - currentMl).clamp(0, 10000)} ml', color: AppColors.accentAmber),
                    _buildSubMetric(icon: Icons.local_drink_rounded, label: 'Glass Target', value: '$targetGlasses Glasses', color: AppColors.accentBlue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick 1-Tap Logging Buttons
          Text('Log Water Intake', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickWaterButton(label: '+250ml', sub: '1 Glass', delta: 250, profile: profile),
              const SizedBox(width: 8),
              _buildQuickWaterButton(label: '+500ml', sub: 'Bottle', delta: 500, profile: profile),
              const SizedBox(width: 8),
              _buildQuickWaterButton(label: '+750ml', sub: 'Sipper', delta: 750, profile: profile),
              const SizedBox(width: 8),
              _buildQuickWaterButton(label: '+1.0 L', sub: 'Large', delta: 1000, profile: profile),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Undo 250ml', style: TextStyle(fontSize: 12)),
                  onPressed: () => profile.logWater(-250),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Custom ml', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showCustomNumberInputDialog(
                    title: 'Add Custom Water',
                    label: 'Amount (ml)',
                    initialVal: '350',
                    suffix: 'ml',
                    onSaved: (val) {
                      final v = int.tryParse(val);
                      if (v != null && v > 0) profile.logWater(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-Day Hydration Bar Chart
          _buildWeeklyBarChart(
            title: '7-Day Hydration Consistency Graph',
            subtitle: 'Daily water intake vs 3.0 Liter target',
            data: profile.weeklyWaterMl,
            targetValue: profile.dailyWaterIntakeMlTarget.toDouble(),
            unit: 'ml',
            barColor: AppColors.accentBlue,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Hydration Schedule Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 8),
                    Text('Recommended Hydration Schedule', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildScheduleItem('07:00 AM - Morning Wakeup', '500ml warm water with lemon', true),
                _buildScheduleItem('11:00 AM - Pre-Lunch Hydration', '500ml fresh water', true),
                _buildScheduleItem('04:30 PM - Intra / Post Workout', '750ml electrolyte hydration', true),
                _buildScheduleItem('08:00 PM - Evening Recovery', '500ml water before dinner', currentMl >= 2250),
                _buildScheduleItem('10:00 PM - Pre-Sleep Sip', '250ml water for overnight hydration', currentMl >= 3000),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickWaterButton({
    required String label,
    required String sub,
    required int delta,
    required ProfileService profile,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => profile.logWater(delta),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 9.5, color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String time, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isDone ? AppColors.accentGreen : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDone ? null : AppColors.textMuted)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: TELEMETRY ANALYSIS & GRAPHS
  // ==========================================
  Widget _buildAnalysisTab(ThemeData theme) {
    final profile = ProfileService.instance;
    final stepAvg = profile.weeklySteps.isEmpty ? 0 : (profile.weeklySteps.reduce((a, b) => a + b) / profile.weeklySteps.length).round();
    final activeAvg = profile.weeklyActiveMinutes.isEmpty ? 0 : (profile.weeklyActiveMinutes.reduce((a, b) => a + b) / profile.weeklyActiveMinutes.length).round();
    final waterAvg = profile.weeklyWaterMl.isEmpty ? 0 : (profile.weeklyWaterMl.reduce((a, b) => a + b) / profile.weeklyWaterMl.length).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Average Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryPill(
                  title: 'Avg Steps/Day',
                  value: '$stepAvg',
                  badge: '${((stepAvg / profile.dailyStepTarget) * 100).toStringAsFixed(0)}% Target',
                  color: AppColors.accentAmber,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryPill(
                  title: 'Avg Active/Day',
                  value: '${activeAvg}m',
                  badge: '${((activeAvg / profile.dailyActiveTimeMinutesTarget) * 100).toStringAsFixed(0)}% Target',
                  color: AppColors.accentBlue,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryPill(
                  title: 'Avg Water/Day',
                  value: '${(waterAvg / 1000).toStringAsFixed(1)}L',
                  badge: '${((waterAvg / profile.dailyWaterIntakeMlTarget) * 100).toStringAsFixed(0)}% Target',
                  color: AppColors.accentGreen,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Multi-metric Comparison Graph
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('7-Day Normalized Telemetry Graph', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Percentage of Target Hit (% Performance)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildLegendIndicator('Steps', AppColors.accentAmber),
                        const SizedBox(width: 6),
                        _buildLegendIndicator('Active', AppColors.accentBlue),
                        const SizedBox(width: 6),
                        _buildLegendIndicator('Water', AppColors.accentGreen),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Multi-bar visual container
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (idx) {
                      final day = _weekDays[idx];
                      final stepRatio = (profile.weeklySteps[idx] / profile.dailyStepTarget).clamp(0.0, 1.3);
                      final activeRatio = (profile.weeklyActiveMinutes[idx] / profile.dailyActiveTimeMinutesTarget).clamp(0.0, 1.3);
                      final waterRatio = (profile.weeklyWaterMl[idx] / profile.dailyWaterIntakeMlTarget).clamp(0.0, 1.3);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildMiniMultiBar(stepRatio, AppColors.accentAmber),
                              const SizedBox(width: 2),
                              _buildMiniMultiBar(activeRatio, AppColors.accentBlue),
                              const SizedBox(width: 2),
                              _buildMiniMultiBar(waterRatio, AppColors.accentGreen),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(day, style: TextStyle(fontSize: 10.5, fontWeight: idx == 6 ? FontWeight.bold : FontWeight.normal)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Synthesis & Correlation Insights Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: AppColors.accentPurple, size: 22),
                    SizedBox(width: 8),
                    Text('AI Vitals & Health Telemetry Analysis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAnalysisReportItem(
                  title: '1. Movement & NEAT Pacing',
                  body: stepAvg >= 10000
                      ? '⚡ Exceptional daily movement! Your 7-day average ($stepAvg steps) exceeds the 10,000 threshold, maintaining high baseline fat oxidation and cardiovascular health.'
                      : '💡 You are averaging $stepAvg steps/day (~${(10000 - stepAvg)} steps away from 10k). Adding a 15-minute post-lunch walk will bridge the gap effortlessly.',
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.accentAmber,
                ),
                const SizedBox(height: 10),
                _buildAnalysisReportItem(
                  title: '2. Cardiovascular & Resistance Strain',
                  body: activeAvg >= 45
                      ? '🔥 Superb training consistency ($activeAvg mins/day). Your weekly high-to-moderate exertion ratio is well balanced with adequate recovery.'
                      : '⚠️ Active duration is averaging $activeAvg mins. Aim for at least 45-60 minutes on workout days to maximize hypertrophy and endurance.',
                  icon: Icons.timer_rounded,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(height: 10),
                _buildAnalysisReportItem(
                  title: '3. Hydration & Recovery Matrix',
                  body: waterAvg >= 2800
                      ? '💧 Optimal cellular hydration ($waterAvg ml/day). Your fluid intake supports peak muscle protein synthesis, joint lubrication, and toxin clearance.'
                      : '💧 Water intake is at ${(waterAvg / 1000).toStringAsFixed(1)} L/day. Increasing water intake to 3.0 L will significantly curb mid-day cravings and enhance workout pump.',
                  icon: Icons.water_drop_rounded,
                  color: AppColors.accentGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required String title,
    required String value,
    required String badge,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildMiniMultiBar(double ratio, Color color) {
    final height = (ratio * 120.0).clamp(4.0, 140.0);
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAnalysisReportItem({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 11.5, height: 1.35)),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED 7-DAY BAR CHART WIDGET
  // ==========================================
  Widget _buildWeeklyBarChart({
    required String title,
    required String subtitle,
    required List<int> data,
    required double targetValue,
    required String unit,
    required Color barColor,
    required ThemeData theme,
  }) {
    final maxVal = data.isEmpty ? targetValue : (data.reduce((a, b) => a > b ? a : b).toDouble() * 1.15).clamp(targetValue * 1.1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: theme.hintColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: barColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('Target: ${targetValue.toInt()} $unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: barColor)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final day = _weekDays[idx];
                final val = idx < data.length ? data[idx] : 0;
                final heightRatio = (maxVal > 0 ? (val / maxVal) : 0.0).clamp(0.05, 1.0);
                final isToday = idx == 6;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : '$val',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? barColor : theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 105 * heightRatio,
                      decoration: BoxDecoration(
                        color: isToday ? barColor : barColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                        border: isToday ? Border.all(color: Colors.white, width: 1.5) : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? barColor : null,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
