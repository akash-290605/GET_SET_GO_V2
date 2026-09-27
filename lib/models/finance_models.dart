import 'dart:convert';

enum TransactionPeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  all,
  custom,
}

enum TransactionType {
  expense,
  income,
}

class FinanceTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isCredit; // true = Credit / Income, false = Debit / Expense
  final String partyName; // Name of Creditor / Debtor / Merchant / Source
  final String paymentMethod; // UPI, Cash, Card, Bank Transfer, Net Banking
  final bool isRecurring; // Subscriptions, SIP, Rent, Salary
  final String notes;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isCredit = false,
    this.partyName = 'Self / General',
    this.paymentMethod = 'UPI',
    this.isRecurring = false,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isCredit': isCredit ? 1 : 0,
      'partyName': partyName,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring ? 1 : 0,
      'notes': notes,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Untitled',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      category: map['category']?.toString() ?? 'Other',
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      isCredit: map['isCredit'] == 1 || map['isCredit'] == true || map['type'] == 'income',
      partyName: map['partyName']?.toString() ?? map['creditor']?.toString() ?? 'Self / General',
      paymentMethod: map['paymentMethod']?.toString() ?? 'UPI',
      isRecurring: map['isRecurring'] == 1 || map['isRecurring'] == true,
      notes: map['notes']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FinanceTransaction.fromJson(String source) =>
      FinanceTransaction.fromMap(json.decode(source));

  FinanceTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isCredit,
    String? partyName,
    String? paymentMethod,
    bool? isRecurring,
    String? notes,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isCredit: isCredit ?? this.isCredit,
      partyName: partyName ?? this.partyName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
    );
  }
}

class CategoryBudget {
  final String category;
  final double budgetAmount;
  final double spentAmount;

  CategoryBudget({
    required this.category,
    required this.budgetAmount,
    this.spentAmount = 0.0,
  });

  double get remaining => (budgetAmount - spentAmount).clamp(0, double.infinity);
  double get percentageUsed => budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => spentAmount > budgetAmount;

  Map<String, dynamic> toMap() => {
    'category': category,
    'budgetAmount': budgetAmount,
    'spentAmount': spentAmount,
  };

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
    category: map['category']?.toString() ?? 'General',
    budgetAmount: (map['budgetAmount'] as num?)?.toDouble() ?? 0.0,
    spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
  );
}

class FinanceAuditFlag {
  final String category;
  final String reason;
  final double currentPeriodAmount;
  final double previousPeriodAmount;
  final double percentageChange;
  final double potentialMonthlySaving;
  final String severity; // 'info', 'warning', 'action'

  FinanceAuditFlag({
    required this.category,
    required this.reason,
    required this.currentPeriodAmount,
    required this.previousPeriodAmount,
    required this.percentageChange,
    required this.potentialMonthlySaving,
    this.severity = 'warning',
  });
}
