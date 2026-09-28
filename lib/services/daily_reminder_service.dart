import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_helper.dart';
import '../models/workout_models.dart';
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
  final bool workoutCompleted;
  final String workoutName;
  final double caloriesConsumed;
  final double calorieTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final bool bodyPhotoCompleted;
  final bool weeklyWeightCompleted;
  final bool studyCompleted;
  final bool englishCompleted;
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
    required this.workoutCompleted,
    required this.workoutName,
    required this.caloriesConsumed,
    required this.calorieTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.bodyPhotoCompleted,
    required this.weeklyWeightCompleted,
    required this.studyCompleted,
    required this.englishCompleted,
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
      'workoutCompleted': workoutCompleted,
      'workoutName': workoutName,
      'caloriesConsumed': caloriesConsumed,
      'calorieTarget': calorieTarget,
      'proteinConsumed': proteinConsumed,
      'proteinTarget': proteinTarget,
      'bodyPhotoCompleted': bodyPhotoCompleted,
      'weeklyWeightCompleted': weeklyWeightCompleted,
      'studyCompleted': studyCompleted,
      'englishCompleted': englishCompleted,
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
}

class DailyReminderService {
  static final DailyReminderService instance = DailyReminderService._internal();
  DailyReminderService._internal();

  bool dailyReminderEnabled = true;
  bool browserNotificationEnabled = true;
  bool emailReminderEnabled = true;
  bool messageReminderEnabled = false;
  String reminderTime = '21:00'; // 9:00 PM
  String timezone = 'Asia/Kolkata';

  List<Map<String, dynamic>> notificationLogs = [];
  DailyGoalSummary? lastEvaluatedSummary;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
      browserNotificationEnabled = prefs.getBool('browser_notification_enabled') ?? true;
      emailReminderEnabled = prefs.getBool('email_reminder_enabled') ?? true;
      messageReminderEnabled = prefs.getBool('message_reminder_enabled') ?? false;
      reminderTime = prefs.getString('reminder_time') ?? '21:00';
      timezone = prefs.getString('reminder_timezone') ?? 'Asia/Kolkata';

      final logsJson = prefs.getString('notification_logs');
      if (logsJson != null) {
        final List list = jsonDecode(logsJson);
        notificationLogs = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> saveSettings({
    bool? dailyEnabled,
    bool? browserEnabled,
    bool? emailEnabled,
    bool? messageEnabled,
    String? time,
    String? tz,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dailyEnabled != null) {
        dailyReminderEnabled = dailyEnabled;
        await prefs.setBool('daily_reminder_enabled', dailyEnabled);
      }
      if (browserEnabled != null) {
        browserNotificationEnabled = browserEnabled;
        await prefs.setBool('browser_notification_enabled', browserEnabled);
      }
      if (emailEnabled != null) {
        emailReminderEnabled = emailEnabled;
        await prefs.setBool('email_reminder_enabled', emailEnabled);
      }
      if (messageEnabled != null) {
        messageReminderEnabled = messageEnabled;
        await prefs.setBool('message_reminder_enabled', messageEnabled);
      }
      if (time != null) {
        reminderTime = time;
        await prefs.setString('reminder_time', time);
      }
      if (tz != null) {
        timezone = tz;
        await prefs.setString('reminder_timezone', tz);
      }
    } catch (_) {}
  }

