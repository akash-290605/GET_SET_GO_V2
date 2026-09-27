import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/workout_service.dart';
import '../services/finance_service.dart';
import '../services/food_service.dart';
import '../services/theme_service.dart';
import '../models/workout_models.dart';
import '../widgets/titan_ai_sheet.dart';
import '../widgets/account_cloud_modal.dart';
import '../widgets/body_photo_modal.dart';
import '../widgets/weekly_report_modal.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;
  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileService = ProfileService.instance;
    final workoutService = WorkoutService.instance;
    final financeService = FinanceService.instance;
    final foodService = FoodService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([profileService, workoutService, financeService, foodService]),
      builder: (context, _) {
        final profile = profileService.profile;
        final todayPlan = workoutService.todayPlan;
        final currSymbol = profile.currencySymbol;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GET SET GO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Welcome back, ${profile.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                tooltip: 'Weekly BMI Report',
                onPressed: () => WeeklyReportModal.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Body Photo Check-in',
                onPressed: () => BodyPhotoModal.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.cloud_sync_outlined),
                tooltip: 'Cloud Sync & Vault',
                onPressed: () => AccountCloudModal.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                tooltip: 'Ask Titan AI',
                onPressed: () => TitanAiSheet.show(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // 1. Strict Goal & Daily Telemetry Header Banner (Editable on Tap)
                _buildStrictGoalHeader(context, profile, profileService, isDark),
                const SizedBox(height: 18),

                // 2. Titan Dynamic AI Insight Card
                _buildTitanInsightCard(context, isDark, currSymbol, financeService, workoutService),
                const SizedBox(height: 18),

                // 3. Quick Action Bar
                _buildQuickActionBar(context, isDark),
                const SizedBox(height: 22),

                // 4. Daily Fitness Snapshot
                _buildFitnessCard(context, isDark, profile, todayPlan, workoutService),
                const SizedBox(height: 18),

                // 5. Finance Health Snapshot
                _buildFinanceCard(context, isDark, currSymbol, financeService),
                const SizedBox(height: 18),

                // 6. Nutrition & Macros Snapshot
                _buildNutritionCard(context, isDark, foodService),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Strict Goal & Daily Steps / Active Duration Telemetry Card
  Widget _buildStrictGoalHeader(
    BuildContext context,
    UserProfile profile,
    ProfileService profileService,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Strict Goal Title (Editable on Tap) + Strict Badge
          InkWell(
            onTap: () => _showEditStrictGoalDialog(context, profile, profileService),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: Color(0xFF818CF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.isStrictMode ? 'STRICT GOAL PROTOCOL' : 'ACTIVE GOAL PROTOCOL',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF818CF8)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.strictGoalTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.isStrictMode
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: profile.isStrictMode
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      profile.isStrictMode ? 'STRICT' : 'STANDARD',
                      style: TextStyle(
                        color: profile.isStrictMode ? Colors.redAccent : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Telemetry Row: Daily Steps Meter & Daily Active Time Meter
          Row(
            children: [
              // 1. Steps Tracker
              Expanded(
                child: _buildTelemetryMeter(
                  context: context,
                  title: 'Daily Steps',
                  current: profile.todaySteps,
                  target: profile.dailyStepTarget,
                  unit: 'steps',
                  progress: profile.stepsProgressRatio,
                  color: ThemeService.primaryEmerald,
                  isDark: isDark,
                  onQuickAdd1: () => profileService.addSteps(500),
                  quickAdd1Label: '+500',
                  onQuickAdd2: () => profileService.addSteps(1000),
                  quickAdd2Label: '+1k',
                  onCustomEdit: () => _showCustomInputDialog(
                    context,
                    title: 'Log Today\'s Steps',
                    initialVal: profile.todaySteps.toString(),
                    onSaved: (val) {
                      final s = int.tryParse(val);
                      if (s != null) profileService.logSteps(s);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Active Time Tracker
              Expanded(
                child: _buildTelemetryMeter(
                  context: context,
                  title: 'Active Time',
                  current: profile.todayActiveTimeMinutes,
                  target: profile.dailyActiveTimeMinutesTarget,
                  unit: 'mins',
                  progress: profile.activeTimeProgressRatio,
                  color: ThemeService.primaryCyan,
                  isDark: isDark,
                  onQuickAdd1: () => profileService.addActiveTime(15),
                  quickAdd1Label: '+15m',
                  onQuickAdd2: () => profileService.addActiveTime(30),
                  quickAdd2Label: '+30m',
                  onCustomEdit: () => _showCustomInputDialog(
                    context,
                    title: 'Log Active Duration (Minutes)',
                    initialVal: profile.todayActiveTimeMinutes.toString(),
                    onSaved: (val) {
                      final m = int.tryParse(val);
                      if (m != null) profileService.logActiveTime(m);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Quick Action Buttons: Weekly BMI Report & Body Photo Check-in
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => WeeklyReportModal.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: ThemeService.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ThemeService.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assessment_rounded, size: 16, color: ThemeService.primaryCyan),
                        SizedBox(width: 6),
                        Text(
                          'Weekly BMI Report',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: ThemeService.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => BodyPhotoModal.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF818CF8)),
                        SizedBox(width: 6),
                        Text(
                          'Body Photo Log',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMeter({
    required BuildContext context,
    required String title,
    required int current,
    required int target,
    required String unit,
    required double progress,
    required Color color,
    required bool isDark,
    required VoidCallback onQuickAdd1,
    required String quickAdd1Label,
    required VoidCallback onQuickAdd2,
    required String quickAdd2Label,
    required VoidCallback onCustomEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: onCustomEdit,
                child: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                current.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $target $unit',
                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onQuickAdd1,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quickAdd1Label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: onQuickAdd2,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quickAdd2Label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Titan Dynamic Insight Card
  Widget _buildTitanInsightCard(
    BuildContext context,
    bool isDark,
    String currSymbol,
    FinanceService finance,
    WorkoutService workout,
  ) {
    final audit = finance.generateAuditReport();
    String insightText;
    if (audit.isNotEmpty) {
      final topFlag = audit.first;
      insightText = "${topFlag.category}: ${topFlag.reason}";
    } else if (workout.todayPlan != null && !workout.todayPlan!.isRestDay) {
      insightText = "Today is ${workout.currentDayName} (${workout.todayPlan!.workoutTitle}). Target progressive overload on ${workout.todayPlan!.primaryMuscle}.";
    } else {
      insightText = "Active recovery day logged. Prioritize 8+ hours of sleep and hit your daily hydration target.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE0F2FE), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeService.primaryCyan.withValues(alpha: isDark ? 0.35 : 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ThemeService.primaryCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_outlined, color: ThemeService.primaryCyan, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'TITAN AI DAILY TELEMETRY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ThemeService.primaryCyan,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => TitanAiSheet.show(context),
                child: const Row(
                  children: [
                    Text('Ask AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan)),
                    Icon(Icons.chevron_right, size: 16, color: ThemeService.primaryCyan),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insightText,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Quick Action Bar
  Widget _buildQuickActionBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _quickButton(
            icon: Icons.fitness_center_rounded,
            label: 'Workout',
            color: ThemeService.primaryCyan,
            isDark: isDark,
            onTap: () => onNavigateTab(1), // Workout tab
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickButton(
            icon: Icons.camera_alt_rounded,
            label: 'Food Vision',
            color: ThemeService.primaryEmerald,
            isDark: isDark,
            onTap: () => onNavigateTab(2), // Food tab
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Finance',
            color: ThemeService.accentIndigo,
            isDark: isDark,
            onTap: () => onNavigateTab(3), // Finance tab
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickButton(
            icon: Icons.insights_rounded,
            label: 'Analytics',
            color: ThemeService.accentAmber,
            isDark: isDark,
            onTap: () => onNavigateTab(4), // Analytics tab
          ),
        ),
      ],
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Fitness Card
  Widget _buildFitnessCard(
    BuildContext context,
    bool isDark,
    UserProfile profile,
    DayWorkoutPlan? todayPlan,
    WorkoutService workout,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: ThemeService.primaryCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'FITNESS & SPLIT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.currentStreakDays} Day Streak',
                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Workout Title & Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayPlan?.workoutTitle ?? 'Rest & Regeneration',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${todayPlan?.primaryMuscle ?? 'Mobility'} • ${todayPlan?.durationMinutes ?? 0} mins • ${todayPlan?.exercises.length ?? 0} exercises',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => onNavigateTab(1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: const BorderSide(color: ThemeService.primaryCyan),
                ),
                child: const Text('View Plan', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weight & Progress Metrics
          Row(
            children: [
              _metricTile(
                title: 'Weight',
                value: '${profile.currentWeightKg} kg',
                sub: 'Target: ${profile.targetWeightKg} kg',
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _metricTile(
                title: 'Weekly Completion',
                value: '${(workout.weeklyCompletionRate * 100).toStringAsFixed(0)}%',
                sub: '${workout.plans.values.where((p) => p.status == WorkoutStatus.completed).length}/7 Days Done',
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _metricTile(
                title: 'BMI',
                value: profile.bmi.toStringAsFixed(1),
                sub: profile.bmiCategory,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Finance Card
  Widget _buildFinanceCard(
    BuildContext context,
    bool isDark,
    String currSymbol,
    FinanceService finance,
  ) {
    final balance = finance.netSavings;
    final income = finance.totalIncome;
    final expense = finance.totalExpense;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: ThemeService.primaryEmerald, size: 20),
              const SizedBox(width: 8),
              const Text(
                'FINANCE OVERVIEW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const Spacer(),
              InkWell(
                onTap: () => onNavigateTab(3),
                child: const Text(
                  'Manage Ledger →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Net Balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currSymbol${balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: balance >= 0 ? ThemeService.primaryEmerald : Colors.redAccent,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Net Balance', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),

          // Income vs Expense row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Income', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '+$currSymbol${income.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThemeService.primaryEmerald),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '-$currSymbol${expense.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Budget Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Remaining: $currSymbol${finance.budgetRemaining.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    '${(finance.budgetUsageRatio * 100).toStringAsFixed(0)}% Used',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: finance.budgetUsageRatio > 1.0 ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: finance.budgetUsageRatio.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                  color: finance.budgetUsageRatio > 0.9 ? Colors.redAccent : ThemeService.primaryCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Nutrition Card
  Widget _buildNutritionCard(BuildContext context, bool isDark, FoodService food) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'NUTRITION & MACROS TODAY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const Spacer(),
              InkWell(
                onTap: () => onNavigateTab(2),
                child: const Text(
                  'Log Food →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _macroPill(
                label: 'Calories',
                current: food.totalCalories.toStringAsFixed(0),
                target: '${food.macroTargets.calorieTarget.toStringAsFixed(0)} kcal',
                progress: food.calorieProgress,
                color: Colors.orangeAccent,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _macroPill(
                label: 'Protein',
                current: '${food.totalProtein.toStringAsFixed(0)}g',
                target: '${food.macroTargets.proteinTargetGrams.toStringAsFixed(0)}g',
                progress: food.proteinProgress,
                color: ThemeService.primaryCyan,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _macroPill(
                label: 'Hydration',
                current: '${(food.todayWaterMl / 1000).toStringAsFixed(1)}L',
                target: '${(food.macroTargets.waterMlTarget / 1000).toStringAsFixed(1)}L',
                progress: food.waterProgress,
                color: ThemeService.accentIndigo,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required String sub,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _macroPill({
    required String label,
    required String current,
    required String target,
    required double progress,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(current, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(target, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStrictGoalDialog(
    BuildContext context,
    UserProfile profile,
    ProfileService profileService,
  ) {
    final titleCtrl = TextEditingController(text: profile.strictGoalTitle);
    final stepCtrl = TextEditingController(text: profile.dailyStepTarget.toString());
    final activeCtrl = TextEditingController(text: profile.dailyActiveTimeMinutesTarget.toString());
    final weightTargetCtrl = TextEditingController(text: profile.targetWeightKg.toStringAsFixed(1));
    bool strictMode = profile.isStrictMode;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.track_changes_rounded, color: ThemeService.primaryCyan),
                  SizedBox(width: 8),
                  Text('Edit Strict Goal Protocol'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Strict Goal Headline',
                        hintText: 'e.g. 10,000 Steps & Hypertrophy',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stepCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Step Target',
                        hintText: 'e.g. 10000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_walk_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: activeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Active Minutes Target',
                        hintText: 'e.g. 60',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightTargetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target Weight (kg)',
                        hintText: 'e.g. 68.0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Strict Discipline Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Highlights daily step and active compliance', style: TextStyle(fontSize: 12)),
                      value: strictMode,
                      activeThumbColor: ThemeService.primaryCyan,
                      onChanged: (v) => setModalState(() => strictMode = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeService.primaryCyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final newTitle = titleCtrl.text.trim();
                    final newSteps = int.tryParse(stepCtrl.text.trim()) ?? profile.dailyStepTarget;
                    final newActive = int.tryParse(activeCtrl.text.trim()) ?? profile.dailyActiveTimeMinutesTarget;
                    final newTargetW = double.tryParse(weightTargetCtrl.text.trim()) ?? profile.targetWeightKg;

                    profileService.updateStrictGoal(
                      strictGoalTitle: newTitle.isNotEmpty ? newTitle : profile.strictGoalTitle,
                      isStrictMode: strictMode,
                      dailyStepTarget: newSteps,
                      dailyActiveTimeMinutesTarget: newActive,
                      targetWeightKg: newTargetW,
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Strict Goal Protocol updated!')),
                    );
                  },
                  child: const Text('Save Protocol'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomInputDialog(
    BuildContext context, {
    required String title,
    required String initialVal,
    required Function(String) onSaved,
  }) {
    final ctrl = TextEditingController(text: initialVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ThemeService.primaryCyan, foregroundColor: Colors.black),
            onPressed: () {
              onSaved(ctrl.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
