import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_helper.dart';
import '../notification_service.dart';
import 'profile_service.dart';
import 'study_english_service.dart';

enum ReminderStatusCategory {
  allCompleted,
  partialCompleted,
  nothingCompleted,
}

class DailyGoalSummary {
  final DateTime date;
  final bool strictGoalsCompleted;
  final bool studyCompleted;
  final bool englishCompleted;
  final bool budgetUnderControl;
  final int totalGoalsCount;
  final int completedGoalsCount;
  final List<String> remainingGoalTitles;
  final List<String> completedGoalTitles;
  final ReminderStatusCategory category;
  final String summaryText;
  final String shortNotificationTitle;
  final String shortNotificationBody;

  DailyGoalSummary({
    required this.date,
    required this.strictGoalsCompleted,
    required this.studyCompleted,
    required this.englishCompleted,
    required this.budgetUnderControl,
    required this.totalGoalsCount,
    required this.completedGoalsCount,
    required this.remainingGoalTitles,
    required this.completedGoalTitles,
    required this.category,
    required this.summaryText,
    required this.shortNotificationTitle,
    required this.shortNotificationBody,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'strictGoalsCompleted': strictGoalsCompleted,
      'studyCompleted': studyCompleted,
      'englishCompleted': englishCompleted,
      'budgetUnderControl': budgetUnderControl,
      'totalGoalsCount': totalGoalsCount,
      'completedGoalsCount': completedGoalsCount,
      'remainingGoalTitles': remainingGoalTitles,
      'completedGoalTitles': completedGoalTitles,
      'category': category.name,
      'summaryText': summaryText,
      'shortNotificationTitle': shortNotificationTitle,
      'shortNotificationBody': shortNotificationBody,
    };
  }

  factory DailyGoalSummary.fromMap(Map<String, dynamic> map) {
    return DailyGoalSummary(
      date: DateTime.parse(map['date']),
      strictGoalsCompleted: map['strictGoalsCompleted'] ?? false,
      studyCompleted: map['studyCompleted'] ?? false,
      englishCompleted: map['englishCompleted'] ?? false,
      budgetUnderControl: map['budgetUnderControl'] ?? true,
      totalGoalsCount: map['totalGoalsCount'] ?? 0,
      completedGoalsCount: map['completedGoalsCount'] ?? 0,
      remainingGoalTitles: List<String>.from(map['remainingGoalTitles'] ?? []),
      completedGoalTitles: List<String>.from(map['completedGoalTitles'] ?? []),
      category: ReminderStatusCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ReminderStatusCategory.nothingCompleted,
      ),
      summaryText: map['summaryText'] ?? '',
      shortNotificationTitle: map['shortNotificationTitle'] ?? '',
      shortNotificationBody: map['shortNotificationBody'] ?? '',
    );
  }
}

class DailyReminderService {
  static final DailyReminderService instance = DailyReminderService._internal();
  DailyReminderService._internal();

  static const String _dismissedRemindersKey = 'gsg_dismissed_reminders_';