  Future<DailyGoalSummary> evaluateDailyGoals() async {
    final now = DateTime.now();
    final todayWeekdayName = _getWeekdayName(now.weekday);
    final profile = ProfileService.instance;

    // 1. Calories & Protein
    double totalCalories = 0;
    double totalProtein = 0;
    try {
      final meals = await DBHelper.instance.getMeals();
      for (var m in meals) {
        if (_isSameDay(m.loggedAt, now)) {
          totalCalories += m.totalCalories;
          totalProtein += m.totalProtein;
        }
      }
    } catch (_) {}

    final calTarget = profile.nutritionTarget.calorieTarget;
    final protTarget = profile.nutritionTarget.proteinTargetGrams;
    final bool calGoalAchieved = calTarget > 0 && totalCalories >= (calTarget * 0.85);
    final bool protGoalAchieved = protTarget > 0 && totalProtein >= (protTarget * 0.85);

    // 2. Workout
    bool workoutCompleted = false;
    String workoutName = 'Workout Session';
    try {
      final plans = await DBHelper.instance.getWorkoutPlans();
      final todayPlan = plans.firstWhere(
        (p) => p.dayName.toLowerCase() == todayWeekdayName.toLowerCase(),
        orElse: () => WorkoutDayPlan(
          id: 'temp',
          dayName: todayWeekdayName,
          workoutName: '$todayWeekdayName Workout',
          muscleGroup: 'Full Body',
          exercises: [],
        ),
      );
      workoutName = todayPlan.workoutName;
      workoutCompleted = todayPlan.status == WorkoutStatus.completed ||
          todayPlan.status == WorkoutStatus.restDay ||
          todayPlan.isFullyCompleted;
    } catch (_) {}

    // 3. Body Photo
    bool bodyPhotoCompleted = false;
    try {
      final photos = await DBHelper.instance.fetchBodyPhotos();
      final todayDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      bodyPhotoCompleted = photos.any((p) => p.date == todayDateStr);
    } catch (_) {}

    // 4. Weekly Weight Check-in
    bool weeklyWeightCompleted = false;
    try {
      final weights = await DBHelper.instance.fetchWeeklyWeights();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      weeklyWeightCompleted = weights.any((w) {
        final parsed = DateTime.tryParse(w.date);
        return parsed != null && parsed.isAfter(sevenDaysAgo);
      });
    } catch (_) {}

    // 5. Study & English Goals
    bool studyCompleted = false;
    bool englishCompleted = false;
    try {
      final studyLogs = await DBHelper.instance.getStudyLogs();
      int todayStudyMins = 0;
      for (var log in studyLogs) {
        final dt = DateTime.tryParse(log['timestamp']?.toString() ?? '');
        if (dt != null && _isSameDay(dt, now)) {
          todayStudyMins += (log['durationMinutes'] as num?)?.toInt() ?? 0;
        }
      }
      final studyService = StudyEnglishService.instance;
      studyCompleted = todayStudyMins >= studyService.dailyStudyTargetMinutes || todayStudyMins >= 60;
      final int todaySpeakingMins = studyService.todaySpeakingMinutes;
      final int targetSpeakingMins = studyService.dailySpeakingGoalMinutes;
      englishCompleted = todaySpeakingMins >= targetSpeakingMins || (todaySpeakingMins > 0 && todaySpeakingMins >= (targetSpeakingMins * 0.7)) || studyService.grammarQuizzesTaken > 0 || studyService.totalCompletedTopics > 0;
    } catch (_) {}

    // Compile Active Goal Checklists
    final List<String> completedTitles = [];
    final List<String> remainingTitles = [];

    // Calorie Target
    if (calTarget > 0) {
      if (calGoalAchieved) {
        completedTitles.add('Calories (${totalCalories.toStringAsFixed(0)} / ${calTarget.toStringAsFixed(0)} kcal)');
      } else {
        remainingTitles.add('Calories (${totalCalories.toStringAsFixed(0)} / ${calTarget.toStringAsFixed(0)} kcal)');
      }
    }

    // Protein Target
    if (protTarget > 0) {
      if (protGoalAchieved) {
        completedTitles.add('Protein (${totalProtein.toStringAsFixed(0)} / ${protTarget.toStringAsFixed(0)} g)');
      } else {
        remainingTitles.add('Protein (${totalProtein.toStringAsFixed(0)} / ${protTarget.toStringAsFixed(0)} g)');
      }
    }

    // Workout
    if (workoutCompleted) {
      completedTitles.add('Workout ($workoutName)');
    } else {
      remainingTitles.add('Workout ($workoutName)');
    }

    // Body Photo
    if (bodyPhotoCompleted) {
      completedTitles.add('Body Photo Progress');
    } else {
      remainingTitles.add('Body Photo Progress');
    }

    // Weekly Weight
    if (weeklyWeightCompleted) {
      completedTitles.add('Weight Tracking');
    } else {
      remainingTitles.add('Weight Tracking');
    }

    // Study
    if (studyCompleted) {
      completedTitles.add('Study Goal');
    } else {
      remainingTitles.add('Study Goal');
    }

    // English
    final int todaySpeakingMins = StudyEnglishService.instance.todaySpeakingMinutes;
    final int targetSpeakingMins = StudyEnglishService.instance.dailySpeakingGoalMinutes;
    final String englishStatus = StudyEnglishService.instance.todayGoalStatus;
    final String englishEntryTitle = 'English ($todaySpeakingMins / $targetSpeakingMins min - $englishStatus)';

    if (englishCompleted) {
      completedTitles.add(englishEntryTitle);
    } else {
      remainingTitles.add(englishEntryTitle);
    }

    final totalGoals = completedTitles.length + remainingTitles.length;
    final completedCount = completedTitles.length;

    ReminderStatusCategory category;
    String summaryText;
    String shortTitle;
    String shortBody;

    final dateHeader = _formatDateHeader(now);

    if (completedCount == totalGoals && totalGoals > 0) {
      category = ReminderStatusCategory.allCompleted;
      shortTitle = '🎉 GET SET GO — All Goals Complete!';
      shortBody = 'Excellent! You completed all $completedCount/$totalGoals goals for today. Keep the streak going!';
      summaryText = '''🎉 GET SET GO

Excellent!

You completed all of today's goals.

🔥 Calories: ${totalCalories.toStringAsFixed(0)} / ${calTarget.toStringAsFixed(0)} kcal
💪 Protein: ${totalProtein.toStringAsFixed(0)} / ${protTarget.toStringAsFixed(0)} g
🏋️ Workout: Completed ($workoutName)
📸 Body tracking: ${bodyPhotoCompleted ? 'Completed' : 'Logged'}
📚 Study: Completed
🇬🇧 English:
Speaking: $todaySpeakingMins / $targetSpeakingMins minutes
Status: $englishStatus

All goals completed for today.
Keep the streak going tomorrow!''';

    } else if (completedCount > 0) {
      category = ReminderStatusCategory.partialCompleted;
      shortTitle = '⏰ GET SET GO — 9 PM Daily Check';
      shortBody = '$completedCount/$totalGoals goals completed. ${remainingTitles.length} goals remaining today.';
      
      final remainingList = remainingTitles.map((t) => '• $t').join('\n');
      final completedList = completedTitles.map((t) => '• $t').join('\n');

      summaryText = '''⏰ GET SET GO — 9 PM CHECK
$dateHeader

You still have some goals remaining today.

✅ Completed: $completedCount
$completedList

❌ Remaining: ${remainingTitles.length}
$remainingList

Complete them before the day ends!''';
    } else {
      category = ReminderStatusCategory.nothingCompleted;
      shortTitle = '⏰ GET SET GO — Daily Goals Reminder';
      shortBody = "Today's goals are still open. Take a few minutes to check your dashboard and finish strong!";
      summaryText = '''⏰ GET SET GO
$dateHeader

Today's goals are still incomplete.

You have time to finish them.

Check your dashboard and complete today's goals.''';
    }

    final summary = DailyGoalSummary(
      date: now,
      workoutCompleted: workoutCompleted,
      workoutName: workoutName,
      caloriesConsumed: totalCalories,
      calorieTarget: calTarget,
      proteinConsumed: totalProtein,
      proteinTarget: protTarget,
      bodyPhotoCompleted: bodyPhotoCompleted,
      weeklyWeightCompleted: weeklyWeightCompleted,
      studyCompleted: studyCompleted,
      englishCompleted: englishCompleted,
      totalGoalsCount: totalGoals,
      completedGoalsCount: completedCount,
      remainingGoalTitles: remainingTitles,
      completedGoalTitles: completedTitles,
      category: category,
      summaryText: summaryText,
      shortNotificationTitle: shortTitle,
      shortNotificationBody: shortBody,
    );

    lastEvaluatedSummary = summary;
    return summary;
  }

  Future<void> triggerDailyCheck({bool isManualTest = false}) async {
    final summary = await evaluateDailyGoals();
    
    // Log to notification history
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'title': summary.shortNotificationTitle,
      'body': summary.shortNotificationBody,
      'completed': summary.completedGoalsCount,
      'total': summary.totalGoalsCount,
      'category': summary.category.name,
      'isManualTest': isManualTest,
    };

    notificationLogs.insert(0, logEntry);
    if (notificationLogs.length > 30) {
      notificationLogs = notificationLogs.sublist(0, 30);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_logs', jsonEncode(notificationLogs));
    } catch (_) {}

    // Dispatch notification if enabled
    if (browserNotificationEnabled && !kIsWeb) {
      try {
        await NotificationService.instance.scheduleDailyAlarms();
      } catch (_) {}
    }
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _formatDateHeader(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[(d.weekday - 1).clamp(0, 6)];
    final monthName = months[(d.month - 1).clamp(0, 11)];
    return '$dayName, ${d.day} $monthName ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
