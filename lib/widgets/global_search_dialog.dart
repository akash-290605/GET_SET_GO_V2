import 'package:flutter/material.dart';
import '../db_helper.dart';
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

  List<Map<String, dynamic>> _goals = [];
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
      final g = await DBHelper.instance.getGoals();
      final e = await DBHelper.instance.getExpenses();
      if (mounted) {
        setState(() {
          _goals = g;
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

    final matchingGoals = q.isEmpty
        ? <Map<String, dynamic>>[]
        : _goals
            .where((g) =>
                (g['title']?.toString().toLowerCase().contains(q) ?? false) ||
                (g['category']?.toString().toLowerCase().contains(q) ?? false))
            .take(5)
            .toList();

    final matchingExpenses = q.isEmpty
        ? <Map<String, dynamic>>[]
        : _expenses
            .where((e) =>
                (e['item']?.toString().toLowerCase().contains(q) ?? false) ||
                (e['category']?.toString().toLowerCase().contains(q) ?? false))
            .take(5)
            .toList();

    final matchingSubjects = q.isEmpty
        ? <StudySubject>[]
        : StudyEnglishService.instance.subjects
            .where((s) => s.name.toLowerCase().contains(q) || s.topics.any((t) => t.title.toLowerCase().contains(q)))
            .toList();

    final matchingWords = q.isEmpty
        ? <EnglishVocabularyWord>[]
        : StudyEnglishService.instance.vocabularyList
            .where((w) => w.word.toLowerCase().contains(q) || w.meaning.toLowerCase().contains(q))
            .take(5)
            .toList();

    final hasResults = matchingGoals.isNotEmpty ||
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
            Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primaryGlow),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search goals, expenses, study & English...',
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
                                  Text('Type a keyword to instantly search goals, finance, study & English.',
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
                                  if (matchingGoals.isNotEmpty) ...[
                                    _buildCategoryHeader('🎯 STRICT GOALS & HABITS', AppColors.accentRose),
                                    ...matchingGoals.map((g) => _buildResultTile(
                                          title: g['title']?.toString() ?? 'Goal',
                                          subtitle: '${g['currentStreak'] ?? 0} day streak • Target: ${g['targetDays'] ?? 0} days',
                                          icon: Icons.flag_rounded,
                                          color: AppColors.accentRose,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(1);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  if (matchingExpenses.isNotEmpty) ...[
                                    _buildCategoryHeader('💰 FINANCE & EXPENSES', AppColors.secondary),
                                    ...matchingExpenses.map((exp) => _buildResultTile(
                                          title: exp['item']?.toString() ?? 'Expense',
                                          subtitle: '${exp['category']} • ₹${(exp['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                          icon: Icons.account_balance_wallet_rounded,
                                          color: AppColors.secondary,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(2);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  if (matchingSubjects.isNotEmpty) ...[
                                    _buildCategoryHeader('📚 STUDY SUBJECTS', AppColors.accentAmber),
                                    ...matchingSubjects.map((sub) => _buildResultTile(
                                          title: sub.name,
                                          subtitle: '${sub.topics.length} topics • ${(sub.completionProgress * 100).toStringAsFixed(0)}% done',
                                          icon: Icons.school_rounded,
                                          color: AppColors.accentAmber,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(3);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],

                                  if (matchingWords.isNotEmpty) ...[
                                    _buildCategoryHeader('🇬🇧 ENGLISH VOCABULARY', AppColors.primaryGlow),
                                    ...matchingWords.map((v) => _buildResultTile(
                                          title: v.word,
                                          subtitle: v.meaning,
                                          icon: Icons.menu_book_rounded,
                                          color: AppColors.primaryGlow,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onNavigateTab?.call(4);
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