  Future<DailyGoalSummary> evaluateTodayStatus({DateTime? targetDate}) async {
    final now = targetDate ?? DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final completedGoals = <String>[];
    final remainingGoals = <String>[];

    // 1. Strict Goals & Telemetry
    final profile = ProfileService.instance;
    final goals = await DBHelper.instance.getGoals();
    int goalsDoneToday = 0;
    for (var g in goals) {
      if (g['lastCompletedDate'] == todayStr) {
        goalsDoneToday++;
        completedGoals.add(g['title'] ?? 'Goal');
      } else {
        remainingGoals.add(g['title'] ?? 'Goal');
      }
    }
    final bool strictGoalsCompleted = goals.isNotEmpty ? (goalsDoneToday == goals.length) : (profile.todaySteps >= profile.dailyStepTarget);

    // 2. Study & Academics
    final studyLogs = await DBHelper.instance.getStudyLogs();
    final todayStudy = studyLogs.where((l) {
      final d = l['date'] ?? '';
      return d.startsWith(todayStr);
    }).toList();
    final bool studyCompleted = todayStudy.isNotEmpty || StudyEnglishService.instance.studyStreakDays > 0;
    if (studyCompleted) {
      completedGoals.add('Study Focus Session');
    } else {
      remainingGoals.add('Study Focus Session');
    }

    // 3. English Mastery
    final speakingRecords = await DBHelper.instance.fetchSpeakingRecords();
    final todaySpeaking = speakingRecords.where((s) => s.date == todayStr).toList();
    final bool englishCompleted = todaySpeaking.isNotEmpty || StudyEnglishService.instance.vocabularyList.any((v) => v.dateAdded.toIso8601String().startsWith(todayStr));
    if (englishCompleted) {
      completedGoals.add('English Speaking / Vocab');
    } else {
      remainingGoals.add('English Speaking / Vocab');
    }

    // 4. Budget Adherence
    final expenses = await DBHelper.instance.getExpenses();
    double totalSpent = 0;
    for (var e in expenses) {
      if (e['is_income'] != 1 && e['is_income'] != true && e['isCredit'] != 1) {
        totalSpent += ((e['amount'] as num?) ?? 0).toDouble();
      }
    }
    final bool budgetUnderControl = totalSpent <= profile.monthlyBudgetCap;

    final totalCount = completedGoals.length + remainingGoals.length;
    final completedCount = completedGoals.length;

    ReminderStatusCategory category;
    if (completedCount == 0) {
      category = ReminderStatusCategory.nothingCompleted;
    } else if (remainingGoals.isEmpty) {
      category = ReminderStatusCategory.allCompleted;
    } else {
      category = ReminderStatusCategory.partialCompleted;
    }

    String summaryText;
    String shortNotificationTitle;
    String shortNotificationBody;

    switch (category) {
      case ReminderStatusCategory.allCompleted:
        summaryText = 'Outstanding discipline! All strict goals, study sessions, and English modules for today are complete.';
        shortNotificationTitle = '🎉 Unstoppable Consistency!';
        shortNotificationBody = 'You crushed 100% of your goals today. Incredible work!';
        break;
      case ReminderStatusCategory.partialCompleted:
        summaryText = 'Great momentum! You completed ${completedGoals.join(", ")}. Remaining: ${remainingGoals.join(", ")}.';
        shortNotificationTitle = '⚡ Keep the Streak Alive!';
        shortNotificationBody = 'You have ${remainingGoals.length} milestone(s) remaining today: ${remainingGoals.join(", ")}.';
        break;
      case ReminderStatusCategory.nothingCompleted:
        summaryText = 'Your daily protocol is waiting. Commit to your strict goals, study blocks, and English practice now!';
        shortNotificationTitle = '🎯 Daily Protocol Check-In';
        shortNotificationBody = 'Maintain your momentum. Dedicate 20 minutes to your goals today!';
        break;
    }

    return DailyGoalSummary(
      date: now,
      strictGoalsCompleted: strictGoalsCompleted,
      studyCompleted: studyCompleted,
      englishCompleted: englishCompleted,
      budgetUnderControl: budgetUnderControl,
      totalGoalsCount: totalCount,
      completedGoalsCount: completedCount,
      remainingGoalTitles: remainingGoals,
      completedGoalTitles: completedGoals,
      category: category,
      summaryText: summaryText,
      shortNotificationTitle: shortNotificationTitle,
      shortNotificationBody: shortNotificationBody,
    );
  }

  Future<void> triggerDailyCheckNotification() async {
    final summary = await evaluateTodayStatus();
    try {
      await NotificationService.instance.showInstantNotification(
        title: summary.shortNotificationTitle,
        body: summary.shortNotificationBody,
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> dismissReminderForSlot(int slotHour) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setBool('$_dismissedRemindersKey${today}_$slotHour', true);
  }

  Future<bool> isReminderDismissed(int slotHour) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getBool('$_dismissedRemindersKey${today}_$slotHour') ?? false;
  }
}
