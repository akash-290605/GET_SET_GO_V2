import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_helper.dart';
import '../services/gemini_service.dart';

class ExpenseScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ExpenseScreen({super.key, this.onBack});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  double _targetMonthlyCap = 20000.0;
  static const String _targetCapKey = 'gsg_target_expense_cap_v1';

  final List<String> _debitCategories = [
    'Food & Dining',
    'Gym & Fitness',
    'Rent & Utilities',
    'Shopping',
    'Transport & Fuel',
    'Entertainment',
    'Healthcare',
    'Education',
    'Other Expense',
  ];

  final List<String> _creditCategories = [
    'Salary / Job',
    'Freelance / Client',
    'Business / Sales',
    'Investments / Stocks',
    'Gift / Cashback',
    'Other Income',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCap = prefs.getDouble(_targetCapKey);
      if (savedCap != null && savedCap > 0) {
        _targetMonthlyCap = savedCap;
      }

      final records = await DBHelper.instance.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(records);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalDebited {
    double sum = 0;
    for (final item in _expenses) {
      final isCredit = (item['isCredit'] ?? 0) == 1;
      if (!isCredit) {
        sum += ((item['amount'] as num?) ?? 0).toDouble();
      }
    }
    return sum;
  }

  double get _totalCredited {
    double sum = 0;
    for (final item in _expenses) {
      final isCredit = (item['isCredit'] ?? 0) == 1;
      if (isCredit) {
        sum += ((item['amount'] as num?) ?? 0).toDouble();
      }
    }
    return sum;
  }

  double get _netBalance => _totalCredited - _totalDebited;

  double get _safeDailySpend {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDayOfMonth - now.day + 1).clamp(1, 31);
    final remainingBudget = (_targetMonthlyCap - _totalDebited).clamp(0.0, double.infinity);
    return remainingBudget / remainingDays;
  }

  Future<void> _deleteExpense(int id) async {
    await DBHelper.instance.deleteExpense(id);
    _loadData();
  }

  void _showSetTargetDialog() {
    final controller = TextEditingController(text: _targetMonthlyCap.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18223C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.track_changes_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 10),
            Text(
              'Set Target Expense Cap',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your maximum monthly spending threshold. Titan AI will dynamically compute your Safe Daily Spend allowance.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF11182B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: Color(0xFF8B5CF6), fontSize: 16, fontWeight: FontWeight.bold),
                  hintText: '20000',
                  hintStyle: TextStyle(color: Colors.white30),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? _targetMonthlyCap;
              if (val > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble(_targetCapKey, val);
                setState(() => _targetMonthlyCap = val);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Cap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal() {
    bool isCredit = false;
    final payeeController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = _debitCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          const surface = Color(0xFF11182B);
          const surfaceElevated = Color(0xFF18223C);
          const primary = Color(0xFF8B5CF6);
          const green = Color(0xFF10B981);
          const rose = Color(0xFFF43F5E);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Transaction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  isCredit = false;
                                  selectedCategory = _debitCategories.first;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isCredit ? rose.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isCredit ? rose.withValues(alpha: 0.8) : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.arrow_downward_rounded, color: Color(0xFFF43F5E), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Debited (- Expense)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  isCredit = true;
                                  selectedCategory = _creditCategories.first;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCredit ? green.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCredit ? green.withValues(alpha: 0.8) : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Credited (+ Income)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Amount (₹)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                            color: isCredit ? green : rose,
                          ),
                          hintText: '0.00',
                          hintStyle: const TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isCredit ? 'Source / Payer / Debtor Name' : 'Payee / Creditor / Store Name',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: payeeController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: primary, size: 20),
                          hintText: isCredit ? 'e.g. Monthly Salary, Freelance Client' : 'e.g. Amazon, Grocery, John Trainer',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Category', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          dropdownColor: surfaceElevated,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                          items: (isCredit ? _creditCategories : _debitCategories)
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Notes / Remarks (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: notesController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Additional details or memo...',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 12.5),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCredit ? green : primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          final amt = double.tryParse(amountController.text) ?? 0;
                          final payee = payeeController.text.trim();
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount.')),
                            );
                            return;
                          }

                          final now = DateTime.now();
                          await DBHelper.instance.insertExpense({
                            'name': payee.isNotEmpty ? payee : (isCredit ? 'Credit Entry' : 'Debit Entry'),
                            'amount': amt,
                            'category': selectedCategory,
                            'isCredit': isCredit ? 1 : 0,
                            'creditor': payee,
                            'notes': notesController.text.trim(),
                            'date': now.toIso8601String().substring(0, 10),
                            'timestamp': now.toIso8601String(),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadData();
                          }
                        },
                        child: Text(
                          isCredit ? 'Record Income (+ ₹${amountController.text.isEmpty ? '0' : amountController.text})' : 'Record Expense (- ₹${amountController.text.isEmpty ? '0' : amountController.text})',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _triggerAiExpenseAudit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18223C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: const [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Titan AI auditing expenses and analyzing 50/30/20 leaks...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final auditText = await GeminiService.instance.analyzeExpenses(
        expenses: _expenses,
        targetMonthlyCap: _targetMonthlyCap,
        totalCredited: _totalCredited,
        totalDebited: _totalDebited,
      );

      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF11182B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Titan AI Expense Reduction Report',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      auditText,
                      style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13.5, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audit error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF090D18);
    const surface = Color(0xFF11182B);
    const surfaceElevated = Color(0xFF18223C);
    const primary = Color(0xFF8B5CF6);
    const secondary = Color(0xFF06B6D4);
    const green = Color(0xFF10B981);
    const rose = Color(0xFFF43F5E);

    final debitedList = _expenses.where((e) => (e['isCredit'] ?? 0) == 0).toList();
    final creditedList = _expenses.where((e) => (e['isCredit'] ?? 0) == 1).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text(
              'FINANCE & CASHFLOW',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Set Target Cap',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: _showSetTargetDialog,
          ),
          IconButton(
            tooltip: 'AI Expense Audit',
            icon: const Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
            onPressed: _triggerAiExpenseAudit,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            const Tab(text: '📊 Overview'),
            Tab(text: '🔻 Debited (${debitedList.length})'),
            Tab(text: '🔺 Credited (${creditedList.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        onPressed: _showAddTransactionModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _netBalance >= 0
                                ? [const Color(0xFF065F46), const Color(0xFF047857)]
                                : [const Color(0xFF881337), const Color(0xFF9F1239)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (_netBalance >= 0 ? green : rose).withValues(alpha: 0.3),
                              blurRadius: 18,
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
                                const Text(
                                  'NET CASH BALANCE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Colors.white70,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _netBalance >= 0 ? 'Surplus' : 'Deficit',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_netBalance >= 0 ? '+' : '-'} ₹${_netBalance.abs().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: green.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.arrow_upward_rounded, color: green, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Credited (+)',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${_totalCredited.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: rose.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.arrow_downward_rounded, color: rose, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Debited (-)',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${_totalDebited.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: rose),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Monthly Target Spend Cap',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                Text(
                                  '₹${_totalDebited.toStringAsFixed(0)} / ₹${_targetMonthlyCap.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF06B6D4)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (_totalDebited / (_targetMonthlyCap > 0 ? _targetMonthlyCap : 1)).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: surfaceElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _totalDebited > _targetMonthlyCap ? rose : primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: secondary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: secondary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Safe Daily Spend Allowance',
                                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '₹${_safeDailySpend.toStringAsFixed(0)} / day',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: secondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _triggerAiExpenseAudit,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Audit', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                debitedList.isEmpty
                    ? _buildEmptyState('No debited expenses logged yet.', Icons.receipt_long_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: debitedList.length,
                        itemBuilder: (context, index) {
                          final item = debitedList[index];
                          return _buildTransactionTile(item, false);
                        },
                      ),
                creditedList.isEmpty
                    ? _buildEmptyState('No credited income logged yet.', Icons.savings_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: creditedList.length,
                        itemBuilder: (context, index) {
                          final item = creditedList[index];
                          return _buildTransactionTile(item, true);
                        },
                      ),
              ],
            ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> item, bool isCredit) {
    const surfaceElevated = Color(0xFF18223C);
    const green = Color(0xFF10B981);
    const rose = Color(0xFFF43F5E);
    final amt = ((item['amount'] as num?) ?? 0).toDouble();
    final name = (item['name'] as String?) ?? 'Entry';
    final creditor = (item['creditor'] as String?) ?? '';
    final category = (item['category'] as String?) ?? 'General';
    final date = (item['date'] as String?) ?? '';
    final id = item['id'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? green : rose).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isCredit ? green : rose,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creditor.isNotEmpty ? creditor : name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} ₹${amt.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isCredit ? green : rose,
                ),
              ),
              if (id != null)
                InkWell(
                  onTap: () => _deleteExpense(id),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white30),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }
}
