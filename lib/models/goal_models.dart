import 'dart:convert';

class GoalItem {
  final String id;
  String title;
  int targetDays;
  int currentStreak;
  DateTime? lastCompletedDate;
  bool isStrict;
  String category;
  DateTime createdDate;
  List<String> auditHistory;
  bool notifyUser;

  GoalItem({
    String? id,
    required this.title,
    required this.targetDays,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.isStrict = true,
    this.category = 'General',
    DateTime? createdDate,
    List<String>? auditHistory,
    this.notifyUser = true,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdDate = createdDate ?? DateTime.now(),
        auditHistory = auditHistory ?? [];

  bool get isCompletedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  // Check if streak was broken (missed yesterday)
  bool get isStreakBroken {
    if (lastCompletedDate == null || currentStreak == 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastCompletedDate!.year, lastCompletedDate!.month, lastCompletedDate!.day);
    final diffDays = today.difference(last).inDays;
    return diffDays > 1;
  }

  double get progressPercentage {
    if (targetDays <= 0) return 0.0;
    return (currentStreak / targetDays).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetDays': targetDays,
      'currentStreak': currentStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'notifyUser': notifyUser ? 1 : 0,
      'isStrict': isStrict ? 1 : 0,
      'category': category,
      'createdDate': createdDate.toIso8601String(),
      'auditHistory': json.encode(auditHistory),
    };
  }

  factory GoalItem.fromMap(Map<String, dynamic> map) {
    List<String> audit = [];
    if (map['auditHistory'] != null) {
      try {
        final decoded = json.decode(map['auditHistory']);
        if (decoded is List) {
          audit = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return GoalItem(
      id: map['id']?.toString(),
      title: map['title'] ?? 'Goal',
      targetDays: (map['targetDays'] as num?)?.toInt() ?? 21,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null ? DateTime.tryParse(map['lastCompletedDate']) : null,
      isStrict: map['isStrict'] == 1 || map['isStrict'] == true || map['isStrict'] == null,
      category: map['category'] ?? 'General',
      createdDate: map['createdDate'] != null ? (DateTime.tryParse(map['createdDate']) ?? DateTime.now()) : DateTime.now(),
      auditHistory: audit,
      notifyUser: map['notifyUser'] == 1 || map['notifyUser'] == true,
    );
  }
}

class DeletedGoalRecord {
  final int? id;
  final String title;
  final int streakAchieved;
  final int targetDays;
  final String apologyLetter;
  final String reason;
  final DateTime deletedAt;

  DeletedGoalRecord({
    this.id,
    required this.title,
    required this.streakAchieved,
    required this.targetDays,
    required this.apologyLetter,
    this.reason = 'Lack of Discipline',
    DateTime? deletedAt,
  }) : deletedAt = deletedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'streakAchieved': streakAchieved,
      'targetDays': targetDays,
      'apologyLetter': apologyLetter,
      'reason': reason,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory DeletedGoalRecord.fromMap(Map<String, dynamic> map) {
    String apology = map['apologyLetter'] ?? '';
    String parsedReason = map['reason'] ?? 'Lack of Discipline';

    if (apology.startsWith('[Reason: ') && apology.contains(']\n')) {
      final endIdx = apology.indexOf(']\n');
      parsedReason = apology.substring(9, endIdx);
      apology = apology.substring(endIdx + 2);
    }

    return DeletedGoalRecord(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] ?? 'Goal',
      streakAchieved: (map['streakAchieved'] as num?)?.toInt() ?? 0,
      targetDays: (map['targetDays'] as num?)?.toInt() ?? 21,
      apologyLetter: apology,
      reason: parsedReason,
      deletedAt: map['deletedAt'] != null ? (DateTime.tryParse(map['deletedAt']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}
