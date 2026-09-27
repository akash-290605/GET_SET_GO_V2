import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../models/workout_models.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<WorkoutDayPlan> _workoutPlans = [];
  List<MealRecord> _mealRecords = [];
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllProgressData();
    ProfileService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    ProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAllProgressData() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await DBHelper.instance.getWorkoutPlans();
      final meals = await DBHelper.instance.getMeals();
      final expenses = await DBHelper.instance.getExpenses();

      if (mounted) {
        setState(() {
          _workoutPlans = workouts;
          _mealRecords = meals;
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logWeightDialog() {
    final currentWeight = ProfileService.instance.weightKg;
    final weightCtrl = TextEditingController(text: currentWeight.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Log Today\'s Weight', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder(), suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text.trim());
              if (w != null && w > 0) {
                await ProfileService.instance.logWeight(w);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              }
            },
            child: const Text('Save Log', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_weight_outlined),
            tooltip: 'Log Weight',
            onPressed: _logWeightDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Workout'),
            Tab(icon: Icon(Icons.restaurant_rounded), text: 'Nutrition'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Finance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutAnalyticsTab(),
                _buildNutritionAnalyticsTab(),
                _buildFinanceAnalyticsTab(),
              ],
            ),
    );
  }

  // ---------------- WORKOUT ANALYTICS ----------------
  Widget _buildWorkoutAnalyticsTab() {
    final theme = Theme.of(context);
    final completedCount = _workoutPlans.where((p) => p.status == WorkoutStatus.completed).length;
    final totalPlanned = _workoutPlans.where((p) => p.status != WorkoutStatus.restDay).length;
    final completionRate = totalPlanned > 0 ? (completedCount / totalPlanned) : 0.0;
    
    final currentWeight = ProfileService.instance.weightKg;
    final targetWeight = ProfileService.instance.targetWeightKg;
    final weightHistory = ProfileService.instance.weightHistory;

    // Muscle group distribution
    final muscleCounts = <String, int>{};
    for (var plan in _workoutPlans) {
      for (var ex in plan.exercises) {
        final m = ex.targetMuscle;
        muscleCounts[m] = (muscleCounts[m] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Completion & Streak Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WEEKLY WORKOUT PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: AppColors.accentAmber, size: 18),
                        SizedBox(width: 4),
                        Text('4 Day Streak 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentAmber)),
                      ],
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
                          Text('$completedCount of $totalPlanned', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                          Text('Workouts completed this split', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(completionRate * 100).toStringAsFixed(0)}% Done',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accentGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Weight Progression Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BODYWEIGHT PROGRESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1.1)),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Log Today'),
                      onPressed: _logWeightDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile('Current', '${currentWeight.toStringAsFixed(1)} kg', AppColors.primaryGlow),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile('Target Goal', '${targetWeight.toStringAsFixed(1)} kg', AppColors.accentGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        'Difference',
                        '${(targetWeight - currentWeight).abs().toStringAsFixed(1)} kg ${targetWeight > currentWeight ? 'to gain' : 'to lose'}',
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Weight History List
                if (weightHistory.isNotEmpty) ...[
                  const Text('Recent Logged Points:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: weightHistory.reversed.take(6).map((item) {
                      return Chip(
                        label: Text('${item['weight']} kg (${item['date'].toString().split('T').first})', style: const TextStyle(fontSize: 11)),
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.08),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Muscle Group Distribution
          if (muscleCounts.isNotEmpty) ...[
            Text('Muscle-Group Volume Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: muscleCounts.entries.map((entry) {
                  final muscle = entry.key;
                  final count = entry.value;
                  final totalEx = _workoutPlans.fold(0, (s, p) => s + p.exercises.length);
                  final pct = totalEx > 0 ? (count / totalEx) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(muscle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('$count exercises (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- NUTRITION ANALYTICS ----------------
  Widget _buildNutritionAnalyticsTab() {
    final theme = Theme.of(context);
    final target = ProfileService.instance.nutritionTarget;

    // Aggregate meal records for last 7 days
    final now = DateTime.now();
    final last7Days = _mealRecords.where((m) => m.loggedAt.isAfter(now.subtract(const Duration(days: 7)))).toList();
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var m in last7Days) {
      totalCalories += m.totalCalories;
      totalProtein += m.totalProtein;
      totalCarbs += m.totalCarbs;
      totalFat += m.totalFat;
    }

    final avgCalories = last7Days.isNotEmpty ? totalCalories / 7 : 0.0;
    final avgProtein = last7Days.isNotEmpty ? totalProtein / 7 : 0.0;
    final avgCarbs = last7Days.isNotEmpty ? totalCarbs / 7 : 0.0;
    final avgFat = last7Days.isNotEmpty ? totalFat / 7 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-DAY DAILY NUTRITION AVERAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 1.1)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${avgCalories.toStringAsFixed(0)} ', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    Text('/ ${target.calorieTarget.toStringAsFixed(0)} kcal target', style: TextStyle(fontSize: 14, color: theme.hintColor)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: target.calorieTarget > 0 ? (avgCalories / target.calorieTarget).clamp(0.0, 1.0) : 0.0,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('Average Macro Intake vs Goals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildMacroComparisonCard('Protein', avgProtein, target.proteinTargetGrams, AppColors.accentGreen, 'g'),
          const SizedBox(height: 8),
          _buildMacroComparisonCard('Carbohydrates', avgCarbs, target.carbTargetGrams, AppColors.accentAmber, 'g'),
          const SizedBox(height: 8),
          _buildMacroComparisonCard('Fats', avgFat, target.fatTargetGrams, AppColors.accentRose, 'g'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- FINANCE ANALYTICS ----------------
  Widget _buildFinanceAnalyticsTab() {
    final theme = Theme.of(context);
    final curSym = ProfileService.instance.currencySymbol;

    double income = 0;
    double expenses = 0;
    for (var t in _expenses) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['is_income'] == 1 || t['is_income'] == true) {
        income += amt;
      } else {
        expenses += amt;
      }
    }
    final netSavings = income - expenses;
    final savingsRate = income > 0 ? (netSavings / income).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LIFETIME WEALTH & SAVINGS RATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$curSym ${netSavings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        Text('Net Accumulation', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${(savingsRate * 100).toStringAsFixed(0)}% Saved', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _buildMetricTile('Total Inflow', '$curSym ${income.toStringAsFixed(0)}', AppColors.accentGreen)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Total Outflow', '$curSym ${expenses.toStringAsFixed(0)}', AppColors.accentRose)),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMacroComparisonCard(String name, double currentAvg, double targetVal, Color color, String unit) {
    final theme = Theme.of(context);
    final pct = targetVal > 0 ? (currentAvg / targetVal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              Text(
                '${currentAvg.toStringAsFixed(1)} / ${targetVal.toStringAsFixed(0)}$unit (${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
