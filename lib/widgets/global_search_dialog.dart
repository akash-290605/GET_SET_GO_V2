import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../models/workout_models.dart';
import '../models/study_english_models.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';

class GlobalSearchDialog extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const GlobalSearchDialog({super.key, this.onNavigateTab});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  List<WorkoutDayPlan> _workouts = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final w = await DBHelper.instance.getWorkoutPlans();
      final e = await DBHelper.instance.getExpenses();
      if (mounted) {
        setState(() {
          _workouts = w;
          _expenses = e;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.toLowerCase().trim();

    // 1. Workouts / Exercises matching
    final matchingExercises = <Map<String, String>>[];
    for (var w in _workouts) {
      for (var ex in w.exercises) {
        if (q.isNotEmpty && (ex.name.toLowerCase().contains(q) || ex.targetMuscle.toLowerCase().contains(q))) {
          matchingExercises.add({
            'name': ex.name,
            'detail': '${w.dayName} • ${ex.targetMuscle} • ${ex.sets} sets × ${ex.reps}',
          });
        }
      }
    }

    // 2. Food Catalogue matching
    final matchingFoods = q.isEmpty
        ? <StandardFoodEntry>[]
        : StandardNutritionDatabase.allFoods
            .where((f) => f.name.toLowerCase().contains(q) || f.category.toLowerCase().contains(q))
            .take(5)
            .toList();

    // 3. Expenses matching
    final matchingExpenses = q.isEmpty
        ? <Map<String, dynamic>>[]
        : _expenses
            .where((e) =>
                (e['item']?.toString().toLowerCase().contains(q) ?? false) ||
                (e['category']?.toString().toLowerCase().contains(q) ?? false))
            .take(5)
            .toList();

    // 4. Study Subjects matching
    final matchingSubjects = q.isEmpty
        ? <StudySubject>[]
        : StudyEnglishService.instance.subjects
            .where((s) => s.name.toLowerCase().contains(q) || s.topics.any((t) => t.title.toLowerCase().contains(q)))
            .toList();

    // 5. English Words matching
    final matchingWords = q.isEmpty
        ? <EnglishVocabularyWord>[]
        : StudyEnglishService.instance.vocabularyList
            .where((w) => w.word.toLowerCase().contains(q) || w.meaning.toLowerCase().contains(q))
            .take(5)
            .toList();

    final hasResults = matchingExercises.isNotEmpty ||
        matchingFoods.isNotEmpty ||
        matchingExpenses.isNotEmpty ||
        matchingSubjects.isNotEmpty ||
        matchingWords.isNotEmpty;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Header
            Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primaryGlow),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search workouts, foods, expenses, study & English...',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Results List
            Flexible(
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : q.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.travel_explore_rounded, size: 44, color: theme.hintColor),
                                  const SizedBox(height: 8),
                                  Text('Type a keyword to instantly search across all modules.',
                                      style: TextStyle(fontSize: 13, color: theme.hintColor)),
                                ],
                              ),
                            ),
                          )
                        : !hasResults
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No matching items found for "$q"',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exercises
                                  if (matchingExercises.isNotEmpty) ...[
                                    _buildCategoryHeader('💪 FITNESS & EXERCISES', AppColors.primaryGlow),
                                    ...matchingExercises.map((e) => _buildResultTile(
                                          title: e['name']!,
                                          subtitle: e['detail']!,
                                          icon: Icons.fitness_center_rounded,
                                          color: AppColors.primary,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(1);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  // Foods
                                  if (matchingFoods.isNotEmpty) ...[
                                    _buildCategoryHeader('🍎 NUTRITION & FOODS', AppColors.accentGreen),
                                    ...matchingFoods.map((f) => _buildResultTile(
                                          title: f.name,
                                          subtitle: '${f.category} • ~${f.caloriesPerServing.toStringAsFixed(0)} kcal • ${f.proteinPerServing}g Protein',
                                          icon: Icons.restaurant_rounded,
                                          color: AppColors.accentGreen,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(2);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  // Expenses
                                  if (matchingExpenses.isNotEmpty) ...[
                                    _buildCategoryHeader('💰 FINANCE & TRANSACTIONS', AppColors.secondary),
                                    ...matchingExpenses.map((exp) => _buildResultTile(
                                          title: exp['item']?.toString() ?? 'Expense',
                                          subtitle: '${exp['category']} • ₹${(exp['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                          icon: Icons.account_balance_wallet_rounded,
                                          color: AppColors.secondary,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(5);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  // Study
                                  if (matchingSubjects.isNotEmpty) ...[
                                    _buildCategoryHeader('📚 STUDY SUBJECTS', AppColors.accentAmber),
                                    ...matchingSubjects.map((sub) => _buildResultTile(
                                          title: sub.name,
                                          subtitle: '${sub.topics.length} topics • ${(sub.completionProgress * 100).toStringAsFixed(0)}% done',
                                          icon: Icons.school_rounded,
                                          color: AppColors.accentAmber,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(6);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  // English Words
                                  if (matchingWords.isNotEmpty) ...[
                                    _buildCategoryHeader('🇬🇧 ENGLISH VOCABULARY', AppColors.accentRose),
                                    ...matchingWords.map((v) => _buildResultTile(
                                          title: v.word,
                                          subtitle: v.meaning,
                                          icon: Icons.menu_book_rounded,
                                          color: AppColors.accentRose,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(7);
                                          },
                                        )),
                                  ],
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.1)),
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

void showGlobalSearchDialog(BuildContext context, {Function(int tabIndex)? onNavigateTab}) {
  showDialog(
    context: context,
    builder: (_) => GlobalSearchDialog(onNavigateTab: onNavigateTab),
  );
}
