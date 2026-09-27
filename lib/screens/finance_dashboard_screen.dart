import 'package:flutter/material.dart';
import '../services/finance_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import '../models/finance_models.dart';
import '../widgets/titan_ai_sheet.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final finance = FinanceService.instance;
    final profile = ProfileService.instance.profile;
    final curr = profile.currencySymbol;

    return AnimatedBuilder(
      animation: finance,
      builder: (context, _) {
        final transactions = finance.filteredTransactions;
        final auditFlags = finance.generateAuditReport();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Finance & Expense Engine'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Edit Monthly Budget',
                onPressed: () => _showBudgetDialog(context, finance),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                tooltip: 'Ask Titan Finance Advisor',
                onPressed: () => TitanAiSheet.show(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Period Filter Pills
              _buildPeriodFilter(isDark, finance),
              const SizedBox(height: 16),

              // Executive Balance Card
              _buildBalanceCard(isDark, curr, finance),
              const SizedBox(height: 18),

              // Deterministic AI Spending Leak Audit Section
              if (auditFlags.isNotEmpty) ...[
                _buildAuditSection(isDark, curr, auditFlags),
                const SizedBox(height: 18),
              ],

              // Category Spending Breakdown
              _buildCategoryBreakdown(isDark, curr, finance),
              const SizedBox(height: 20),

              // Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRANSACTIONS (${transactions.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showTransactionModal(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transaction Items List
              if (transactions.isEmpty)
                _buildEmptyTransactions(isDark)
              else
                ...transactions.map((tx) => _buildTransactionTile(tx, isDark, curr, finance)),

              const SizedBox(height: 40),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: ThemeService.primaryEmerald,
            onPressed: () => _showTransactionModal(context),
          ),
        );
      },
    );
  }

  // 1. Period Filter Selector
  Widget _buildPeriodFilter(bool isDark, FinanceService finance) {
    const periods = [
      {'label': 'This Month', 'value': TransactionPeriod.thisMonth},
      {'label': 'This Week', 'value': TransactionPeriod.thisWeek},
      {'label': 'Today', 'value': TransactionPeriod.today},
      {'label': 'Last Month', 'value': TransactionPeriod.lastMonth},
      {'label': 'All Time', 'value': TransactionPeriod.all},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = finance.selectedPeriod == p['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['label'] as String, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: ThemeService.primaryCyan.withValues(alpha: 0.2),
              onSelected: (selected) {
                if (selected) {
                  finance.setPeriod(p['value'] as TransactionPeriod);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Executive Balance & Cashflow Card
  Widget _buildBalanceCard(bool isDark, String curr, FinanceService finance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
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
                  const Text('NET CASHFLOW / SAVINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(
                    '$curr${finance.netSavings.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: finance.netSavings >= 0 ? ThemeService.primaryEmerald : Colors.redAccent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Monthly Budget', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('$curr${finance.monthlyBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _flowBox(
                  title: 'Income (Credits)',
                  amount: '+$curr${finance.totalIncome.toStringAsFixed(0)}',
                  color: ThemeService.primaryEmerald,
                  icon: Icons.arrow_downward,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _flowBox(
                  title: 'Expenses (Debits)',
                  amount: '-$curr${finance.totalExpense.toStringAsFixed(0)}',
                  color: Colors.redAccent,
                  icon: Icons.arrow_upward,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. AI Spending Leak Audit Section
  Widget _buildAuditSection(bool isDark, String curr, List<FinanceAuditFlag> auditFlags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ThemeService.accentIndigo.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_fix_high, color: ThemeService.primaryCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'AI EXPENSE OPTIMIZATION & LEAK AUDIT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ThemeService.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...auditFlags.map((flag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: flag.severity == 'action' ? Colors.redAccent.withValues(alpha: 0.4) : (isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(flag.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (flag.potentialMonthlySaving > 0)
                        Text(
                          'Save ~$curr${flag.potentialMonthlySaving.toStringAsFixed(0)}/mo',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThemeService.primaryEmerald),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(flag.reason, style: const TextStyle(fontSize: 12, height: 1.4)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. Category Breakdown
  Widget _buildCategoryBreakdown(bool isDark, String curr, FinanceService finance) {
    final breakdown = finance.categoryBreakdown;
    final total = finance.totalExpense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SPENDING CATEGORY DISTRIBUTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Text('No expense transactions logged in this period.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...breakdown.entries.map((e) {
              final pct = total > 0 ? (e.value / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$curr${e.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9),
                        color: ThemeService.primaryCyan,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5. Individual Transaction Tile
  Widget _buildTransactionTile(FinanceTransaction tx, bool isDark, String curr, FinanceService finance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (tx.isCredit ? ThemeService.primaryEmerald : Colors.redAccent).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: tx.isCredit ? ThemeService.primaryEmerald : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tx.isRecurring) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThemeService.accentIndigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('RECURRING', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: ThemeService.accentIndigo)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${tx.category} • ${tx.partyName} • ${tx.paymentMethod}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.isCredit ? "+" : "-"}$curr${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: tx.isCredit ? ThemeService.primaryEmerald : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tx.date.day}/${tx.date.month}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (val) {
              if (val == 'edit') {
                _showTransactionModal(context, tx);
              } else if (val == 'delete') {
                finance.deleteTransaction(tx.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Transaction Creator / Editor Modal
  void _showTransactionModal(BuildContext context, [FinanceTransaction? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final partyCtrl = TextEditingController(text: existing?.partyName ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? 'Food & Dining');
    final methodCtrl = TextEditingController(text: existing?.paymentMethod ?? 'UPI');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    bool isCredit = existing?.isCredit ?? false;
    bool isRecurring = existing?.isRecurring ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing != null ? 'Edit Transaction' : 'Record Transaction',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Credit / Debit Segmented Selector
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Expense (Debit)'), icon: Icon(Icons.arrow_upward)),
                        ButtonSegment(value: true, label: Text('Income (Credit)'), icon: Icon(Icons.arrow_downward)),
                      ],
                      selected: {isCredit},
                      onSelectionChanged: (set) {
                        setModalState(() {
                          isCredit = set.first;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Description (e.g. Zomato Dinner)')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Creditor / Payer Name'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: methodCtrl, decoration: const InputDecoration(labelText: 'Payment Method (UPI, Card, Cash)'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Recurring Subscription / Fixed Expense', style: TextStyle(fontSize: 13)),
                      value: isRecurring,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() {
                          isRecurring = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCredit ? ThemeService.primaryEmerald : ThemeService.primaryCyan,
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                        if (titleCtrl.text.trim().isEmpty || amt <= 0) return;

                        final tx = FinanceTransaction(
                          id: existing?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          amount: amt,
                          category: categoryCtrl.text.trim().isNotEmpty ? categoryCtrl.text.trim() : 'Other',
                          date: existing?.date ?? DateTime.now(),
                          isCredit: isCredit,
                          partyName: partyCtrl.text.trim().isNotEmpty ? partyCtrl.text.trim() : 'Self',
                          paymentMethod: methodCtrl.text.trim().isNotEmpty ? methodCtrl.text.trim() : 'UPI',
                          isRecurring: isRecurring,
                          notes: notesCtrl.text.trim(),
                        );

                        if (existing != null) {
                          FinanceService.instance.updateTransaction(tx);
                        } else {
                          FinanceService.instance.addTransaction(tx);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(existing != null ? 'Update Transaction' : 'Save Transaction'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBudgetDialog(BuildContext context, FinanceService finance) {
    final ctrl = TextEditingController(text: finance.monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Budget Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final b = double.tryParse(ctrl.text) ?? 25000.0;
              finance.setMonthlyBudget(b);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _flowBox({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('No transactions recorded for this period. Tap "Add Transaction" to start tracking.'),
      ),
    );
  }
}
