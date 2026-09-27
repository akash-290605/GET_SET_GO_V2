import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_models.dart';

class FinanceService extends ChangeNotifier {
  static final FinanceService _instance = FinanceService._internal();
  static FinanceService get instance => _instance;
  FinanceService._internal();

  List<FinanceTransaction> _transactions = [];
  TransactionPeriod _selectedPeriod = TransactionPeriod.thisMonth;
  DateTimeRange? _customRange;
  double _monthlyBudget = 25000.0;

  List<FinanceTransaction> get allTransactions => _transactions;
  TransactionPeriod get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customRange => _customRange;
  double get monthlyBudget => _monthlyBudget;

  // Filtered transactions by selected period
  List<FinanceTransaction> get filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((tx) {
      switch (_selectedPeriod) {
        case TransactionPeriod.today:
          return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
        case TransactionPeriod.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return tx.date.isAfter(startDay.subtract(const Duration(seconds: 1)));
        case TransactionPeriod.thisMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case TransactionPeriod.lastMonth:
          final prevMonth = now.month == 1 ? 12 : now.month - 1;
          final prevYear = now.month == 1 ? now.year - 1 : now.year;
          return tx.date.year == prevYear && tx.date.month == prevMonth;
        case TransactionPeriod.custom:
          if (_customRange == null) return true;
          return tx.date.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
                 tx.date.isBefore(_customRange!.end.add(const Duration(days: 1)));
        case TransactionPeriod.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => filteredTransactions
      .where((tx) => tx.isCredit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => filteredTransactions
      .where((tx) => !tx.isCredit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get netSavings => totalIncome - totalExpense;

  double get budgetRemaining => (_monthlyBudget - totalExpense).clamp(0, double.infinity);

  double get budgetUsageRatio => _monthlyBudget > 0 ? (totalExpense / _monthlyBudget).clamp(0.0, 2.0) : 0.0;

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (var tx in filteredTransactions.where((t) => !t.isCredit)) {
      map[tx.category] = (map[tx.category] ?? 0.0) + tx.amount;
    }
    return map;
  }

  String get topSpendingCategory {
    final breakdown = categoryBreakdown;
    if (breakdown.isEmpty) return 'None';
    var sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<FinanceTransaction> get recurringTransactions =>
      _transactions.where((t) => t.isRecurring).toList();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('finance_transactions_list');
      if (savedJson != null) {
        final List<dynamic> decoded = json.decode(savedJson);
        _transactions = decoded.map((e) => FinanceTransaction.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        _transactions = _getDefaultTransactions();
        await _saveTransactions();
      }
      _monthlyBudget = prefs.getDouble('finance_monthly_budget') ?? 25000.0;
    } catch (e) {
      debugPrint('FinanceService init error: $e');
      _transactions = _getDefaultTransactions();
    }
    notifyListeners();
  }

  void setPeriod(TransactionPeriod period, {DateTimeRange? custom}) {
    _selectedPeriod = period;
    _customRange = custom;
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('finance_monthly_budget', _monthlyBudget);
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  Future<void> addTransaction(FinanceTransaction tx) async {
    _transactions.insert(0, tx);
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> updateTransaction(FinanceTransaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _transactions[idx] = updated;
      notifyListeners();
      await _saveTransactions();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTransactions();
  }

  // Deterministic AI Financial Audit Analysis
  List<FinanceAuditFlag> generateAuditReport() {
    final flags = <FinanceAuditFlag>[];
    final now = DateTime.now();

    // Current Month expenses by category
    final curExpenses = <String, double>{};
    final curCounts = <String, int>{};
    for (var tx in _transactions.where((t) => !t.isCredit && t.date.year == now.year && t.date.month == now.month)) {
      curExpenses[tx.category] = (curExpenses[tx.category] ?? 0.0) + tx.amount;
      curCounts[tx.category] = (curCounts[tx.category] ?? 0) + 1;
    }

    // Previous Month expenses by category
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevExpenses = <String, double>{};
    for (var tx in _transactions.where((t) => !t.isCredit && t.date.year == prevYear && t.date.month == prevMonth)) {
      prevExpenses[tx.category] = (prevExpenses[tx.category] ?? 0.0) + tx.amount;
    }

    // Evaluate categories with notable increases
    curExpenses.forEach((cat, curAmt) {
      final prevAmt = prevExpenses[cat] ?? 0.0;
      final count = curCounts[cat] ?? 1;

      if (prevAmt > 0 && curAmt > prevAmt) {
        final pct = ((curAmt - prevAmt) / prevAmt) * 100;
        if (pct >= 20.0) {
          final potentialSaving = (curAmt - prevAmt) * 0.5;
          flags.add(FinanceAuditFlag(
            category: cat,
            reason: '$cat spending increased by ${pct.toStringAsFixed(0)}% compared with last month across $count transactions. Moderating discretionary orders can trim high-frequency leakage.',
            currentPeriodAmount: curAmt,
            previousPeriodAmount: prevAmt,
            percentageChange: pct,
            potentialMonthlySaving: potentialSaving,
            severity: pct > 40 ? 'action' : 'warning',
          ));
        }
      } else if (cat.toLowerCase().contains('food') || cat.toLowerCase().contains('dining') || cat.toLowerCase().contains('entertainment')) {
        if (curAmt > 3000) {
          flags.add(FinanceAuditFlag(
            category: cat,
            reason: 'High discretionary volume logged (₹${curAmt.toStringAsFixed(0)}). Meal prepping and batch grocery purchases can reliably recover ₹800–₹1,500/month.',
            currentPeriodAmount: curAmt,
            previousPeriodAmount: prevAmt,
            percentageChange: 0,
            potentialMonthlySaving: 1000.0,
            severity: 'warning',
          ));
        }
      }
    });

    // Subscriptions check
    final subscriptions = _transactions.where((t) => t.isRecurring && !t.isCredit).toList();
    if (subscriptions.isNotEmpty) {
      final subTotal = subscriptions.fold(0.0, (s, t) => s + t.amount);
      flags.add(FinanceAuditFlag(
        category: 'Recurring Subscriptions',
        reason: 'Active recurring subscriptions total ₹${subTotal.toStringAsFixed(0)}/month across ${subscriptions.length} services (${subscriptions.map((s) => s.title).join(", ")}). Audit unutilized memberships.',
        currentPeriodAmount: subTotal,
        previousPeriodAmount: subTotal,
        percentageChange: 0,
        potentialMonthlySaving: subTotal * 0.35,
        severity: 'info',
      ));
    }

    return flags;
  }

  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_transactions.map((t) => t.toMap()).toList());
      await prefs.setString('finance_transactions_list', encoded);
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  List<FinanceTransaction> _getDefaultTransactions() {
    final now = DateTime.now();
    return [
      FinanceTransaction(
        id: 'tx_1',
        title: 'Monthly Salary Credit',
        amount: 45000.0,
        category: 'Salary',
        date: DateTime(now.year, now.month, 1),
        isCredit: true,
        partyName: 'TechCorp Pvt Ltd',
        paymentMethod: 'Bank Transfer',
        isRecurring: true,
        notes: 'Monthly corporate payroll credit',
      ),
      FinanceTransaction(
        id: 'tx_2',
        title: 'Apartment Rent & Maintenance',
        amount: 9500.0,
        category: 'Housing',
        date: DateTime(now.year, now.month, 2),
        isCredit: false,
        partyName: 'Landlord (Ramesh)',
        paymentMethod: 'UPI',
        isRecurring: true,
        notes: 'Monthly rental lease',
      ),
      FinanceTransaction(
        id: 'tx_3',
        title: 'Whole Foods & Nutrition Grocery',
        amount: 2850.0,
        category: 'Groceries',
        date: DateTime(now.year, now.month, 4),
        isCredit: false,
        partyName: 'SuperMart Chennai',
        paymentMethod: 'Card',
        isRecurring: false,
        notes: 'Eggs, oats, chicken breast, peanut butter, greens',
      ),
      FinanceTransaction(
        id: 'tx_4',
        title: 'Whey Protein Isolate (2kg)',
        amount: 3400.0,
        category: 'Fitness & Health',
        date: DateTime(now.year, now.month, 7),
        isCredit: false,
        partyName: 'NutraHub Store',
        paymentMethod: 'UPI',
        isRecurring: false,
        notes: 'Nutritional replenishment',
      ),
      FinanceTransaction(
        id: 'tx_5',
        title: 'Zomato Food Delivery',
        amount: 680.0,
        category: 'Food & Dining',
        date: DateTime(now.year, now.month, 10),
        isCredit: false,
        partyName: 'Spice Garden Resto',
        paymentMethod: 'UPI',
        isRecurring: false,
        notes: 'Weekend dinner',
      ),
      FinanceTransaction(
        id: 'tx_6',
        title: 'Freelance Mobile App Dev',
        amount: 8500.0,
        category: 'Freelance',
        date: DateTime(now.year, now.month, 12),
        isCredit: true,
        partyName: 'Client (Stellar Labs)',
        paymentMethod: 'UPI',
        isRecurring: false,
        notes: 'UI sprint milestone delivery',
      ),
      FinanceTransaction(
        id: 'tx_7',
        title: 'Spotify Premium & Cloud Storage',
        amount: 299.0,
        category: 'Subscriptions',
        date: DateTime(now.year, now.month, 14),
        isCredit: false,
        partyName: 'Spotify India',
        paymentMethod: 'Card',
        isRecurring: true,
        notes: 'Monthly auto-debit',
      ),
    ];
  }
}
