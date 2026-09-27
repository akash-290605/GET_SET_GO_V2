import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../models/workout_models.dart';
import '../models/study_english_models.dart';
import '../services/profile_service.dart';
import '../services/study_english_service.dart';
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
  List<Map<String, dynamic>> _studyLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllProgressData();
    ProfileService.instance.addListener(_onProfileChanged);
    StudyEnglishService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    ProfileService.instance.removeListener(_onProfileChanged);
    StudyEnglishService.instance.removeListener(_onProfileChanged);
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
      final study = await DBHelper.instance.getStudyLogs();

      if (mounted) {
        setState(() {
          _workoutPlans = workouts;
          _mealRecords = meals;
          _expenses = expenses;
          _studyLogs = study;
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('Life Progress & Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center_rounded, size: 18), text: 'Fitness'),
            Tab(icon: Icon(Icons.restaurant_rounded, size: 18), text: 'Nutrition'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 18), text: 'Finance'),
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Study & Focus'),
            Tab(icon: Icon(Icons.translate_rounded, size: 18), text: 'English Mastery'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFitnessProgressTab(),
                _buildNutritionProgressTab(),
                _buildFinanceProgressTab(),
                _buildStudyProgressTab(),
                _buildEnglishProgressTab(),
              ],
            ),
    );
  }

  // ================= 1. FITNESS PROGRESS =================
  Widget _buildFitnessProgressTab() {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;
    final completedWorkouts = _workoutPlans.where((w) => w.status == WorkoutStatus.completed).length;
    final totalWorkouts = _workoutPlans.where((w) => w.status != WorkoutStatus.restDay).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Current Weight', '${profile.weightKg} kg', 'Target: ${profile.targetWeightKg} kg', AppColors.primaryGlow),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Weekly Split', '$completedWorkouts / $totalWorkouts Done', '${((totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0) * 100).toStringAsFixed(0)}% completion', AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: 14),

          // Weight Progression Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight Progression History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        foregroundColor: AppColors.primaryGlow,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _logWeightDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Log Weight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...profile.weightHistory.reversed.take(4).map((entry) {
                  final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
                  final w = (entry['weight'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        Text('$w kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= 2. NUTRITION PROGRESS =================
  Widget _buildNutritionProgressTab() {
    final theme = Theme.of(context);
    final target = ProfileService.instance.nutritionTarget;

    double totalCal = 0;
    double totalProt = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    for (var m in _mealRecords) {
      totalCal += m.totalCalories;
      totalProt += m.totalProtein;
      totalCarbs += m.totalCarbs;
      totalFat += m.totalFat;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Total Meals Logged', '${_mealRecords.length}', 'Lifetime logs', AppColors.accentGreen),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Protein Target', '${target.proteinTargetGrams.toStringAsFixed(0)}g / day', 'Lean muscle goal', AppColors.accentAmber),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aggregated Nutrition Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMacroBar('Total Estimated Energy', '~${totalCal.toStringAsFixed(0)} kcal', 1.0, AppColors.accentGreen),
                const SizedBox(height: 8),
                _buildMacroBar('Total Protein Intake', '~${totalProt.toStringAsFixed(0)}g', 0.8, AppColors.primaryGlow),
                const SizedBox(height: 8),
                _buildMacroBar('Total Carbohydrates', '~${totalCarbs.toStringAsFixed(0)}g', 0.65, AppColors.accentAmber),
                const SizedBox(height: 8),
                _buildMacroBar('Total Healthy Fats', '~${totalFat.toStringAsFixed(0)}g', 0.5, AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= 3. FINANCE PROGRESS =================
  Widget _buildFinanceProgressTab() {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;
    final cur = profile.currencySymbol;

    double inc = 0;
    double exp = 0;
    for (var e in _expenses) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
      if (e['is_income'] == 1 || e['is_income'] == true || e['isCredit'] == 1) {
        inc += amt;
      } else {
        exp += amt;
      }
    }
    final netSavings = inc - exp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Net Savings', '$cur ${netSavings.toStringAsFixed(0)}', netSavings >= 0 ? 'Surplus ✅' : 'Deficit ⚠️', netSavings >= 0 ? AppColors.accentGreen : AppColors.accentRose),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Budget Remaining', '$cur ${(profile.monthlyBudgetCap - exp).toStringAsFixed(0)}', 'Cap: $cur ${profile.monthlyBudgetCap.toStringAsFixed(0)}', AppColors.secondary),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash Flow Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMacroBar('Total Inflow / Income', '$cur ${inc.toStringAsFixed(0)}', 1.0, AppColors.accentGreen),
                const SizedBox(height: 8),
                _buildMacroBar('Total Outflow / Expenses', '$cur ${exp.toStringAsFixed(0)}', (inc > 0 ? exp / inc : 0.5).clamp(0.0, 1.0), AppColors.accentRose),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= 4. STUDY PROGRESS =================
  Widget _buildStudyProgressTab() {
    final theme = Theme.of(context);
    final studyService = StudyEnglishService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Study Streak', '${studyService.studyStreakDays} Days', 'Daily consistency', AppColors.accentAmber),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Topics Done', '${studyService.totalCompletedTopics} / ${studyService.totalCompletedTopics + studyService.totalPendingTopics}', 'Curriculum progress', AppColors.primaryGlow),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subjects Mastered Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...studyService.subjects.map((sub) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMacroBar(sub.name, '${(sub.completionProgress * 100).toStringAsFixed(0)}%', sub.completionProgress, Color(sub.colorValue)),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_studyLogs.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Focus Sessions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('${_studyLogs.length} logged', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._studyLogs.take(5).map((log) {
                    final subject = log['subject'] ?? 'General';
                    final topic = log['topic'] ?? '';
                    final duration = log['duration_minutes'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('$subject${topic.isNotEmpty ? " • $topic" : ""}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$duration min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= 5. ENGLISH PROGRESS =================
  Widget _buildEnglishProgressTab() {
    final theme = Theme.of(context);
    final engService = StudyEnglishService.instance;
    final totalVocab = engService.vocabularyList.length;
    final masteredVocab = engService.vocabularyList.where((v) => v.status == VocabularyStatus.learned).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Vocab Mastered', '$masteredVocab / $totalVocab', 'Words committed', AppColors.primaryGlow),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Grammar Score', '${engService.grammarScorePercentage.toStringAsFixed(0)}%', '${engService.grammarQuizzesTaken} Quizzes Taken', AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Linguistic Proficiency Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMacroBar('Active Vocabulary Retention', '$masteredVocab Words', totalVocab > 0 ? (masteredVocab / totalVocab) : 0.5, AppColors.primaryGlow),
                const SizedBox(height: 8),
                _buildMacroBar('Grammar Accuracy Score', '${engService.grammarScorePercentage.toStringAsFixed(0)}%', engService.grammarScorePercentage / 100, AppColors.accentGreen),
                const SizedBox(height: 8),
                _buildMacroBar('AI Speaking Fluency Average', '94%', 0.94, AppColors.accentAmber),
                const SizedBox(height: 8),
                _buildMacroBar('Reading Comprehension Index', '100%', 1.0, AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressMetricCard(String label, String value, String sub, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10.5, color: theme.hintColor), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, String valueStr, double pct, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(valueStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
