import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/study_english_models.dart';
import '../services/profile_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _deletedGoals = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _studyLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final goals = await DBHelper.instance.getGoals();
      final deleted = await DBHelper.instance.getDeletedGoals();
      final expenses = await DBHelper.instance.getExpenses();
      final study = await DBHelper.instance.getStudyLogs();

      if (mounted) {
        setState(() {
          _goals = goals;
          _deletedGoals = deleted;
          _expenses = expenses;
          _studyLogs = study;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'Goals & Discipline'),
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
                _buildGoalsProgressTab(),
                _buildFinanceProgressTab(),
                _buildStudyProgressTab(),
                _buildEnglishProgressTab(),
              ],
            ),
    );
  }

  Widget _buildGoalsProgressTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ProfileService.instance;
    final maxStreak = _goals.fold<int>(0, (prev, g) {
      final s = (g['currentStreak'] as num?)?.toInt() ?? 0;
      return s > prev ? s : prev;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressMetricCard('Active Strict Goals', '${_goals.length}', 'Unbreakable streak', AppColors.accentRose),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Best Streak', '$maxStreak Days', 'Consecutive days', AppColors.accentAmber),
            ],
          ),
          const SizedBox(height: 14),

          GlassCard(
            borderColor: AppColors.accentRose.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Discipline Protocol Execution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
                const SizedBox(height: 12),
                _buildMacroBar('Daily Step Target', '${profile.todaySteps} / ${profile.dailyStepTarget} steps', (profile.dailyStepTarget > 0 ? profile.todaySteps / profile.dailyStepTarget : 0.0), AppColors.accentBlue),
                const SizedBox(height: 10),
                _buildMacroBar('Active Time Target', '${profile.todayActiveTimeMinutes} / ${profile.dailyActiveTimeMinutesTarget} mins', (profile.dailyActiveTimeMinutesTarget > 0 ? profile.todayActiveTimeMinutes / profile.dailyActiveTimeMinutesTarget : 0.0), AppColors.purple),
                const SizedBox(height: 10),
                _buildMacroBar('Hydration Target', '${(profile.todayWaterIntakeMl / 1000).toStringAsFixed(2)} / ${(profile.dailyWaterIntakeMlTarget / 1000).toStringAsFixed(1)} L', (profile.dailyWaterIntakeMlTarget > 0 ? profile.todayWaterIntakeMl / profile.dailyWaterIntakeMlTarget : 0.0), AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_goals.isNotEmpty)
            GlassCard(
              borderColor: AppColors.primaryGlow.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Commitments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
                      Text('${_goals.length} ongoing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._goals.map((g) {
                    final title = g['title'] ?? 'Goal';
                    final streak = g['currentStreak'] ?? 0;
                    final target = g['targetDays'] ?? 30;
                    final progress = target > 0 ? (streak / target).clamp(0.0, 1.0) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildMacroBar(title, '$streak / $target days', progress, AppColors.accentRose),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 14),

          if (_deletedGoals.isNotEmpty)
            GlassCard(
              borderColor: AppColors.accentRose.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sentiment_very_dissatisfied_rounded, color: AppColors.accentRose, size: 18),
                      const SizedBox(width: 8),
                      Text('Accountability Archive (${_deletedGoals.length} Apologies)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Failed commitments and formal handwritten apologies submitted before deletion.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(isDark))),
                  const SizedBox(height: 10),
                  ..._deletedGoals.take(3).map((dg) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dg['title'] ?? 'Deleted Goal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentRose)),
                          const SizedBox(height: 3),
                          Text(dg['apologyLetter'] ?? '', style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textPrimary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis),
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

  Widget _buildFinanceProgressTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

          GlassCard(
            borderColor: AppColors.secondary.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash Flow Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
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

  Widget _buildStudyProgressTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

          GlassCard(
            borderColor: AppColors.accentAmber.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subjects Mastered Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
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
            GlassCard(
              borderColor: AppColors.primaryGlow.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Focus Sessions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
                      Text('${_studyLogs.length} logged', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._studyLogs.take(5).map((log) {
                    final subject = log['subject'] ?? 'General';
                    final topic = log['topic'] ?? '';
                    final duration = log['timeSpent'] ?? '30 mins';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('$subject${topic.isNotEmpty ? " • $topic" : ""}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$duration', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
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

  Widget _buildEnglishProgressTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Linguistic Proficiency Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
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
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: GlassCard(
        borderColor: color.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary(isDark)), overflow: TextOverflow.ellipsis),
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
