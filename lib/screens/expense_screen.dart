import 'package:flutter/material.dart';
import '../main.dart';
import '../db_helper.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../widgets/titan_ai_sheet.dart';

/// Redesigned Cyber-Neon Expense Tracker with Smart Calculations & AI Insights
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food & Dining 🍽️';
  final List<String> _categories = [
    'Food & Dining 🍽️',
    'Gym & Supplements 🏋️',
    'Living & Rent 🏠',
    'Bills & Utilities 📱',
    'Shopping & Fun 🛍️',
    'Books & Learning 📚',
    'Travel & Commute 🚗',
    'Other / Personal 💡',
  ];

  String _selectedNecessity = 'Essential Need 🟢';
  final List<String> _necessityOptions = [
    'Essential Need 🟢',
    'Discretionary Want 🟡',
    'Impulsive Waste 🔴',
  ];

  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    AppSyncBus.syncTick.addListener(_fetchExpenses);
  }

  @override
  void dispose() {
    AppSyncBus.syncTick.removeListener(_fetchExpenses);
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchExpenses() async {
    final data = await DBHelper.instance.fetchExpenses();
    if (mounted) setState(() => _expenses = data);
  }

  int get _daysLeftInMonth {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return (lastDay - now.day + 1).clamp(1, 31);
  }

  double get _totalSpentThisMonth {
    final now = DateTime.now();
    double total = 0.0;
    for (var e in _expenses) {
      if (e['date'] != null) {
        final d = DateTime.tryParse(e['date'].toString());
        if (d != null && d.year == now.year && d.month == now.month) {
          total += (e['amount'] as num).toDouble();
          continue;
        }
      }
      total += (e['amount'] as num).toDouble();
    }
    return total;
  }

  double get _monthlyBudget => AuthService.instance.currentUser.monthlyExpenseBudget;

  double get _remainingBudget => (_monthlyBudget - _totalSpentThisMonth).clamp(0.0, double.infinity);

  double get _safeDailyAllowance => _daysLeftInMonth > 0 ? (_remainingBudget / _daysLeftInMonth) : 0.0;

  double get _budgetBurnPercentage => _monthlyBudget > 0 ? (_totalSpentThisMonth / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

  void _addExpense() async {
    final item = _itemController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (item.isNotEmpty && amount > 0) {
      await DBHelper.instance.insertExpense({
        'item': '$item [$_selectedNecessity]',
        'category': _selectedCategory,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
      _itemController.clear();
      _amountController.clear();
      _fetchExpenses();

      if (mounted) {
        DisciplineFeedback.showCelebration(
          context: context,
          title: '💼 Expense Logged!',
          message: '₹${amount.toInt()} for "$item" tracked under $_selectedCategory.\nRemaining safe daily limit: ₹${_safeDailyAllowance.toStringAsFixed(0)}/day.',
          disciplineQuote: 'Rule No. 1: Never lose money. Rule No. 2: Never forget rule No. 1.',
          color: _selectedNecessity.contains('Waste') ? AppColors.accentRose : AppColors.accentGreen,
          icon: Icons.account_balance_wallet_rounded,
        );
      }
    }
  }

  void _deleteExpense(Map<String, dynamic> exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accentRose, width: 1.2)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Entry?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(
          'Remove "${exp['item']}" of ₹${exp['amount']} (${exp['category']})?',
          style: const TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () async {
              Navigator.pop(ctx);
              if (exp['id'] != null) {
                await DBHelper.instance.deleteExpense(exp['id'] as int);
                _fetchExpenses();
              }
            },
            child: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog() {
    final budgetCtrl = TextEditingController(text: _monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.secondary)),
        title: const Row(
          children: [
            Icon(Icons.savings_rounded, color: AppColors.secondary, size: 22),
            SizedBox(width: 8),
            Text('Set Monthly Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set your monthly spending ceiling to calculate daily allowances and prevent lifestyle creep.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Budget (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final newB = double.tryParse(budgetCtrl.text.trim()) ?? _monthlyBudget;
              await AuthService.instance.updateProfile(monthlyBudget: newB);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }

  void _runAIFinancialAudit() async {
    final prompt = 'Audit my monthly financial spending: Budget: ₹${_monthlyBudget.toInt()}, Spent: ₹${_totalSpentThisMonth.toInt()}, Remaining: ₹${_remainingBudget.toInt()}, Safe Daily Allowance: ₹${_safeDailyAllowance.toStringAsFixed(0)}/day. Give me 3 strict money-saving rules.';
    TitanAICoachSheet.show(context, initialPrompt: prompt);
  }

  Color _getCategoryColor(String cat) {
    if (cat.contains('Food')) return AppColors.accentGreen;
    if (cat.contains('Gym')) return AppColors.primaryGlow;
    if (cat.contains('Living')) return AppColors.accentBlue;
    if (cat.contains('Bills')) return AppColors.accentAmber;
    if (cat.contains('Shopping')) return AppColors.accentRose;
    if (cat.contains('Books')) return AppColors.accentPurple;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final burnPercent = _budgetBurnPercentage;
    final burnColor = burnPercent > 0.85
        ? AppColors.accentRose
        : (burnPercent > 0.6 ? AppColors.accentAmber : AppColors.accentGreen);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SMART FINANCIAL CALCULATION DASHBOARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF261320), Color(0xFF131D33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: burnColor.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(color: burnColor.withValues(alpha: 0.12), blurRadius: 16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Budget Setting Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentRose, size: 20),
                        SizedBox(width: 8),
                        Text('MONTHLY WEALTH & BUDGET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.accentRose, letterSpacing: 1.0)),
                      ],
                    ),
                    InkWell(
                      onTap: _showSetBudgetDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: AppColors.secondary, size: 14),
                            const SizedBox(width: 4),
                            Text('Budget: ₹${_monthlyBudget.toInt()}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Numbers Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL SPENT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('₹${_totalSpentThisMonth.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: burnColor)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('REMAINING BUDGET', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('₹${_remainingBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Linear Budget Gauge
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: burnPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(burnColor),
                  ),
                ),
                const SizedBox(height: 12),

                // Daily Safe Allowance Chip Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, color: AppColors.accentGreen, size: 16),
                          const SizedBox(width: 6),
                          Text('Safe Daily Allowance ($_daysLeftInMonth days left):', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                      Text(
                        '₹${_safeDailyAllowance.toStringAsFixed(0)} / day',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accentGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // AI Financial Audit Action Banner
          InkWell(
            onTap: _runAIFinancialAudit,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Run Titan AI Financial Leak & Savings Audit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. LOG NEW EXPENSE FORM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log New Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemController,
                        decoration: const InputDecoration(labelText: 'Expense Item (e.g. Whey Protein / Groceries)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '₹ Amount'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val ?? _categories[0]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedNecessity,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        decoration: const InputDecoration(labelText: 'Necessity'),
                        items: _necessityOptions.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedNecessity = val ?? _necessityOptions[0]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
                    onPressed: _addExpense,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Add Expense & Recalculate Burn Rate'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. LOGGED EXPENSE HISTORY LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EXPENSE TRANSACTIONS (${_expenses.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted)),
              if (_expenses.isNotEmpty)
                Text('Total: ₹${_totalSpentThisMonth.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
            ],
          ),
          const SizedBox(height: 8),

          if (_expenses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text('No expenses logged this month. You are maintaining complete financial discipline! 💰', textAlign: TextAlign.center, style: TextStyle(color: AppColors.accentGreen, fontSize: 12.5)),
              ),
            )
          else
            ..._expenses.map((exp) {
              final cat = exp['category']?.toString() ?? 'Other';
              final color = _getCategoryColor(cat);
              final amt = (exp['amount'] as num?)?.toDouble() ?? 0.0;
              final dateStr = exp['date'] != null ? DateTime.tryParse(exp['date'].toString()) : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payments_rounded, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp['item']?.toString() ?? 'Expense', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(cat, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
                              if (dateStr != null) ...[
                                const SizedBox(width: 6),
                                Text('• ${dateStr.day}/${dateStr.month}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accentRose)),
                    const SizedBox(width: 4),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                      tooltip: 'Delete transaction',
                      onPressed: () => _deleteExpense(exp),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
