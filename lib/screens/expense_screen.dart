import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _filter = 'This Month'; // 'Today', 'This Week', 'This Month', 'Last Month', 'All'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
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

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await DBHelper.instance.getExpenses();
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      final dateStr = t['date'] as String? ?? '';
      final date = DateTime.tryParse(dateStr) ?? now;

      if (_filter == 'Today') {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_filter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek);
      } else if (_filter == 'This Month') {
        return date.year == now.year && date.month == now.month;
      } else if (_filter == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonth.year && date.month == lastMonth.month;
      }
      return true;
    }).toList();
  }

  double get _totalIncome {
    return _filteredTransactions
        .where((t) => (t['is_income'] == 1 || t['is_income'] == true))
        .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
  }

  double get _totalExpenses {
    return _filteredTransactions
        .where((t) => (t['is_income'] == 0 || t['is_income'] == false || t['is_income'] == null))
        .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
  }

  Map<String, double> get _categorySpending {
    final map = <String, double>{};
    for (var t in _filteredTransactions) {
      if (t['is_income'] == 0 || t['is_income'] == false || t['is_income'] == null) {
        final cat = t['category'] as String? ?? 'General';
        final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
        map[cat] = (map[cat] ?? 0.0) + amt;
      }
    }
    return map;
  }

  List<Map<String, dynamic>> get _recurringExpenses {
    return _transactions.where((t) => (t['is_recurring'] == 1 || t['is_recurring'] == true)).toList();
  }

  void _addOrEditTransactionDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: item?['title'] ?? item?['description'] ?? '');
    final amountCtrl = TextEditingController(text: item != null ? item['amount'].toString() : '');
    String category = item?['category'] ?? 'Food';
    String paymentMethod = item?['payment_method'] ?? 'UPI / Card';
    bool isIncome = item?['is_income'] == 1 || item?['is_income'] == true;
    bool isRecurring = item?['is_recurring'] == 1 || item?['is_recurring'] == true;
    DateTime selectedDate = item?['date'] != null ? (DateTime.tryParse(item!['date']) ?? DateTime.now()) : DateTime.now();

    final categories = isIncome
        ? ['Salary', 'Freelance', 'Investment', 'Gift', 'Other Income']
        : ['Food', 'Groceries', 'Fitness & Gym', 'Rent & Bills', 'Entertainment', 'Transport', 'Shopping', 'Subscriptions', 'Healthcare', 'Education', 'Miscellaneous'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final curSym = ProfileService.instance.currencySymbol;
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income / Expense Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Expense'),
                          selected: !isIncome,
                          selectedColor: AppColors.accentRose.withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) {
                              setDlgState(() {
                                isIncome = false;
                                category = 'Food';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Income'),
                          selected: isIncome,
                          selectedColor: AppColors.accentGreen.withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) {
                              setDlgState(() {
                                isIncome = true;
                                category = 'Salary';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Description / Payee', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount ($curSym)',
                      prefixText: '$curSym ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(category) ? category : categories.first,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                    items: ['UPI / Card', 'Cash', 'Bank Transfer', 'Credit Card', 'Wallet'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recurring (Monthly)', style: TextStyle(fontSize: 13.5)),
                    subtitle: const Text('e.g. Subscriptions, Gym membership, Rent', style: TextStyle(fontSize: 11)),
                    value: isRecurring,
                    onChanged: (val) => setDlgState(() => isRecurring = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isIncome ? AppColors.accentGreen : AppColors.primary),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (title.isEmpty || amt <= 0) return;

                  final payload = {
                    'title': title,
                    'amount': amt,
                    'category': category,
                    'payment_method': paymentMethod,
                    'is_income': isIncome ? 1 : 0,
                    'is_recurring': isRecurring ? 1 : 0,
                    'date': selectedDate.toIso8601String(),
                  };

                  if (isEdit) {
                    await DBHelper.instance.updateExpense(item['id'], payload);
                  } else {
                    await DBHelper.instance.insertExpense(payload);
                  }

                  await _loadExpenses();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(dynamic id) async {
    await DBHelper.instance.deleteExpense(id);
    await _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => _addOrEditTransactionDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview & Spending'),
            Tab(icon: Icon(Icons.repeat_rounded), text: 'Recurring & Bills'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRecurringTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final curSym = ProfileService.instance.currencySymbol;
    final income = _totalIncome;
    final expenses = _totalExpenses;
    final savings = income - expenses;
    final budgetCap = ProfileService.instance.monthlyBudgetCap;
    final budgetRemaining = (budgetCap - expenses).clamp(0.0, double.infinity);
    final budgetUsagePercent = (budgetCap > 0 ? (expenses / budgetCap) : 0.0).clamp(0.0, 1.0);

    // Safe Daily Spend Allowance Calculation
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);
    final safeDailySpend = budgetRemaining / daysRemaining;

    final categories = _categorySpending;
    final transactions = _filteredTransactions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'This Week', 'This Month', 'Last Month', 'All'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: AppColors.secondary,
                    onSelected: (val) {
                      if (val) setState(() => _filter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Main Balance & Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('NET SAVINGS (${_filter.toUpperCase()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (savings >= 0 ? AppColors.accentGreen : AppColors.accentRose).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        savings >= 0 ? 'Surplus' : 'Deficit',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: savings >= 0 ? AppColors.accentGreen : AppColors.accentRose),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$curSym ${savings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: savings >= 0 ? Colors.white : AppColors.accentRose,
                  ),
                ),
                const SizedBox(height: 16),

                // Income vs Expense Row
                Row(
                  children: [
                    Expanded(
                      child: _buildBalancePill(
                        label: 'Total Income',
                        amount: '$curSym ${income.toStringAsFixed(0)}',
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBalancePill(
                        label: 'Total Expenses',
                        amount: '$curSym ${expenses.toStringAsFixed(0)}',
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.accentRose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Budget & Safe Daily Spend Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Budget Cap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('$curSym ${budgetCap.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Safe Daily Spend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                        const SizedBox(height: 2),
                        Text('$curSym ${safeDailySpend.toStringAsFixed(0)} / day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accentGreen)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: budgetUsagePercent,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(budgetUsagePercent >= 0.9 ? AppColors.accentRose : AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(budgetUsagePercent * 100).toStringAsFixed(0)}% used • $curSym ${budgetRemaining.toStringAsFixed(0)} remaining across $daysRemaining days',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Breakdown
          if (categories.isNotEmpty) ...[
            Text('Spending by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                children: categories.entries.map((entry) {
                  final catName = entry.key;
                  final catAmt = entry.value;
                  final catPct = expenses > 0 ? (catAmt / expenses) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('$curSym ${catAmt.toStringAsFixed(0)} (${(catPct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: catPct,
                            minHeight: 6,
                            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(catName)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Transactions List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions (${transactions.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                onPressed: () => _addOrEditTransactionDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Transactions List
          if (transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('No transactions recorded for $_filter', style: TextStyle(color: theme.hintColor)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                final isInc = item['is_income'] == 1 || item['is_income'] == true;
                final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                final dateStr = item['date'] as String? ?? '';
                final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isInc ? AppColors.accentGreen : AppColors.accentRose).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isInc ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
                        color: isInc ? AppColors.accentGreen : AppColors.accentRose,
                        size: 20,
                      ),
                    ),
                    title: Text(item['title'] ?? item['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${item['category'] ?? 'General'} • ${DateFormat('dd MMM, hh:mm a').format(date)}', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isInc ? '+' : '-'}$curSym ${amt.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isInc ? AppColors.accentGreen : AppColors.accentRose,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _addOrEditTransactionDialog(item);
                            } else if (val == 'delete') {
                              _deleteTransaction(item['id']);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.accentRose))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRecurringTab() {
    final theme = Theme.of(context);
    final curSym = ProfileService.instance.currencySymbol;
    final recurring = _recurringExpenses;
    final recurringTotal = recurring.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));

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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MONTHLY RECURRING COMMITMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Text('$curSym ${recurringTotal.toStringAsFixed(0)} / month', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Includes gym memberships, streaming subscriptions, broadband & fixed rent.', style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (recurring.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.repeat_rounded, size: 48, color: theme.hintColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No recurring expenses marked', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Toggle "Recurring" when adding a transaction to track fixed monthly bills.', style: TextStyle(fontSize: 12, color: theme.hintColor), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recurring.length,
              itemBuilder: (context, index) {
                final item = recurring[index];
                final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x2206B6D4),
                      child: Icon(Icons.repeat_rounded, color: AppColors.secondary, size: 20),
                    ),
                    title: Text(item['title'] ?? item['description'] ?? 'Recurring Bill', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['category'] ?? 'Subscriptions', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                    trailing: Text('$curSym ${amt.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBalancePill({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'groceries':
        return AppColors.accentAmber;
      case 'fitness & gym':
        return AppColors.primary;
      case 'rent & bills':
        return AppColors.accentBlue;
      case 'entertainment':
      case 'subscriptions':
        return AppColors.accentRose;
      case 'transport':
        return AppColors.secondary;
      default:
        return AppColors.accentPurple;
    }
  }
}
