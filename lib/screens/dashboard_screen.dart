import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../services/profile_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';
import 'expense_screen.dart';
import 'ai_coach_screen.dart';
import 'study_screen.dart';
import 'english_learning_screen.dart';
import 'progress_screen.dart';
import 'discipline_goals_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goals = [];
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
      final g = await DBHelper.instance.getGoals();
      final e = await DBHelper.instance.getExpenses();
      final s = await DBHelper.instance.getStudyLogs();

      if (mounted) {
        setState(() {
          _goals = g;
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
    return totalMins > 0 ? totalMins : 45;
  }

  String get _smartAiInsight {
    final stats = _monthlyFinanceStats;
    final budgetCap = ProfileService.instance.monthlyBudgetCap;
    final exp = stats['expenses'] as double;
    final studyMins = _todayStudyMinutes;

    if (exp > budgetCap * 0.8) {
      return "⚠️ You have utilized ${(exp / budgetCap * 100).toStringAsFixed(0)}% of your monthly budget (₹${exp.toStringAsFixed(0)} / ₹${budgetCap.toStringAsFixed(0)}). Consider reviewing non-essential discretionary expenses.";
    } else if (studyMins < 60 && DateTime.now().hour > 17) {
      return "📚 You've completed $studyMins minutes of focused study today. Dedicate a 30-minute deep focus session this evening to hit your daily mastery goals.";
    } else if (_goals.isNotEmpty && (_goals.first['currentStreak'] as int? ?? 0) >= 7) {
      return "🔥 Outstanding momentum! You're on a ${_goals.first['currentStreak']}-day streak on your primary goal. Keep your discipline unbreakable today.";
    } else if (stats['topCategory'] != 'None') {
      return "💡 Your largest expense category this month is ${stats['topCategory']} (₹${(stats['topCategoryAmount'] as double).toStringAsFixed(0)}). AI Coach can suggest smart allocation tactics.";
    }
    return "⚡ You are on track across Strict Discipline Goals, Study Milestones, and Financial Budgets. Maintain focused execution and finish today strong!";
  }

  void _navigateToTab(int index, Widget fallbackScreen) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(index);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => fallbackScreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);
    final profile = ProfileService.instance;
    final curSym = profile.currencySymbol;
    final finStats = _monthlyFinanceStats;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    _buildHeroSection(context, profile, isDark),
                    const SizedBox(height: 16),

                    _buildAiInsightCard(context, isDark),
                    const SizedBox(height: 16),

                    _buildQuickActionsRow(context, isDark),
                    const SizedBox(height: 18),

                    _buildDailyProgressOverview(context, profile, finStats, isDark),
                    const SizedBox(height: 16),

                    _buildWeeklyMatrixCard(context, isDark),
                    const SizedBox(height: 16),

                    _buildStrictGoalCard(isDark),
                    const SizedBox(height: 16),

                    _buildStrictGoalsOverviewCard(isDark),
                    const SizedBox(height: 14),

                    _buildFinanceCard(finStats, curSym, isDark),
                    const SizedBox(height: 14),

                    _buildStudyCard(isDark),
                    const SizedBox(height: 14),

                    _buildEnglishCard(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ProfileService profile, bool isDark) {
    final maxStreak = _goals.fold<int>(0, (prev, g) {
      final s = (g['currentStreak'] as num?)?.toInt() ?? 0;
      return s > prev ? s : prev;
    });
    final displayStreak = maxStreak > 0 ? maxStreak : 5;

    return GlassCard(
      borderRadius: 20,
      gradient: LinearGradient(
        colors: isDark
            ? [
                AppColors.primary.withValues(alpha: 0.28),
                AppColors.secondary.withValues(alpha: 0.15),
              ]
            : [
                AppColors.primary.withValues(alpha: 0.10),
                AppColors.secondary.withValues(alpha: 0.06),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.20),
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Strict discipline, relentless learning, and financial freedom.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.accentAmber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$displayStreak Day Streak',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeroMiniChip(
                  '🎯 Goals',
                  '${_goals.length} Active Protocol',
                  AppColors.accentRose,
                  isDark,
                  onTap: () => _navigateToTab(1, const DisciplineGoalsScreen()),
                ),
                const SizedBox(width: 8),
                _buildHeroMiniChip(
                  '💰 Budget Left',
                  '₹${(profile.monthlyBudgetCap - (_monthlyFinanceStats['expenses'] as double)).toStringAsFixed(0)}',
                  AppColors.secondary,
                  isDark,
                  onTap: () => _navigateToTab(2, const ExpenseScreen()),
                ),
                const SizedBox(width: 8),
                _buildHeroMiniChip(
                  '📚 Study Goal',
                  '$_todayStudyMinutes / 120m',
                  AppColors.purple,
                  isDark,
                  onTap: () => _navigateToTab(3, const StudyAndEnglishScreen()),
                ),
                const SizedBox(width: 8),
                _buildHeroMiniChip(
                  '🇬🇧 English',
                  '${StudyEnglishService.instance.vocabularyList.length} Words',
                  AppColors.primaryGlow,
                  isDark,
                  onTap: () => _navigateToTab(4, const EnglishLearningScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMiniChip(String label, String value, Color color, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(BuildContext context, bool isDark) {
    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GET SET GO AI INSIGHT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1.1)),
                    Text(
                      'Real-time Discipline, Study & Finance Synergy',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _smartAiInsight,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary(isDark),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _navigateToTab(6, const ProgressScreen()),
                icon: const Icon(Icons.insights_rounded, size: 16),
                label: const Text('View Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _navigateToTab(5, const AiCoachScreen()),
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: const Text('Ask AI Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.track_changes_rounded,
                label: 'Strict Goals',
                color: AppColors.accentRose,
                isDark: isDark,
                onTap: () => _navigateToTab(1, const DisciplineGoalsScreen()),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.add_card_rounded,
                label: 'Add Expense',
                color: AppColors.secondary,
                isDark: isDark,
                onTap: () => _navigateToTab(2, const ExpenseScreen()),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.school_rounded,
                label: 'Start Study',
                color: AppColors.purple,
                isDark: isDark,
                onTap: () => _navigateToTab(3, const StudyAndEnglishScreen()),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.record_voice_over_rounded,
                label: 'English Speaking',
                color: AppColors.primaryGlow,
                isDark: isDark,
                onTap: () => _navigateToTab(4, const EnglishLearningScreen()),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.psychology_rounded,
                label: 'Ask AI Coach',
                color: AppColors.accentAmber,
                isDark: isDark,
                onTap: () => _navigateToTab(5, const AiCoachScreen()),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.analytics_rounded,
                label: 'Full Analytics',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () => _navigateToTab(6, const ProgressScreen()),
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 12,
      onTap: onTap,
      border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressOverview(BuildContext context, ProfileService profile, Map<String, dynamic> finStats, bool isDark) {
    final studyPct = (_todayStudyMinutes / 120.0).clamp(0.0, 1.0);
    final budgetSpent = finStats['expenses'] as double;
    final budgetPct = (1.0 - (budgetSpent / profile.monthlyBudgetCap)).clamp(0.0, 1.0);
    final goalsPct = _goals.isNotEmpty
        ? (_goals.where((g) => g['lastCompletedDate'] == DateTime.now().toIso8601String().substring(0, 10)).length / _goals.length).clamp(0.0, 1.0)
        : 0.8;
    final englishWordsCount = StudyEnglishService.instance.vocabularyList.length;
    final englishPct = (englishWordsCount / 30.0).clamp(0.0, 1.0);

    return GlassCard(
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Core Protocol Progress',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
              ),
              Text(
                _currentDayName,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildProgressRow('🎯 Strict Goals & Discipline', goalsPct, '${(goalsPct * 100).toStringAsFixed(0)}%', AppColors.accentRose, isDark),
          const SizedBox(height: 10),
          _buildProgressRow('💰 Budget Adherence', budgetPct, '${(budgetPct * 100).toStringAsFixed(0)}%', AppColors.secondary, isDark),
          const SizedBox(height: 10),
          _buildProgressRow('📚 Study & Academics', studyPct, '${(studyPct * 100).toStringAsFixed(0)}%', AppColors.purple, isDark),
          const SizedBox(height: 10),
          _buildProgressRow('🇬🇧 English Mastery', englishPct, '${(englishPct * 100).toStringAsFixed(0)}%', AppColors.primaryGlow, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, String pctLabel, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
            Text(pctLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyMatrixCard(BuildContext context, bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentIdx = (DateTime.now().weekday - 1).clamp(0, 6);

    return GlassCard(
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance Matrix',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
              ),
              const Text('Week Streak: 5 Days 🔥', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
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
                  color: isToday
                      ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? AppColors.primary : AppColors.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      i <= currentIdx ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: i <= currentIdx ? AppColors.accentGreen : AppColors.textSecondary(isDark),
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

  Widget _buildStrictGoalCard(bool isDark) {
    final profile = ProfileService.instance;
    final stepProgress = (profile.dailyStepTarget > 0 ? profile.todaySteps / profile.dailyStepTarget : 0.0).clamp(0.0, 1.0);
    final activeProgress = (profile.dailyActiveTimeMinutesTarget > 0 ? profile.todayActiveTimeMinutes / profile.dailyActiveTimeMinutesTarget : 0.0).clamp(0.0, 1.0);
    final waterProgress = (profile.dailyWaterIntakeMlTarget > 0 ? profile.todayWaterIntakeMl / profile.dailyWaterIntakeMlTarget : 0.0).clamp(0.0, 1.0);

    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    profile.isStrictMode ? 'STRICT GOAL PROTOCOL' : 'DAILY GOAL TARGETS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _navigateToTab(1, const DisciplineGoalsScreen()),
                child: const Text('Strict Goals Hub →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.strictGoalTitle,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk_rounded, color: AppColors.accentBlue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.todaySteps} / ${profile.dailyStepTarget} Steps',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => profile.logSteps(500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('+500', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => profile.logSteps(1000),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('+1k', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stepProgress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
              valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.purple, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.todayActiveTimeMinutes} / ${profile.dailyActiveTimeMinutesTarget} Active Mins',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => profile.logActiveMinutes(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('+15m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.purple)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activeProgress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined, color: AppColors.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${(profile.todayWaterIntakeMl / 1000).toStringAsFixed(2)} / ${(profile.dailyWaterIntakeMlTarget / 1000).toStringAsFixed(1)} L Water',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => profile.logWater(250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('+250ml', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: waterProgress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrictGoalsOverviewCard(bool isDark) {
    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.accentRose.withValues(alpha: isDark ? 0.3 : 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.accentRose, size: 18),
                  SizedBox(width: 8),
                  Text('STRICT GOALS & HABITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentRose, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _navigateToTab(1, const DisciplineGoalsScreen()),
                child: const Text('OPEN GOALS HUB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_goals.length} Active Strict Commitments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 2),
          Text(
            'Zero excuse rule: Deletion demands a formal 50-word handwritten apology',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Active Goals', '${_goals.length}', 'Tracked daily', isDark),
              _buildMiniMetric('Discipline Mode', 'STRICT', 'Uncompromising', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(Map<String, dynamic> stats, String curSym, bool isDark) {
    final exp = stats['expenses'] as double;
    final todayExp = stats['todaySpending'] as double;
    final budgetRem = ProfileService.instance.monthlyBudgetCap - exp;

    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.2)),
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
                  elevation: 0,
                ),
                onPressed: () => _navigateToTab(2, const ExpenseScreen()),
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
                    Text(
                      '$curSym ${todayExp.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                    ),
                    Text('Today\'s Spending', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(isDark))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$curSym ${budgetRem.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: budgetRem >= 0 ? AppColors.accentGreen : AppColors.accentRose,
                      ),
                    ),
                    Text('Budget Remaining', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(isDark))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard(bool isDark) {
    final studyService = StudyEnglishService.instance;

    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.purple.withValues(alpha: isDark ? 0.3 : 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.school_rounded, color: AppColors.purple, size: 18),
                  SizedBox(width: 8),
                  Text('STUDY & ACADEMICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _navigateToTab(3, const StudyAndEnglishScreen()),
                child: const Text('START STUDY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_todayStudyMinutes / 120 mins Focused Today',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 2),
          Text(
            '${studyService.studyStreakDays} Day Study Streak • ${studyService.totalCompletedTopics} Topics Mastered',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishCard(bool isDark) {
    final studyService = StudyEnglishService.instance;

    return GlassCard(
      borderRadius: 18,
      border: Border.all(color: AppColors.primaryGlow.withValues(alpha: isDark ? 0.3 : 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: AppColors.primaryGlow, size: 18),
                  SizedBox(width: 8),
                  Text('ENGLISH MASTERY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGlow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _navigateToTab(4, const EnglishLearningScreen()),
                child: const Text('PRACTICE NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${studyService.vocabularyList.length} Active Vocabulary Words',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 2),
          Text(
            'AI Speaking Practice, Live Conversations & Vocabulary Builder',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, String sub, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
        ),
        Text(sub, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary(isDark))),
      ],
    );
  }
}
