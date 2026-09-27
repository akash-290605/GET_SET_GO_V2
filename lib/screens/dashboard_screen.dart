import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/workout_service.dart';
import '../services/finance_service.dart';
import '../services/food_service.dart';
import '../services/theme_service.dart';
import '../models/workout_models.dart';
import '../widgets/titan_ai_sheet.dart';
import '../widgets/account_cloud_modal.dart';

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
                // Titan Dynamic AI Insight Card
                _buildTitanInsightCard(context, isDark, currSymbol, financeService, workoutService),
                const SizedBox(height: 18),

                // Quick Action Bar
                _buildQuickActionBar(context, isDark),
                const SizedBox(height: 22),

                // Daily Fitness Snapshot
                _buildFitnessCard(context, isDark, profile, todayPlan, workoutService),
                const SizedBox(height: 18),

                // Finance Health Snapshot
                _buildFinanceCard(context, isDark, currSymbol, financeService),
                const SizedBox(height: 18),

                // Nutrition & Macros Snapshot
                _buildNutritionCard(context, isDark, foodService),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Titan Dynamic Insight Card
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

  // 2. Quick Action Bar
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

  // 3. Fitness Card
  Widget _buildFitnessCard(
    BuildContext context,
    bool isDark,
    dynamic profile,
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

  // 4. Finance Card
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

  // 5. Nutrition Card
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
}
