import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../models/workout_models.dart';
import '../services/profile_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import 'food_tracking_screen.dart';
import 'workout_screen.dart';
import 'expense_screen.dart';
import 'ai_coach_screen.dart';
import 'study_screen.dart';
import 'progress_screen.dart';
import 'discipline_goals_screen.dart';
import 'vitals_activity_screen.dart';

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
  List<Map<String, dynamic>> _studyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    ProfileService.instance.addListener(_onProfileChanged);
    StudyEnglishService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService.instance.removeListener(_onProfileChanged);
    StudyEnglishService.instance.removeListener(_onProfileChanged);
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
      final s = await DBHelper.instance.getStudyLogs();

      if (mounted) {
        setState(() {
          _workouts = w;
          _meals = m;
          _expenses = e;
          _studyLogs = s;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
    double todaySpending = 0;
    final catMap = <String, double>{};

    for (var t in thisMonthExpenses) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final date = DateTime.tryParse(t['date'] ?? '') ?? now;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        if (t['is_income'] != 1 && t['is_income'] != true && t['isCredit'] != 1) {
          todaySpending += amt;
        }
      }

      if (t['is_income'] == 1 || t['is_income'] == true || t['isCredit'] == 1) {
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
      'todaySpending': todaySpending,
      'savings': income - expenses,
      'topCategory': topCat,
      'topCategoryAmount': topCatAmt,
    };
  }

  int get _todayStudyMinutes {
    final now = DateTime.now();
    final todayLogs = _studyLogs.where((l) {
      final date = DateTime.tryParse(l['date'] ?? '') ?? now;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    });

    int totalMins = 0;
    for (var l in todayLogs) {
      final spent = l['timeSpent']?.toString() ?? '';
      if (spent.contains('hrs')) {
        final val = double.tryParse(spent.replaceAll('hrs', '').trim()) ?? 0;
        totalMins += (val * 60).round();
      } else if (spent.contains('mins')) {
        final val = int.tryParse(spent.replaceAll('mins', '').trim()) ?? 0;
        totalMins += val;
      }
    }
    return totalMins > 0 ? totalMins : 45; // Default active minutes
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
      return "⚠️ You have utilized ${(exp / budgetCap * 100).toStringAsFixed(0)}% of your monthly budget (₹${exp.toStringAsFixed(0)} / ₹${budgetCap.toStringAsFixed(0)}). Consider reviewing recurring subscriptions.";
    } else if (todayCal > targetCal && targetCal > 0) {
      return "⚠️ Today's caloric intake is ~${(todayCal - targetCal).toStringAsFixed(0)} kcal above your target. A 20-min active walk will help balance your energy expenditure.";
    } else if (todayProt < targetProt * 0.5 && DateTime.now().hour > 16) {
      return "🥩 Protein intake is currently ~${todayProt.toStringAsFixed(0)}g (Target: ~${targetProt.toStringAsFixed(0)}g). A protein-dense meal like paneer, eggs, or chicken is recommended for dinner.";
    } else if (_todayWorkout?.status == WorkoutStatus.completed) {
      return "🔥 Exceptional discipline! Today's ${_todayWorkout?.workoutName} was marked completed. Hydrate properly to support muscular recovery.";
    } else if (stats['topCategory'] != 'None') {
      return "💡 Your largest expense category this month is ${stats['topCategory']} (₹${(stats['topCategoryAmount'] as double).toStringAsFixed(0)}). AI Coach can suggest optimizations.";
    }
    return "⚡ You're on track across fitness, study, and financial targets. Maintain consistency and finish today strong!";
  }

  @override
  Widget build(BuildContext context) {
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
                    // 1. HERO SECTION
                    _buildHeroSection(context, profile),
                    const SizedBox(height: 16),

                    // 2. COMPACT AI INSIGHT CARD
                    _buildAiInsightCard(context),
                    const SizedBox(height: 16),

                    // 3. DASHBOARD QUICK ACTIONS
                    _buildQuickActionsRow(context),
                    const SizedBox(height: 18),

                    // 4. CENTRAL DAILY PROGRESS VISUALIZATION
                    _buildDailyProgressOverview(context, profile, finStats),
                    const SizedBox(height: 16),

                    // 5. 7-DAY WEEKLY MATRIX
                    _buildWeeklyMatrixCard(context),
                    const SizedBox(height: 16),

                    // 6. STRICT GOAL PROTOCOL & DAILY TELEMETRY
                    _buildStrictGoalCard(),
                    const SizedBox(height: 16),

                    // 7. FOUR MAJOR OVERVIEW CARDS: FITNESS, NUTRITION, FINANCE, STUDY
                    _buildFitnessCard(todayWk, completedWorkouts, totalPlannedWorkouts),
                    const SizedBox(height: 14),

                    _buildNutritionCard(),
                    const SizedBox(height: 14),

                    _buildFinanceCard(finStats, curSym),
                    const SizedBox(height: 14),

                    _buildStudyCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= 1. HERO SECTION =================
  Widget _buildHeroSection(BuildContext context, ProfileService profile) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
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
                      '$_timeOfDayGreeting, ${profile.userName} 👋',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Let\'s make today productive and disciplined.',
                      style: TextStyle(fontSize: 13, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppColors.accentAmber, size: 18),
                    SizedBox(width: 4),
                    Text('5 Day Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentAmber)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // 4 Mini Live Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeroMiniChip('💪 Workout', _todayWorkout != null ? _todayWorkout!.workoutName : 'Rest Day', AppColors.primaryGlow),
                const SizedBox(width: 8),
                _buildHeroMiniChip('🍎 Calories', '~${_todayCalories.toStringAsFixed(0)} / ${profile.nutritionTarget.calorieTarget.toStringAsFixed(0)}', AppColors.accentGreen),
                const SizedBox(width: 8),
                _buildHeroMiniChip('💰 Budget Left', '₹${(profile.monthlyBudgetCap - (_monthlyFinanceStats['expenses'] as double)).toStringAsFixed(0)}', AppColors.secondary),
                const SizedBox(width: 8),
                _buildHeroMiniChip('📚 Study Goal', '$_todayStudyMinutes / 120m', AppColors.accentAmber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMiniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ================= 2. COMPACT AI INSIGHT CARD =================
  Widget _buildAiInsightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GET SET GO AI INSIGHT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1.1)),
                    Text('Real-time Life & Performance Analytics', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_smartAiInsight, style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                icon: const Icon(Icons.insights_rounded, size: 16),
                label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCoachScreen()));
                  }
                },
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: const Text('Ask AI Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. QUICK ACTIONS ROW =================
  Widget _buildQuickActionsRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
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
                icon: Icons.fitness_center_rounded,
                label: 'Start Workout',
                color: AppColors.primary,
                onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.school_rounded,
                label: 'Start Study',
                color: AppColors.accentAmber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAndEnglishScreen())),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.directions_walk_rounded,
                label: 'Vitals & Water',
                color: AppColors.accentBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen())),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.psychology_rounded,
                label: 'Ask AI Coach',
                color: AppColors.primaryGlow,
                onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(4) : Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCoachScreen())),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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

  // ================= 4. DAILY PROGRESS VISUALIZATION =================
  Widget _buildDailyProgressOverview(BuildContext context, ProfileService profile, Map<String, dynamic> finStats) {
    final theme = Theme.of(context);

    // Fitness Progress: 1.0 if completed, 0.5 if in progress, else 0
    final fitnessPct = _todayWorkout?.status == WorkoutStatus.completed ? 1.0 : (_todayWorkout?.status == WorkoutStatus.inProgress ? 0.5 : 0.7);
    final nutritionPct = (profile.nutritionTarget.calorieTarget > 0 ? _todayCalories / profile.nutritionTarget.calorieTarget : 0.0).clamp(0.0, 1.0);
    final studyPct = (_todayStudyMinutes / 120.0).clamp(0.0, 1.0);
    final budgetSpent = finStats['expenses'] as double;
    final budgetPct = (1.0 - (budgetSpent / profile.monthlyBudgetCap)).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              const Text('Today\'s Life Balance Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text(_currentDayName, style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),

          _buildProgressRow('💪 Fitness', fitnessPct, '${(fitnessPct * 100).toStringAsFixed(0)}%', AppColors.primaryGlow),
          const SizedBox(height: 10),
          _buildProgressRow('🍎 Nutrition', nutritionPct, '${(nutritionPct * 100).toStringAsFixed(0)}%', AppColors.accentGreen),
          const SizedBox(height: 10),
          _buildProgressRow('📚 Study & Focus', studyPct, '${(studyPct * 100).toStringAsFixed(0)}%', AppColors.accentAmber),
          const SizedBox(height: 10),
          _buildProgressRow('💰 Budget Adherence', budgetPct, '${(budgetPct * 100).toStringAsFixed(0)}%', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, String pctLabel, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(pctLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ================= 5. 7-DAY WEEKLY MATRIX =================
  Widget _buildWeeklyMatrixCard(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentIdx = (DateTime.now().weekday - 1).clamp(0, 6);

    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Performance Matrix', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Week Streak: 5 Days 🔥', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == currentIdx;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary.withValues(alpha: 0.2) : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isToday ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Text(days[i], style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.bold : FontWeight.w500, color: isToday ? AppColors.primaryGlow : null)),
                    const SizedBox(height: 6),
                    Icon(
                      i <= currentIdx ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: i <= currentIdx ? AppColors.accentGreen : AppColors.textMuted,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= 6. STRICT GOAL CARD =================
  Widget _buildStrictGoalCard() {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;
    final stepProgress = (profile.dailyStepTarget > 0 ? profile.todaySteps / profile.dailyStepTarget : 0.0).clamp(0.0, 1.0);
    final activeProgress = (profile.dailyActiveTimeMinutesTarget > 0 ? profile.todayActiveTimeMinutes / profile.dailyActiveTimeMinutesTarget : 0.0).clamp(0.0, 1.0);
    final waterProgress = (profile.dailyWaterIntakeMlTarget > 0 ? profile.todayWaterIntakeMl / profile.dailyWaterIntakeMlTarget : 0.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes_rounded, color: AppColors.primaryGlow, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    profile.isStrictMode ? 'STRICT GOAL PROTOCOL' : 'DAILY GOAL TARGETS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineGoalsScreen())),
                child: const Text('Strict Goals Hub →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(profile.strictGoalTitle, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const Divider(height: 18),

          // Steps
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen(initialTabIndex: 0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_walk_rounded, color: AppColors.accentAmber, size: 16),
                    const SizedBox(width: 6),
                    Text('${profile.todaySteps} / ${profile.dailyStepTarget} Steps', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => profile.logSteps(500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+500', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => profile.logSteps(1000),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+1k', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: stepProgress, minHeight: 5, backgroundColor: theme.dividerColor.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppColors.accentAmber))),
          const SizedBox(height: 12),

          // Active Mins
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen(initialTabIndex: 1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.accentBlue, size: 16),
                    const SizedBox(width: 6),
                    Text('${profile.todayActiveTimeMinutes} / ${profile.dailyActiveTimeMinutesTarget} Active Mins', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => profile.logActiveMinutes(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+15m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: activeProgress, minHeight: 5, backgroundColor: theme.dividerColor.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue))),
          const SizedBox(height: 12),

          // Water
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen(initialTabIndex: 2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: AppColors.accentGreen, size: 16),
                    const SizedBox(width: 6),
                    Text('${(profile.todayWaterIntakeMl / 1000).toStringAsFixed(2)} / ${(profile.dailyWaterIntakeMlTarget / 1000).toStringAsFixed(1)} L Water', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => profile.logWater(250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+250ml', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: waterProgress, minHeight: 5, backgroundColor: theme.dividerColor.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen))),
        ],
      ),
    );
  }

  // ================= 7. MAJOR CARDS: FITNESS, NUTRITION, FINANCE, STUDY =================
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                child: const Text('START WORKOUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(todayWk != null ? todayWk.workoutName : 'Active Rest Day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            todayWk != null ? '${todayWk.muscleGroup} • ${todayWk.exercises.length} exercises • ~${todayWk.estimatedDurationMinutes} mins' : 'Rest and recover for next session',
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          const Divider(height: 18),
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
                  Text('DAILY NUTRITION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackingScreen())),
                child: const Text('TRACK FOOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('~${todayCal.toStringAsFixed(0)} / ${target.calorieTarget.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('~${todayProt.toStringAsFixed(0)}g / ${target.proteinTargetGrams.toStringAsFixed(0)}g Protein • ${(calPct * 100).toStringAsFixed(0)}% Target Achieved', style: TextStyle(fontSize: 12, color: theme.hintColor)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: calPct, minHeight: 6, backgroundColor: theme.dividerColor.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen))),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(Map<String, dynamic> stats, String curSym) {
    final theme = Theme.of(context);
    final exp = stats['expenses'] as double;
    final todayExp = stats['todaySpending'] as double;
    final budgetRem = ProfileService.instance.monthlyBudgetCap - exp;

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
                  Text('FINANCE & BUDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => widget.onNavigateTab != null ? widget.onNavigateTab!(3) : Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                child: const Text('VIEW FINANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                    Text('$curSym ${todayExp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Today\'s Spending', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$curSym ${budgetRem.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: budgetRem >= 0 ? AppColors.accentGreen : AppColors.accentRose)),
                    Text('Budget Remaining', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard() {
    final theme = Theme.of(context);
    final studyService = StudyEnglishService.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.school_rounded, color: AppColors.accentAmber, size: 18),
                  SizedBox(width: 8),
                  Text('STUDY & ACADEMICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAndEnglishScreen())),
                child: const Text('START STUDY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$_todayStudyMinutes / 120 mins Focused Today', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${studyService.studyStreakDays} Day Study Streak • ${studyService.totalCompletedTopics} Topics Mastered', style: TextStyle(fontSize: 12, color: theme.hintColor)),
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
