import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../models/workout_models.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import 'food_tracking_screen.dart';
import 'workout_screen.dart';
import 'expense_screen.dart';
import 'ai_coach_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<WorkoutDayPlan> _workouts = [];
  List<MealRecord> _meals = [];
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    ProfileService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final w = await DBHelper.instance.getWorkoutPlans();
      final m = await DBHelper.instance.getMeals();
      final e = await DBHelper.instance.getExpenses();

      if (mounted) {
        setState(() {
          _workouts = w;
          _meals = m;
          _expenses = e;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _currentDayName {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekday = DateTime.now().weekday - 1;
    return days[weekday.clamp(0, 6)];
  }

  WorkoutDayPlan? get _todayWorkout {
    final day = _currentDayName;
    try {
      return _workouts.firstWhere((w) => w.dayName == day);
    } catch (_) {
      return null;
    }
  }

  double get _todayCalories {
    final now = DateTime.now();
    final todayMeals = _meals.where((m) =>
        m.loggedAt.year == now.year &&
        m.loggedAt.month == now.month &&
        m.loggedAt.day == now.day);
    return todayMeals.fold(0.0, (sum, m) => sum + m.totalCalories);
  }

  double get _todayProtein {
    final now = DateTime.now();
    final todayMeals = _meals.where((m) =>
        m.loggedAt.year == now.year &&
        m.loggedAt.month == now.month &&
        m.loggedAt.day == now.day);
    return todayMeals.fold(0.0, (sum, m) => sum + m.totalProtein);
  }

  Map<String, dynamic> get _monthlyFinanceStats {
    final now = DateTime.now();
    final thisMonthExpenses = _expenses.where((t) {
      final date = DateTime.tryParse(t['date'] ?? '') ?? now;
      return date.year == now.year && date.month == now.month;
    }).toList();

    double income = 0;
    double expenses = 0;
    final catMap = <String, double>{};

    for (var t in thisMonthExpenses) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['is_income'] == 1 || t['is_income'] == true) {
        income += amt;
      } else {
        expenses += amt;
        final cat = t['category'] as String? ?? 'General';
        catMap[cat] = (catMap[cat] ?? 0) + amt;
      }
    }

    String topCat = 'None';
    double topCatAmt = 0;
    catMap.forEach((k, v) {
      if (v > topCatAmt) {
        topCatAmt = v;
        topCat = k;
      }
    });

    return {
      'income': income,
      'expenses': expenses,
      'savings': income - expenses,
      'topCategory': topCat,
      'topCategoryAmount': topCatAmt,
    };
  }

  String get _smartAiInsight {
    final stats = _monthlyFinanceStats;
    final budgetCap = ProfileService.instance.monthlyBudgetCap;
    final exp = stats['expenses'] as double;
    final todayCal = _todayCalories;
    final targetCal = ProfileService.instance.nutritionTarget.calorieTarget;
    final todayProt = _todayProtein;
    final targetProt = ProfileService.instance.nutritionTarget.proteinTargetGrams;

    if (exp > budgetCap * 0.8) {
      return "⚠️ You've utilized ${(exp / budgetCap * 100).toStringAsFixed(0)}% of your monthly budget. Review recurring subscriptions to stay on track.";
    } else if (todayCal > targetCal && targetCal > 0) {
      return "⚠️ You've reached ${(todayCal - targetCal).toStringAsFixed(0)} kcal over your daily target. Light cardio or active walking can balance today's energy expenditure.";
    } else if (todayProt < targetProt * 0.5 && DateTime.now().hour > 17) {
      return "🥩 You are ${(targetProt - todayProt).toStringAsFixed(0)}g away from your daily protein goal. A high-protein dinner or shake is recommended.";
    } else if (_todayWorkout?.status == WorkoutStatus.completed) {
      return "🔥 Great discipline completing today's ${_todayWorkout?.workoutName}! Ensure you hydrate and rest for optimal recovery.";
    } else if (stats['topCategory'] != 'None') {
      return "💡 Your largest expense category this month is ${stats['topCategory']} (${ProfileService.instance.currencySymbol} ${(stats['topCategoryAmount'] as double).toStringAsFixed(0)}). AI Coach can suggest optimizations.";
    }
    return "⚡ You're on track for your fitness and financial targets. Stay disciplined and keep momentum!";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;
    final curSym = profile.currencySymbol;
    final todayWk = _todayWorkout;
    final finStats = _monthlyFinanceStats;
    final completedWorkouts = _workouts.where((w) => w.status == WorkoutStatus.completed).length;
    final totalPlannedWorkouts = _workouts.where((w) => w.status != WorkoutStatus.restDay).length;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting & Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${profile.userName} 👋',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_currentDayName • Focus: ${profile.fitnessGoal}',
                              style: TextStyle(fontSize: 12.5, color: theme.hintColor),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, color: AppColors.accentAmber, size: 16),
                              SizedBox(width: 4),
                              Text('4 Day Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentAmber)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Compact AI Insight Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.18),
                            AppColors.secondary.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AI LIFE-MANAGEMENT INSIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(_smartAiInsight, style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions Row
                    Text('Quick Actions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.fitness_center_rounded,
                            label: 'Today Workout',
                            color: AppColors.primary,
                            onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Scan Food AI',
                            color: AppColors.accentGreen,
                            onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackingScreen())),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            icon: Icons.add_card_rounded,
                            label: 'Add Expense',
                            color: AppColors.secondary,
                            onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(3) : Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            icon: Icons.psychology_rounded,
                            label: 'Ask AI Coach',
                            color: AppColors.accentAmber,
                            onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(4) : Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCoachScreen())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Dynamic Widgets: Fitness, Nutrition, Finance
                    // 1. Fitness Card
                    _buildFitnessCard(todayWk, completedWorkouts, totalPlannedWorkouts),
                    const SizedBox(height: 14),

                    // 2. Nutrition Card
                    _buildNutritionCard(),
                    const SizedBox(height: 14),

                    // 3. Finance Card
                    _buildFinanceCard(finStats, curSym),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessCard(WorkoutDayPlan? todayWk, int completed, int totalPlanned) {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('FITNESS & WORKOUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                child: const Text('View Plan →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(todayWk != null ? todayWk.workoutName : 'Active Rest Day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      todayWk != null ? '${todayWk.muscleGroup} • ${todayWk.exercises.length} exercises' : 'Rest and recover for next session',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              if (todayWk != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WorkoutModels.getStatusColor(todayWk.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    WorkoutModels.getStatusLabel(todayWk.status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WorkoutModels.getStatusColor(todayWk.status)),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Weight', '${profile.weightKg} kg', 'Target: ${profile.targetWeightKg} kg'),
              _buildMiniMetric('Weekly Split', '$completed / $totalPlanned Done', '${((totalPlanned > 0 ? completed / totalPlanned : 0) * 100).toStringAsFixed(0)}% complete'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final theme = Theme.of(context);
    final target = ProfileService.instance.nutritionTarget;
    final todayCal = _todayCalories;
    final todayProt = _todayProtein;
    final calPct = (target.calorieTarget > 0 ? todayCal / target.calorieTarget : 0.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: AppColors.accentGreen, size: 18),
                  SizedBox(width: 8),
                  Text('DAILY NUTRITION INTAKE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 1.1)),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackingScreen())),
                child: const Text('Log Meal →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${todayCal.toStringAsFixed(0)} / ${target.calorieTarget.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${todayProt.toStringAsFixed(0)}g / ${target.proteinTargetGrams.toStringAsFixed(0)}g Protein', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${(calPct * 100).toStringAsFixed(0)}% Calorie Target', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: calPct,
              minHeight: 6,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(Map<String, dynamic> stats, String curSym) {
    final theme = Theme.of(context);
    final exp = stats['expenses'] as double;
    final savings = stats['savings'] as double;
    final topCat = stats['topCategory'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondary, size: 18),
                  SizedBox(width: 8),
                  Text('MONTHLY FINANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(3) : Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                child: const Text('View Finance →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$curSym ${savings.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: savings >= 0 ? AppColors.accentGreen : AppColors.accentRose)),
                    Text('Monthly Net Savings', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Top: $topCat', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('$curSym ${exp.toStringAsFixed(0)} Total Spent', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, String sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(fontSize: 10.5, color: theme.hintColor)),
      ],
    );
  }
}
