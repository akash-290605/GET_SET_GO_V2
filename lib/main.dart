import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart';
import 'notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'services/cloud_sync_service.dart';
import 'screens/auth_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/workout_screen.dart';
import 'widgets/account_cloud_modal.dart';
import 'widgets/titan_ai_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    tz.initializeTimeZones();
  } catch (_) {}
  try {
    await AuthService.instance.init();
  } catch (_) {}
  try {
    await GeminiService.instance.init();
  } catch (_) {}
  try {
    await CloudSyncService.instance.init();
  } catch (_) {}
  if (!kIsWeb) {
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDailyAlarms();
    } catch (_) {}
  }
  runApp(const GetSetGoApp());
}


// ---------------- DESIGN SYSTEM & COLOR PALETTE ----------------
class AppColors {
  static const Color background = Color(0xFF090D18);
  static const Color surface = Color(0xFF11182B);
  static const Color surfaceElevated = Color(0xFF18223C);
  static const Color surfaceHighlight = Color(0xFF1E2C4D);

  static const Color primary = Color(0xFF8B5CF6); // Electric Violet
  static const Color primaryGlow = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4); // Cyber Cyan
  static const Color secondaryGlow = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF10B981); // Emerald
  static const Color accentAmber = Color(0xFFF59E0B); // Sunset Amber
  static const Color accentRose = Color(0xFFF43F5E); // Radiant Rose
  static const Color accentBlue = Color(0xFF3B82F6); // Cosmic Blue
  static const Color accentPurple = Color(0xFFC084FC); // Soft Lilac

  static const Color borderLight = Color(0x1FFFFFFF);
  static const Color borderGlow = Color(0x408B5CF6);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ---------------- DISCIPLINE FEEDBACK & GREETING MODALS ----------------
class DisciplineFeedback {
  static void showCelebration({
    required BuildContext context,
    required String title,
    required String message,
    String? disciplineQuote,
    IconData icon = Icons.emoji_events_rounded,
    Color color = AppColors.accentGreen,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.4)),
            if (disciplineQuote != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('“', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white38)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        disciplineQuote,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Claim Victory ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showEncouragement({
    required BuildContext context,
    required String title,
    required String message,
    String? confidenceQuote,
    Color color = AppColors.accentAmber,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shield_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.4)),
            if (confidenceQuote != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('“', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white38)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        confidenceQuote,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: Color(0xFFFED7AA)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Will Rise & Execute 💪', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ---------------- HIERARCHICAL STORAGE MANAGER (MONTH > WEEK > DAY) ----------------
class HierarchicalStorageManager {
  static Future<String> getBaseDirectoryPath() async {
    try {
      if (kIsWeb) return 'GetSetGo_Storage';
      final dbPath = await getDatabasesPath();
      final parentDir = Directory(dbPath).parent.path;
      final targetDir = Directory(p.join(parentDir, 'GetSetGo_Storage'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir.path;
    } catch (_) {
      return 'GetSetGo_Storage';
    }
  }

  static int getWeekOfMonth(DateTime date) {
    int day = date.day;
    return ((day - 1) ~/ 7) + 1; // Week 1 (1-7), Week 2 (8-14), Week 3 (15-21), Week 4 (22-28), Week 5 (29-31)
  }

  static Future<File?> saveDailyRecord({
    required DateTime date,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return null;
    try {
      final basePath = await getBaseDirectoryPath();
      const monthNames = [
        '01_January', '02_February', '03_March', '04_April', '05_May', '06_June',
        '07_July', '08_August', '09_September', '10_October', '11_November', '12_December'
      ];
      final monthFolder = '${date.year}_${monthNames[date.month - 1]}';
      final weekFolder = 'Week_${getWeekOfMonth(date)}';

      final targetFolder = Directory(p.join(basePath, monthFolder, weekFolder));
      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      final fileName = '${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}_DailyData.json';
      final file = File(p.join(targetFolder.path, fileName));
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      return file;
    } catch (e) {
      debugPrint('Hierarchical storage error: $e');
      return null;
    }
  }

  static Future<String> exportFullTreeBackup() async {
    try {
      final goals = await DBHelper.instance.fetchGoals();
      final deleted = await DBHelper.instance.fetchDeletedGoals();
      final expenses = await DBHelper.instance.fetchExpenses();
      final study = await DBHelper.instance.fetchStudyLogs();

      final now = DateTime.now();
      final payload = {
        'timestamp': now.toIso8601String(),
        'year': now.year,
        'month': now.month,
        'weekOfMonth': getWeekOfMonth(now),
        'day': now.day,
        'activeGoals': goals,
        'deletedGoalsArchive': deleted,
        'expenses': expenses,
        'studySessions': study,
        'workout': {
          'completedExercises': WorkoutState.completedExercisesCount,
          'totalExercises': WorkoutState.totalExercisesCount,
          'completedSets': WorkoutState.completedSetsCount,
          'totalSets': WorkoutState.totalSetsCount,
          'totalReps': WorkoutState.totalRepsCount,
          'workoutMinutes': WorkoutState.totalWorkoutMinutes,
          'exercises': WorkoutState.exercises.map((e) => e.toMap()).toList(),
        },
        'bodyMetrics': {
          'weightKg': HealthState.weightKg,
          'targetWeightKg': HealthState.targetWeightKg,
          'heightCm': HealthState.heightCm,
          'bmi': HealthState.bmi,
          'bmiCategory': HealthState.bmiCategory,
        }
      };

      final file = await saveDailyRecord(date: now, data: payload);
      return file?.path ?? 'Saved to local hierarchical storage.';
    } catch (e) {
      return 'Backup error: $e';
    }
  }
}

// ---------------- MOTIVATION & GREETING ENGINE ----------------
class MotivationEngine {
  static final List<String> winningQuotes = [
    '🔥 Beast Mode Active! You conquered your commitments today! Greatness is built one rep at a time.',
    '⚡ Elite Discipline in Motion! You chose progress over comfort. Keep dominating!',
    '🏆 Victory belongs to those who show up every single day without excuses!',
    '⚔️ Unstoppable momentum unlocked! The standard has been set. Defend it!',
    '🦁 You are forging unbreakable mental steel today. Proud of your execution!',
    '🌟 High performance isn\'t an accident—it is your daily identity. Stay relentless!',
  ];

  static final List<String> encouragementQuotes = [
    '🛡️ A true champion never negotiates with weakness. Complete your targets before midnight!',
    '⚡ Every minute you delay is a minute stolen from your future self. Rise and execute!',
    '🔥 The pain of discipline is temporary, but the pain of regret lasts forever. Take action now!',
    '💪 Stumble or not, you have the power to make today a total victory. Get after it!',
    '🚀 Champions are made in the moments they don\'t feel like doing the work. Push through!',
    '🌱 Small steps taken under resistance create massive transformations. Start right now!',
  ];

  static String getDailyQuote(bool hasAchievedToday) {
    final list = hasAchievedToday ? winningQuotes : encouragementQuotes;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }
}

class GetSetGoApp extends StatefulWidget {
  const GetSetGoApp({super.key});

  @override
  State<GetSetGoApp> createState() => _GetSetGoAppState();
}

class _GetSetGoAppState extends State<GetSetGoApp> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthService.instance.isLoggedIn;

    return MaterialApp(
      title: 'GET SET GO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          tertiary: AppColors.accentGreen,
          error: AppColors.accentRose,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.borderLight, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
      home: isLoggedIn
          ? const MainNavigationShell()
          : AuthScreen(
              onAuthenticated: () {
                if (mounted) setState(() {});
              },
            ),
    );
  }
}

// ---------------- GLOBAL HEALTH & BMI STATE ----------------
class HealthState {
  static double weightKg = 0.0;
  static double targetWeightKg = 0.0;
  static double heightCm = 0.0;
  static DateTime? lastWeightLogDate;
  static List<double> monthlyWeightHistory = [];

  static bool get canLogWeeklyWeight {
    if (lastWeightLogDate == null) return true;
    final diff = DateTime.now().difference(lastWeightLogDate!).inDays;
    return diff >= 7;
  }

  static int get daysUntilNextWeighIn {
    if (lastWeightLogDate == null) return 0;
    final diff = DateTime.now().difference(lastWeightLogDate!).inDays;
    return (7 - diff).clamp(0, 7);
  }

  static double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  static String get bmiCategory {
    double val = bmi;
    if (val <= 0) return 'Not Set';
    if (val < 18.5) return 'Underweight';
    if (val < 24.9) return 'Healthy / Optimal';
    if (val < 29.9) return 'Overweight';
    return 'Obese';
  }

  static Color get bmiColor {
    double val = bmi;
    if (val <= 0) return AppColors.textMuted;
    if (val < 18.5) return AppColors.accentAmber;
    if (val < 24.9) return AppColors.accentGreen;
    if (val < 29.9) return AppColors.accentAmber;
    return AppColors.accentRose;
  }

  static double customDailyCalorieBudget = 0.0;

  static double get dynamicDailyCalorieTarget {
    if (customDailyCalorieBudget > 0) return customDailyCalorieBudget;
    if (weightKg > 0 && heightCm > 0) {
      // Mifflin-St Jeor Formula for BMR + moderate active multiplier (~1.35x)
      final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * 25) + 5;
      final tdee = bmr * 1.35;
      return double.parse(tdee.clamp(1400.0, 3800.0).toStringAsFixed(0));
    } else if (weightKg > 0) {
      // Rule of thumb: ~30 kcal per kg bodyweight
      return double.parse((weightKg * 30.0).clamp(1500.0, 3500.0).toStringAsFixed(0));
    }
    return 2200.0;
  }
}

// ---------------- DATA MODELS ----------------
class GoalItem {
  String id;
  String title;
  int targetDays;
  int currentStreak;
  DateTime? lastCompletedDate;
  bool notifyUser;

  GoalItem({
    required this.id,
    required this.title,
    required this.targetDays,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.notifyUser = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetDays': targetDays,
      'currentStreak': currentStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'notifyUser': notifyUser ? 1 : 0,
    };
  }

  factory GoalItem.fromMap(Map<String, dynamic> map) {
    return GoalItem(
      id: map['id'],
      title: map['title'],
      targetDays: map['targetDays'],
      currentStreak: map['currentStreak'],
      lastCompletedDate: map['lastCompletedDate'] != null ? DateTime.tryParse(map['lastCompletedDate']) : null,
      notifyUser: (map['notifyUser'] == null || map['notifyUser'] == 1 || map['notifyUser'] == true),
    );
  }

  bool get isCompletedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(lastCompletedDate!.year, lastCompletedDate!.month, lastCompletedDate!.day);
    return today.isAtSameMomentAs(lastDate);
  }

  bool completeToday() {
    if (isCompletedToday) return false;
    currentStreak++;
    lastCompletedDate = DateTime.now();
    return true;
  }
}

enum ExerciseTrackingType { reps, time }

class ExerciseItem {
  String name;
  String category;
  ExerciseTrackingType trackingType;
  int sets;
  int reps;
  int durationSeconds;
  double weightKg;
  int completedSets;
  bool isDone;

  ExerciseItem({
    required this.name,
    required this.category,
    this.trackingType = ExerciseTrackingType.reps,
    this.sets = 4,
    this.reps = 12,
    this.durationSeconds = 60,
    this.weightKg = 0.0,
    this.completedSets = 0,
    this.isDone = false,
  });

  bool get isRepsBased => trackingType == ExerciseTrackingType.reps;
  bool get isTimeBased => trackingType == ExerciseTrackingType.time;

  int get totalReps => isRepsBased ? (sets * reps) : 0;
  int get completedReps => isRepsBased ? (isDone ? totalReps : (completedSets * reps)) : 0;

  int get totalDurationSeconds => isTimeBased ? (sets * durationSeconds) : 0;
  int get completedDurationSeconds => isTimeBased ? (isDone ? totalDurationSeconds : (completedSets * durationSeconds)) : 0;

  String get formattedTarget {
    if (isRepsBased) {
      return '$sets Sets × $reps Reps${weightKg > 0 ? " • ${weightKg}kg" : ""}';
    } else {
      final timeStr = durationSeconds >= 60 ? '${(durationSeconds / 60).toStringAsFixed(durationSeconds % 60 == 0 ? 0 : 1)}m' : '${durationSeconds}s';
      return '$sets Rounds × $timeStr${weightKg > 0 ? " • ${weightKg}kg" : ""}';
    }
  }

  String get formattedProgress {
    final doneSets = isDone ? sets : completedSets;
    if (isRepsBased) {
      return '$doneSets/$sets Sets ($completedReps/$totalReps Reps)';
    } else {
      final doneSec = isDone ? totalDurationSeconds : completedDurationSeconds;
      final doneTimeStr = doneSec >= 60 ? '${(doneSec / 60).toStringAsFixed(doneSec % 60 == 0 ? 0 : 1)}m' : '${doneSec}s';
      final totalTimeStr = totalDurationSeconds >= 60 ? '${(totalDurationSeconds / 60).toStringAsFixed(totalDurationSeconds % 60 == 0 ? 0 : 1)}m' : '${totalDurationSeconds}s';
      return '$doneSets/$sets Rounds ($doneTimeStr/$totalTimeStr)';
    }
  }

  String setChipLabel(int setIndex) {
    if (isRepsBased) {
      return 'Set ${setIndex + 1} (${reps}r)';
    } else {
      final timeStr = durationSeconds >= 60 ? '${durationSeconds ~/ 60}m${durationSeconds % 60 > 0 ? " ${durationSeconds % 60}s" : ""}' : '${durationSeconds}s';
      return 'Round ${setIndex + 1} ($timeStr)';
    }
  }

  void toggleSet(int setIndex) {
    if (setIndex < completedSets) {
      completedSets = setIndex;
      isDone = false;
    } else {
      completedSets = setIndex + 1;
      if (completedSets >= sets) {
        completedSets = sets;
        isDone = true;
      }
    }
  }

  void toggleDone(bool done) {
    isDone = done;
    completedSets = done ? sets : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'trackingType': trackingType.name,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'weightKg': weightKg,
      'completedSets': completedSets,
      'isDone': isDone ? 1 : 0,
    };
  }

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    return ExerciseItem(
      name: map['name'] ?? '',
      category: map['category'] ?? 'Biceps',
      trackingType: map['trackingType'] == 'time' ? ExerciseTrackingType.time : ExerciseTrackingType.reps,
      sets: map['sets'] ?? 4,
      reps: map['reps'] ?? 12,
      durationSeconds: map['durationSeconds'] ?? 60,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      completedSets: map['completedSets'] ?? 0,
      isDone: (map['isDone'] == 1 || map['isDone'] == true),
    );
  }
}

class WorkoutState {
  static final List<ExerciseItem> exercises = [];

  static bool warmupCompleted = false;
  static int walkMins = 0;
  static int jogMins = 0;
  static int gymMins = 0;

  static double? explicitWalkKm;
  static double? explicitJogKm;

  static double get walkDistanceKm => explicitWalkKm ?? (walkMins * 0.08); // ~4.8 km/h brisk walk
  static double get jogDistanceKm => explicitJogKm ?? (jogMins * 0.15); // ~9.0 km/h jog
  static double get totalDistanceKm => walkDistanceKm + jogDistanceKm;

  static List<double> weeklyDistanceHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  static void updateDistance({double? walkKm, double? jogKm, int? walkMinutes, int? jogMinutes}) {
    if (walkKm != null) {
      explicitWalkKm = walkKm;
      walkMins = (walkKm / 0.08).round();
    } else if (walkMinutes != null) {
      walkMins = walkMinutes;
      explicitWalkKm = walkMinutes * 0.08;
    }

    if (jogKm != null) {
      explicitJogKm = jogKm;
      jogMins = (jogKm / 0.15).round();
    } else if (jogMinutes != null) {
      jogMins = jogMinutes;
      explicitJogKm = jogMinutes * 0.15;
    }

    final int todayIdx = (DateTime.now().weekday % 7);
    if (todayIdx < weeklyDistanceHistory.length) {
      weeklyDistanceHistory[todayIdx] = double.parse(totalDistanceKm.toStringAsFixed(1));
    }
  }

  static int get totalExercisesCount => exercises.length;
  static int get completedExercisesCount => exercises.where((e) => e.isDone).length;
  static int get totalSetsCount => exercises.fold(0, (sum, e) => sum + e.sets);
  static int get completedSetsCount => exercises.fold(0, (sum, e) => sum + (e.isDone ? e.sets : e.completedSets));
  static int get totalRepsCount => exercises.fold(0, (sum, e) => sum + e.completedReps);
  static int get totalTargetReps => exercises.fold(0, (sum, e) => sum + e.totalReps);
  static int get totalTimeTensionSeconds => exercises.fold(0, (sum, e) => sum + e.completedDurationSeconds);
  static int get totalWorkoutMinutes => walkMins + jogMins + gymMins;

  static List<String> get trainedCategories => exercises.map((e) => e.category).toSet().toList();
}

class FoodItem {
  int? id;
  String name;
  String mealSlot;
  String type;
  String category;
  double quantity;
  String unit;
  double calories;
  double protein;
  double carbs;
  double fat;
  TimeOfDay time;
  DateTime loggedAt;

  FoodItem({
    this.id,
    required this.name,
    required this.mealSlot,
    required this.type,
    required this.category,
    this.quantity = 1.0,
    this.unit = 'Pcs (Pieces)',
    this.calories = 100.0,
    this.protein = 4.0,
    this.carbs = 15.0,
    this.fat = 2.0,
    required this.time,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mealSlot': mealSlot,
      'type': type,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'date': loggedAt.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      mealSlot: map['mealSlot'] ?? 'Breakfast',
      type: map['type'] ?? 'Natural / Whole Food 🥬',
      category: map['category'] ?? 'Meal',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'Pcs (Pieces)',
      calories: (map['calories'] as num?)?.toDouble() ?? 100.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 4.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 15.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 2.0,
      time: TimeOfDay(
        hour: map['timeHour'] ?? 8,
        minute: map['timeMinute'] ?? 0,
      ),
      loggedAt: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class InbuiltFood {
  final String name;
  final String category; // 'Staples & Rice', 'Breads & Breakfast', 'Fruits', 'Curries & Proteins', 'Dairy & Drinks'
  final String defaultUnit;
  final double defaultQuantity;
  final String defaultMealSlot;
  final String type;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String emoji;

  const InbuiltFood({
    required this.name,
    required this.category,
    required this.defaultUnit,
    this.defaultQuantity = 1.0,
    required this.defaultMealSlot,
    this.type = 'Natural / Whole Food 🥬',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.emoji,
  });
}

class InbuiltFoodLibrary {
  static const List<InbuiltFood> popularPresets = [
    InbuiltFood(name: 'Steamed White Rice', category: 'Staples & Rice', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 205, protein: 4.2, carbs: 45, fat: 0.4, emoji: '🍚'),
    InbuiltFood(name: 'Curd Rice (Thair Sadam)', category: 'Staples & Rice', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 220, protein: 6.0, carbs: 32, fat: 7.0, emoji: '🍛'),
    InbuiltFood(name: 'Chapati / Roti / Phulka', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 2, defaultMealSlot: 'Dinner', type: 'Daily Meals 🍲', calories: 170, protein: 6.2, carbs: 36, fat: 1.0, emoji: '🫓'),
    InbuiltFood(name: 'Poori (Fried)', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 2, defaultMealSlot: 'Breakfast', type: 'Fried / Junk 🍟', calories: 250, protein: 4.4, carbs: 30, fat: 13.0, emoji: '🥟'),
    InbuiltFood(name: 'Plain Dosa', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 130, protein: 3.5, carbs: 22, fat: 4.0, emoji: '🥞'),
    InbuiltFood(name: 'Steamed Idli', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 2, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 110, protein: 4.0, carbs: 24, fat: 0.4, emoji: '⚪'),
    InbuiltFood(name: 'Dal Tadka / Fry', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 150, protein: 8.5, carbs: 22, fat: 3.5, emoji: '🍲'),
    InbuiltFood(name: 'Boiled Egg', category: 'Curries & Proteins', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 2, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 150, protein: 12.6, carbs: 1.0, fat: 10.4, emoji: '🥚'),
    InbuiltFood(name: 'Fresh Banana', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Evening Snack', type: 'Natural / Whole Food 🥬', calories: 105, protein: 1.3, carbs: 27, fat: 0.3, emoji: '🍌'),
    InbuiltFood(name: 'Red Apple', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 85, protein: 0.5, carbs: 22, fat: 0.3, emoji: '🍎'),
    InbuiltFood(name: 'Milk (Toned / Cow)', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 150, protein: 8.0, carbs: 12, fat: 5.0, emoji: '🥛'),
    InbuiltFood(name: 'Chai / Indian Tea', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Evening Snack', type: 'Daily Meals 🍲', calories: 65, protein: 1.5, carbs: 10, fat: 2.0, emoji: '☕'),
  ];

  static const List<InbuiltFood> allFoods = [
    // 1. Staples & Rice
    InbuiltFood(name: 'Steamed White Rice', category: 'Staples & Rice', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 205, protein: 4.2, carbs: 45, fat: 0.4, emoji: '🍚'),
    InbuiltFood(name: 'Curd Rice (Thair Sadam)', category: 'Staples & Rice', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 220, protein: 6.0, carbs: 32, fat: 7.0, emoji: '🍛'),
    InbuiltFood(name: 'Brown Rice', category: 'Staples & Rice', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 215, protein: 5.0, carbs: 45, fat: 1.8, emoji: '🌾'),
    InbuiltFood(name: 'Jeera / Ghee Rice', category: 'Staples & Rice', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 260, protein: 4.5, carbs: 42, fat: 8.0, emoji: '🍚'),
    InbuiltFood(name: 'Chicken Biryani', category: 'Staples & Rice', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 380, protein: 22.0, carbs: 45, fat: 13.0, emoji: '🍗'),
    InbuiltFood(name: 'Veg Biryani / Pulao', category: 'Staples & Rice', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Daily Meals 🍲', calories: 280, protein: 6.0, carbs: 48, fat: 7.5, emoji: '🥘'),
    InbuiltFood(name: 'Pongal / Khichdi', category: 'Staples & Rice', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 220, protein: 7.0, carbs: 36, fat: 5.5, emoji: '🍲'),

    // 2. Breads & Breakfast
    InbuiltFood(name: 'Chapati / Roti / Phulka', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Dinner', type: 'Daily Meals 🍲', calories: 85, protein: 3.1, carbs: 18, fat: 0.5, emoji: '🫓'),
    InbuiltFood(name: 'Poori (Fried)', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Fried / Junk 🍟', calories: 125, protein: 2.2, carbs: 15, fat: 6.5, emoji: '🥟'),
    InbuiltFood(name: 'Aloo Paratha', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 220, protein: 4.5, carbs: 32, fat: 8.5, emoji: '🫓'),
    InbuiltFood(name: 'Plain Dosa', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 130, protein: 3.5, carbs: 22, fat: 4.0, emoji: '🥞'),
    InbuiltFood(name: 'Masala Dosa', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 240, protein: 5.0, carbs: 36, fat: 8.5, emoji: '🥞'),
    InbuiltFood(name: 'Steamed Idli', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 55, protein: 2.0, carbs: 12, fat: 0.2, emoji: '⚪'),
    InbuiltFood(name: 'Upma / Rava Upma', category: 'Breads & Breakfast', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 190, protein: 4.5, carbs: 32, fat: 5.0, emoji: '🍲'),
    InbuiltFood(name: 'Poha (Flattened Rice)', category: 'Breads & Breakfast', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Daily Meals 🍲', calories: 180, protein: 3.5, carbs: 33, fat: 4.0, emoji: '🥣'),
    InbuiltFood(name: 'Bread Slice (Whole Wheat)', category: 'Breads & Breakfast', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 75, protein: 3.0, carbs: 13, fat: 1.0, emoji: '🍞'),

    // 3. Fruits (Fresh & Whole)
    InbuiltFood(name: 'Fresh Banana', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Evening Snack', type: 'Natural / Whole Food 🥬', calories: 105, protein: 1.3, carbs: 27, fat: 0.3, emoji: '🍌'),
    InbuiltFood(name: 'Red Apple', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 85, protein: 0.5, carbs: 22, fat: 0.3, emoji: '🍎'),
    InbuiltFood(name: 'Mango (Sweet)', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 135, protein: 1.1, carbs: 35, fat: 0.6, emoji: '🥭'),
    InbuiltFood(name: 'Orange / Mosambi', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 62, protein: 1.2, carbs: 15, fat: 0.2, emoji: '🍊'),
    InbuiltFood(name: 'Papaya (Cubes)', category: 'Fruits', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 60, protein: 0.9, carbs: 15, fat: 0.4, emoji: '🍈'),
    InbuiltFood(name: 'Guava (Peruka)', category: 'Fruits', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 50, protein: 2.5, carbs: 11, fat: 0.9, emoji: '🍏'),
    InbuiltFood(name: 'Watermelon (Cubes)', category: 'Fruits', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Evening Snack', type: 'Natural / Whole Food 🥬', calories: 45, protein: 0.9, carbs: 11, fat: 0.2, emoji: '🍉'),
    InbuiltFood(name: 'Pomegranate (Arils)', category: 'Fruits', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 120, protein: 2.5, carbs: 28, fat: 1.5, emoji: '🍇'),

    // 4. Curries & Proteins
    InbuiltFood(name: 'Dal Tadka / Yellow Dal', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 150, protein: 8.5, carbs: 22, fat: 3.5, emoji: '🍲'),
    InbuiltFood(name: 'South Indian Sambar', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 110, protein: 4.2, carbs: 18, fat: 2.5, emoji: '🍲'),
    InbuiltFood(name: 'Rasam (Pepper Garlic)', category: 'Curries & Proteins', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 50, protein: 1.5, carbs: 8, fat: 1.2, emoji: '🥣'),
    InbuiltFood(name: 'Paneer Butter Masala', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Dinner', type: 'Daily Meals 🍲', calories: 280, protein: 12.0, carbs: 12, fat: 20.0, emoji: '🧀'),
    InbuiltFood(name: 'Chana Masala / Chickpeas', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 230, protein: 11.0, carbs: 35, fat: 5.0, emoji: '🍛'),
    InbuiltFood(name: 'Boiled Egg', category: 'Curries & Proteins', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 75, protein: 6.3, carbs: 0.5, fat: 5.2, emoji: '🥚'),
    InbuiltFood(name: 'Egg Omelette (2 Eggs)', category: 'Curries & Proteins', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 160, protein: 13.0, carbs: 2.0, fat: 11.0, emoji: '🍳'),
    InbuiltFood(name: 'Chicken Curry', category: 'Curries & Proteins', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Dinner', type: 'Natural / Whole Food 🥬', calories: 240, protein: 26.0, carbs: 5, fat: 12.0, emoji: '🍗'),
    InbuiltFood(name: 'Fish Curry / Fry', category: 'Curries & Proteins', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 190, protein: 22.0, carbs: 3, fat: 9.0, emoji: '🐟'),

    // 5. Dairy & Drinks
    InbuiltFood(name: 'Fresh Curd / Yogurt', category: 'Dairy & Drinks', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 100, protein: 5.5, carbs: 7, fat: 4.0, emoji: '🥣'),
    InbuiltFood(name: 'Milk (Toned / Cow)', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 150, protein: 8.0, carbs: 12, fat: 5.0, emoji: '🥛'),
    InbuiltFood(name: 'Spiced Buttermilk / Chaas', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 45, protein: 2.2, carbs: 4, fat: 2.0, emoji: '🥛'),
    InbuiltFood(name: 'Chai / Indian Milk Tea', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Evening Snack', type: 'Daily Meals 🍲', calories: 65, protein: 1.5, carbs: 10, fat: 2.0, emoji: '☕'),
    InbuiltFood(name: 'Filter Coffee', category: 'Dairy & Drinks', defaultUnit: 'Cups', defaultQuantity: 1, defaultMealSlot: 'Morning Snack', type: 'Daily Meals 🍲', calories: 70, protein: 1.6, carbs: 11, fat: 2.2, emoji: '☕'),
    InbuiltFood(name: 'Almonds (Badam)', category: 'Dairy & Drinks', defaultUnit: 'Pcs (Pieces)', defaultQuantity: 10, defaultMealSlot: 'Morning Snack', type: 'Natural / Whole Food 🥬', calories: 70, protein: 2.5, carbs: 2.5, fat: 6.0, emoji: '🥜'),
    InbuiltFood(name: 'Peanut Butter (Natural)', category: 'Dairy & Drinks', defaultUnit: 'Spoons (tbsp)', defaultQuantity: 1, defaultMealSlot: 'Pre-Workout', type: 'Natural / Whole Food 🥬', calories: 95, protein: 4.0, carbs: 3.5, fat: 8.0, emoji: '🥜'),
    InbuiltFood(name: 'Oatmeal & Milk', category: 'Dairy & Drinks', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Breakfast', type: 'Natural / Whole Food 🥬', calories: 260, protein: 11.0, carbs: 42, fat: 5.5, emoji: '🥣'),
    InbuiltFood(name: 'Green Salad (Cucumber & Tomato)', category: 'Dairy & Drinks', defaultUnit: 'Bowls (Katori)', defaultQuantity: 1, defaultMealSlot: 'Lunch', type: 'Natural / Whole Food 🥬', calories: 45, protein: 1.8, carbs: 8, fat: 0.5, emoji: '🥗'),
  ];
}

class CalorieEstimationEngine {
  static const Map<String, Map<String, double>> foodDatabase = {
    'curd rice': {'per_bowl': 220.0, 'per_cup': 240.0, 'protein_bowl': 6.0, 'carbs_bowl': 32.0, 'fat_bowl': 7.0},
    'curdrice': {'per_bowl': 220.0, 'per_cup': 240.0, 'protein_bowl': 6.0, 'carbs_bowl': 32.0, 'fat_bowl': 7.0},
    'poori': {'per_pc': 125.0, 'protein_pc': 2.2, 'carbs_pc': 15.0, 'fat_pc': 6.5},
    'puri': {'per_pc': 125.0, 'protein_pc': 2.2, 'carbs_pc': 15.0, 'fat_pc': 6.5},
    'roti': {'per_pc': 85.0, 'protein_pc': 3.0, 'carbs_pc': 18.0, 'fat_pc': 0.5},
    'chapati': {'per_pc': 85.0, 'protein_pc': 3.0, 'carbs_pc': 18.0, 'fat_pc': 0.5},
    'phulka': {'per_pc': 75.0, 'protein_pc': 3.0, 'carbs_pc': 16.0, 'fat_pc': 0.3},
    'paratha': {'per_pc': 180.0, 'protein_pc': 4.0, 'carbs_pc': 26.0, 'fat_pc': 8.0},
    'dosa': {'per_pc': 130.0, 'protein_pc': 3.5, 'carbs_pc': 22.0, 'fat_pc': 4.0},
    'idli': {'per_pc': 55.0, 'protein_pc': 2.0, 'carbs_pc': 12.0, 'fat_pc': 0.2},
    'upma': {'per_bowl': 190.0, 'per_cup': 210.0, 'protein_bowl': 4.5, 'carbs_bowl': 32.0, 'fat_bowl': 5.0},
    'poha': {'per_bowl': 180.0, 'per_cup': 200.0, 'protein_bowl': 3.5, 'carbs_bowl': 33.0, 'fat_bowl': 4.0},
    'bread': {'per_pc': 75.0, 'protein_pc': 2.5, 'carbs_pc': 14.0, 'fat_pc': 1.0},
    'boiled egg': {'per_pc': 75.0, 'protein_pc': 6.3, 'carbs_pc': 0.5, 'fat_pc': 5.2},
    'egg': {'per_pc': 75.0, 'protein_pc': 6.0, 'carbs_pc': 0.5, 'fat_pc': 5.0},
    'omelet': {'per_pc': 120.0, 'protein_pc': 7.0, 'carbs_pc': 1.5, 'fat_pc': 9.5},
    'rice': {'per_cup': 205.0, 'per_bowl': 150.0, 'protein_cup': 4.2, 'carbs_cup': 45.0, 'fat_cup': 0.4},
    'dal': {'per_cup': 180.0, 'per_bowl': 150.0, 'protein_cup': 9.0, 'carbs_cup': 24.0, 'fat_cup': 3.5},
    'sambar': {'per_cup': 130.0, 'per_bowl': 110.0, 'protein_cup': 4.0, 'carbs_cup': 18.0, 'fat_cup': 2.5},
    'rasam': {'per_cup': 50.0, 'per_bowl': 45.0, 'protein_cup': 1.5, 'carbs_cup': 8.0, 'fat_cup': 1.2},
    'biryani': {'per_bowl': 380.0, 'per_cup': 320.0, 'protein_bowl': 20.0, 'carbs_bowl': 45.0, 'fat_bowl': 12.0},
    'curd': {'per_cup': 120.0, 'per_bowl': 100.0, 'protein_cup': 6.0, 'carbs_cup': 8.0, 'fat_cup': 4.0},
    'yogurt': {'per_cup': 120.0, 'per_bowl': 100.0, 'protein_cup': 6.0, 'carbs_cup': 8.0, 'fat_cup': 4.0},
    'milk': {'per_cup': 150.0, 'protein_cup': 8.0, 'carbs_cup': 12.0, 'fat_cup': 5.0},
    'buttermilk': {'per_cup': 45.0, 'protein_cup': 2.2, 'carbs_cup': 4.0, 'fat_cup': 2.0},
    'tea': {'per_cup': 65.0, 'protein_cup': 1.5, 'carbs_cup': 10.0, 'fat_cup': 2.0},
    'chai': {'per_cup': 65.0, 'protein_cup': 1.5, 'carbs_cup': 10.0, 'fat_cup': 2.0},
    'coffee': {'per_cup': 70.0, 'protein_cup': 1.6, 'carbs_cup': 11.0, 'fat_cup': 2.2},
    'chicken': {'per_pc': 165.0, 'per_cup': 230.0, 'per_bowl': 240.0, 'protein_pc': 28.0, 'carbs_pc': 2.0, 'fat_pc': 6.0},
    'fish': {'per_pc': 190.0, 'per_bowl': 210.0, 'protein_pc': 22.0, 'carbs_pc': 3.0, 'fat_pc': 9.0},
    'paneer': {'per_pc': 70.0, 'per_cup': 260.0, 'per_bowl': 280.0, 'protein_pc': 5.0, 'carbs_pc': 1.2, 'fat_pc': 5.5},
    'chana': {'per_bowl': 230.0, 'per_cup': 250.0, 'protein_bowl': 11.0, 'carbs_bowl': 35.0, 'fat_bowl': 5.0},
    'oats': {'per_cup': 150.0, 'per_bowl': 260.0, 'protein_cup': 5.5, 'carbs_cup': 27.0, 'fat_cup': 2.5},
    'banana': {'per_pc': 105.0, 'protein_pc': 1.3, 'carbs_pc': 27.0, 'fat_pc': 0.3},
    'apple': {'per_pc': 85.0, 'protein_pc': 0.5, 'carbs_pc': 22.0, 'fat_pc': 0.3},
    'mango': {'per_pc': 135.0, 'per_cup': 120.0, 'protein_pc': 1.1, 'carbs_pc': 35.0, 'fat_pc': 0.6},
    'orange': {'per_pc': 62.0, 'protein_pc': 1.2, 'carbs_pc': 15.0, 'fat_pc': 0.2},
    'papaya': {'per_cup': 60.0, 'per_bowl': 70.0, 'protein_cup': 0.9, 'carbs_cup': 15.0, 'fat_cup': 0.4},
    'guava': {'per_pc': 50.0, 'protein_pc': 2.5, 'carbs_pc': 11.0, 'fat_pc': 0.9},
    'watermelon': {'per_cup': 45.0, 'per_bowl': 55.0, 'protein_cup': 0.9, 'carbs_cup': 11.0, 'fat_cup': 0.2},
    'pomegranate': {'per_cup': 120.0, 'protein_cup': 2.5, 'carbs_cup': 28.0, 'fat_cup': 1.5},
    'almonds': {'per_pc': 7.0, 'per_spoon': 35.0, 'protein_spoon': 1.2, 'carbs_spoon': 1.0, 'fat_spoon': 3.0},
    'peanut butter': {'per_spoon': 95.0, 'protein_spoon': 4.0, 'carbs_spoon': 3.5, 'fat_spoon': 8.0},
    'salad': {'per_bowl': 50.0, 'per_cup': 35.0, 'protein_bowl': 2.0, 'carbs_bowl': 8.0, 'fat_bowl': 0.5},
  };

  static Map<String, double> calculate(String name, double quantity, String unit) {
    final clean = name.toLowerCase().trim();
    String? matchedKey;
    for (var k in foodDatabase.keys) {
      if (clean.contains(k)) {
        matchedKey = k;
        break;
      }
    }

    double baseCal = 120.0;
    double baseProtein = 4.0;
    double baseCarbs = 18.0;
    double baseFat = 3.0;

    if (matchedKey != null) {
      final data = foodDatabase[matchedKey]!;
      if (unit.contains('Pcs') || unit.contains('Piece')) {
        baseCal = data['per_pc'] ?? (data['per_cup'] != null ? data['per_cup']! * 0.5 : 85.0);
        baseProtein = data['protein_pc'] ?? 3.0;
        baseCarbs = data['carbs_pc'] ?? 15.0;
        baseFat = data['fat_pc'] ?? 2.0;
      } else if (unit.contains('Cup')) {
        baseCal = data['per_cup'] ?? (data['per_pc'] != null ? data['per_pc']! * 1.8 : 160.0);
        baseProtein = data['protein_cup'] ?? 6.0;
        baseCarbs = data['carbs_cup'] ?? 24.0;
        baseFat = data['fat_cup'] ?? 3.5;
      } else if (unit.contains('Bowl') || unit.contains('Katori')) {
        baseCal = data['per_bowl'] ?? (data['per_cup'] != null ? data['per_cup']! * 0.85 : 140.0);
        baseProtein = data['protein_bowl'] ?? (data['protein_cup'] != null ? data['protein_cup']! * 0.85 : 5.0);
        baseCarbs = data['carbs_bowl'] ?? (data['carbs_cup'] != null ? data['carbs_cup']! * 0.85 : 20.0);
        baseFat = data['fat_bowl'] ?? (data['fat_cup'] != null ? data['fat_cup']! * 0.85 : 3.0);
      } else if (unit.contains('Spoon') || unit.contains('tbsp')) {
        baseCal = data['per_spoon'] ?? 45.0;
        baseProtein = data['protein_spoon'] ?? 1.5;
        baseCarbs = data['carbs_spoon'] ?? 4.0;
        baseFat = data['fat_spoon'] ?? 3.0;
      } else if (unit.contains('Gram') || unit.contains('g')) {
        baseCal = 1.5;
        baseProtein = 0.08;
        baseCarbs = 0.20;
        baseFat = 0.04;
      }
    } else {
      if (unit.contains('Cup')) {
        baseCal = 180.0;
      } else if (unit.contains('Bowl') || unit.contains('Katori')) {
        baseCal = 150.0;
      } else if (unit.contains('Spoon')) {
        baseCal = 45.0;
      } else if (unit.contains('Gram')) {
        baseCal = 1.5;
      } else {
        baseCal = 90.0;
      }
    }

    final totalCal = (baseCal * quantity).clamp(0.0, 5000.0);
    final totalProtein = (baseProtein * quantity).clamp(0.0, 500.0);
    final totalCarbs = (baseCarbs * quantity).clamp(0.0, 1000.0);
    final totalFat = (baseFat * quantity).clamp(0.0, 500.0);

    return {
      'calories': totalCal,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }
}

class VocabularyWord {
  String word;
  String meaning;
  String example;
  DateTime loggedAt;

  VocabularyWord({required this.word, required this.meaning, required this.example, required this.loggedAt});
}

class EnglishListeningLog {
  String videoName;
  String videoLink;
  String userTitle;
  String content;
  DateTime loggedAt;

  EnglishListeningLog({required this.videoName, required this.videoLink, required this.userTitle, required this.content, required this.loggedAt});
}

// ---------------- GLOBAL APP DATA SYNC BUS ----------------
class AppSyncBus {
  static final ValueNotifier<int> syncTick = ValueNotifier<int>(0);
  static void notifyDataChanged() {
    syncTick.value++;
  }
}

// ---------------- ROOT NAVIGATION SHELL ----------------
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MasterDashboardScreen(),
    const AiCoachScreen(),
    const ExpenseScreen(),
    const WorkoutScreen(),
    const DailyLogScreen(),
    const FoodAndSnacksScreen(),
    const StrictGoalsScreen(),
    const WorkoutAndPhotosScreen(),
    const StudyAndEnglishScreen(),
    const MonthlyReportScreen(),
  ];

  final List<String> _screenTitles = [
    'Dashboard',
    'Titan AI Coach',
    'Finance & Expenses',
    '7-Day Gym Splits',
    'Routine & Recharge',
    'Nutrition & Food',
    'Strict Goals',
    'Workout & Photos',
    'Study & English',
    'Reports Hub',
  ];

  final List<IconData> _screenIcons = [
    Icons.speed_rounded,
    Icons.auto_awesome_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.fitness_center_rounded,
    Icons.wb_sunny_rounded,
    Icons.restaurant_menu_rounded,
    Icons.flag_rounded,
    Icons.camera_alt_rounded,
    Icons.psychology_rounded,
    Icons.assessment_rounded,
  ];

  final List<Color> _screenColors = [
    AppColors.secondary,
    AppColors.primary,
    AppColors.accentRose,
    AppColors.accentBlue,
    AppColors.accentAmber,
    AppColors.accentGreen,
    AppColors.primaryGlow,
    AppColors.accentPurple,
    AppColors.secondaryGlow,
    const Color(0xFF38BDF8),
  ];

  void _openNavigationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apps_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DISCIPLINE MODULES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                            Text('Navigate your growth ecosystem', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...List.generate(_screenTitles.length, (index) {
                      final isSelected = _currentIndex == index;
                      final color = _screenColors[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_screenIcons[index], color: color, size: 20),
                          ),
                          title: Text(
                            _screenTitles[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: color, size: 18)
                              : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white30),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _currentIndex = index);
                            AppSyncBus.notifyDataChanged();
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070B14), Color(0xFF0D1424), Color(0xFF090D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBrandingHeader(),
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.borderLight)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.25),
          selectedIndex: _currentIndex == 0 ? 0 : 1,
          elevation: 0,
          height: 64,
          onDestinationSelected: (index) {
            if (index == 0) {
              setState(() => _currentIndex = 0);
              AppSyncBus.notifyDataChanged();
            } else {
              _openNavigationMenu(context);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed_rounded, color: Colors.white70),
              selectedIcon: Icon(Icons.speed_rounded, color: AppColors.secondary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: Colors.white70),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.accentAmber),
              label: 'Modules Menu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBrandingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                // OFFICIAL GET SET GO LOGO EMBLEM
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF070B16),
                        child: const Icon(Icons.rocket_launch_rounded, color: AppColors.secondary, size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GET SET GO',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _screenColors[_currentIndex],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _screenColors[_currentIndex],
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _screenTitles[_currentIndex].toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                color: _screenColors[_currentIndex],
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TITAN AI QUICK BUTTON
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Titan Gemini AI Coach',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryGlow),
                ),
                onPressed: () => TitanAiSheet.show(context),
              ),
              const SizedBox(width: 8),

              // FIREBASE CLOUD & PROFILE BUTTON
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Account & Firebase Cloud Sync',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, size: 16, color: AppColors.secondary),
                ),
                onPressed: () => AccountCloudModal.show(context),
              ),
              const SizedBox(width: 8),

              // BMI INDICATOR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: HealthState.bmiColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HealthState.bmiColor.withValues(alpha: 0.4), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monitor_weight_rounded, size: 13, color: HealthState.bmiColor),
                    const SizedBox(width: 4),
                    Text(
                      HealthState.bmi > 0 ? 'BMI ${HealthState.bmi.toStringAsFixed(1)}' : 'BMI --',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: HealthState.bmiColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- TAB 1: MASTER DASHBOARD ----------------
class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({super.key});

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  String _selectedViewType = 'Daily';
  DateTime? _selectedFinishedDate;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _selectedWeek = ((DateTime.now().day - 1) ~/ 7) + 1;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<GoalItem> _goals = [];
  double _totalExpenseAmount = 0.0;
  double _totalStudyHours = 0.0;
  int _totalCumulativeStreaks = 0;
  final Set<DateTime> _completedDates = {};

  DateTime _currentDateTime = DateTime.now();
  Timer? _clockTimer;

  int _quoteIndex = 0;
  bool _previewNightlyReport = false;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      }
    });
    _loadDashboardData();
    AppSyncBus.syncTick.addListener(_loadDashboardData);
  }

  @override
  void dispose() {
    AppSyncBus.syncTick.removeListener(_loadDashboardData);
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDayOfWeek(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dt.weekday - 1];
  }

  String _formatFormattedDate(DateTime dt) {
    return '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';
  }

  String _formatFormattedTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  Future<void> _loadDashboardData() async {
    final goalsData = await DBHelper.instance.fetchGoals();
    final expenseData = await DBHelper.instance.fetchExpenses();
    final studyData = await DBHelper.instance.fetchStudyLogs();

    double expenseSum = 0;
    for (var e in expenseData) {
      expenseSum += (e['amount'] as num).toDouble();
    }

    // ACCURATELY PARSE EXACT STUDY SECONDS & HOURS FROM ALL LOGGED SESSIONS
    double studyHoursSum = 0.0;
    for (var s in studyData) {
      final timeStr = (s['timeSpent'] as String?) ?? '00:00:00';
      final parts = timeStr.split(':');
      if (parts.length == 3) {
        final h = double.tryParse(parts[0]) ?? 0.0;
        final m = double.tryParse(parts[1]) ?? 0.0;
        final sec = double.tryParse(parts[2]) ?? 0.0;
        studyHoursSum += h + (m / 60.0) + (sec / 3600.0);
      } else if (parts.length == 2) {
        final m = double.tryParse(parts[0]) ?? 0.0;
        final sec = double.tryParse(parts[1]) ?? 0.0;
        studyHoursSum += (m / 60.0) + (sec / 3600.0);
      }
    }

    int streakSum = 0;
    final parsedGoals = goalsData.map((e) {
      final item = GoalItem.fromMap(e);
      streakSum += item.currentStreak;
      return item;
    }).toList();

    if (mounted) {
      setState(() {
        _goals = parsedGoals;
        _totalExpenseAmount = expenseSum;
        _totalStudyHours = studyHoursSum;
        _totalCumulativeStreaks = streakSum;

        _completedDates.clear();
        for (var g in _goals) {
          if (g.lastCompletedDate != null) {
            _completedDates.add(DateTime(g.lastCompletedDate!.year, g.lastCompletedDate!.month, g.lastCompletedDate!.day));
          }
        }
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Champion ⚡';
    if (hour < 17) return 'Unstoppable Momentum 🚀';
    return 'Evening Mastery 🌙';
  }

  void _openMonthPicker(BuildContext context) {
    int tempYear = _selectedYear;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Month & Year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.secondary),
                          onPressed: () => setModalState(() => tempYear--),
                        ),
                        Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                          onPressed: () => setModalState(() => tempYear++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNumber = index + 1;
                    final isSelected = _selectedMonth == monthNumber && _selectedYear == tempYear;
                    final isCurrentMonth = DateTime.now().month == monthNumber && DateTime.now().year == tempYear;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = monthNumber;
                          _selectedYear = tempYear;
                          _selectedViewType = 'Monthly';
                          _selectedFinishedDate = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : (isCurrentMonth ? AppColors.secondary.withValues(alpha: 0.18) : AppColors.surfaceElevated),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGlow : (isCurrentMonth ? AppColors.secondary : AppColors.borderLight),
                            width: isSelected || isCurrentMonth ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          _monthNames[index].substring(0, 3),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? Colors.white : (isCurrentMonth ? AppColors.secondary : Colors.white70),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openWeekPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Select Week (${_monthNames[_selectedMonth - 1]} $_selectedYear)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              ...List.generate(5, (idx) {
                final weekNum = idx + 1;
                final startDay = (weekNum - 1) * 7 + 1;
                final endDay = math.min(weekNum * 7, 31);
                final isSelected = _selectedWeek == weekNum && _selectedViewType == 'Weekly';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary.withValues(alpha: 0.18) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppColors.secondary : AppColors.borderLight),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.calendar_view_week_rounded, color: isSelected ? AppColors.secondary : AppColors.textMuted),
                    title: Text('Week $weekNum: $startDay - $endDay ${_monthNames[_selectedMonth - 1].substring(0, 3)}', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 18) : null,
                    onTap: () {
                      setState(() {
                        _selectedWeek = weekNum;
                        _selectedViewType = 'Weekly';
                        _selectedFinishedDate = null;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openFinishedDatesCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.accentGreen),
                  ),
                  const SizedBox(width: 12),
                  const Text('Discipline Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Select any completed date to inspect historical performance:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              if (_completedDates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No finished dates recorded yet.', style: TextStyle(color: AppColors.textMuted))),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _completedDates.map((d) {
                    final formatted = '${d.day}/${d.month}/${d.year}';
                    final isSelected = _selectedFinishedDate != null &&
                        _selectedFinishedDate!.year == d.year &&
                        _selectedFinishedDate!.month == d.month &&
                        _selectedFinishedDate!.day == d.day;

                    return ActionChip(
                      avatar: Icon(Icons.check_circle_rounded, color: isSelected ? Colors.white : AppColors.accentGreen, size: 16),
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                      label: Text(formatted, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
                      onPressed: () {
                        setState(() {
                          _selectedViewType = 'Specific Date ($formatted)';
                          _selectedFinishedDate = d;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.borderLight)),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Add Strict Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Goal Title (e.g. 30 Days No Sugar)')),
            const SizedBox(height: 12),
            TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Days (e.g. 30)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
              if (title.isNotEmpty && days > 0) {
                final newGoal = GoalItem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, targetDays: days);
                await DBHelper.instance.insertGoal(newGoal.toMap());
                _loadDashboardData();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  DisciplineFeedback.showCelebration(
                    context: context,
                    title: '🎯 Strict Goal Committed!',
                    message: 'You have committed to "$title" for $days Days. Stand firm and execute daily!',
                    disciplineQuote: 'Commitment means doing what you said you would do, long after the mood you said it in has left you.',
                    color: AppColors.primary,
                  );
                }
              }
            },
            child: const Text('Commit Goal'),
          ),
        ],
      ),
    );
  }

  void _showAccountabilityApologyDialog(BuildContext context, GoalItem goal) {
    final apologyCtrl = TextEditingController();
    String selectedReason = 'Lost Motivation / Inconsistency';
    final reasons = [
      'Lost Motivation / Inconsistency',
      'Target was Unrealistic / Overwhelming',
      'Procrastination & Distractions',
      'Health / Emergency Reason',
      'Replacing with Higher Standard Goal',
      'Other Personal Reason',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.accentRose, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 22),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Apology & Accountability',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breaking streak for "${goal.title}"',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Achieved Day ${goal.currentStreak} of ${goal.targetDays} Days. All broken streaks are permanently tracked in your Apology Archive.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('1. Why are you deleting / quitting this goal?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedReason = val ?? reasons[0]),
                ),
                const SizedBox(height: 14),
                const Text('2. Apology Letter & Reflection (Min 10 chars):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: apologyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'I apologize to myself because I lost discipline... I resolve to recommit by...',
                    hintStyle: TextStyle(fontSize: 11.5, color: Colors.white30),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Keep Goal & Persevere 💪', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
              onPressed: () async {
                final text = apologyCtrl.text.trim();
                if (text.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a genuine apology & reflection (at least 10 characters).')),
                  );
                  return;
                }
                await DBHelper.instance.insertDeletedGoal({
                  'title': goal.title,
                  'streakAchieved': goal.currentStreak,
                  'targetDays': goal.targetDays,
                  'apologyLetter': '[Reason: $selectedReason]\n$text',
                  'deletedAt': DateTime.now().toIso8601String(),
                });
                await DBHelper.instance.deleteGoal(goal.id);
                _loadDashboardData();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  DisciplineFeedback.showEncouragement(
                    context: context,
                    title: '🛡️ Apology Archived & Recommitment',
                    message: 'Your reflection has been recorded. Setbacks are just setups for a comeback. Recommit soon!',
                    confidenceQuote: 'A champion is not defined by their falls, but by how relentlessly they rise. Rebuild your standard now!',
                  );
                }
              },
              child: const Text('Sign Apology & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openApologyArchiveModal(BuildContext context) async {
    final deletedRecords = await DBHelper.instance.fetchDeletedGoals();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.accentRose, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BROKEN STREAKS & APOLOGY ARCHIVE', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.accentRose)),
                      Text('Learn from past setbacks & stay accountable', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: deletedRecords.isEmpty
                    ? const Center(
                        child: Text('No broken goals recorded! You have maintained complete streak integrity! 🏆', textAlign: TextAlign.center, style: TextStyle(color: AppColors.accentGreen, fontSize: 13)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: deletedRecords.length,
                        itemBuilder: (ctx, i) {
                          final rec = deletedRecords[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderLight)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(child: Text(rec['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white), overflow: TextOverflow.ellipsis)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                        child: Text('Ended at Day ${rec['streakAchieved']}/${rec['targetDays']}', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                                    child: Text(
                                      rec['apologyLetter'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Deleted: ${rec['deletedAt']?.toString().substring(0, 10)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double weightDiff = (HealthState.weightKg - HealthState.targetWeightKg);
    bool isMonthlyView = _selectedViewType == 'Monthly';
    bool isYearlyView = _selectedViewType == 'Yearly';
    bool isWeeklyView = _selectedViewType == 'Weekly';
    bool hasCompletedGoalsToday = _goals.any((g) => g.isCompletedToday);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. LIVE ORIGINAL REAL-TIME DATE & TIME CARD
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF131D33), Color(0xFF1B1736)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatFormattedDate(_currentDateTime),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDayOfWeek(_currentDateTime),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppColors.primaryGlow, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _formatFormattedTime(_currentDateTime),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DYNAMIC MOTIVATION FUEL & TICKER BANNER
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasCompletedGoalsToday
                      ? [const Color(0xFF102A24), const Color(0xFF161F33)]
                      : [const Color(0xFF2B1B15), const Color(0xFF181B2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasCompletedGoalsToday ? AppColors.accentGreen.withValues(alpha: 0.4) : AppColors.accentAmber.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasCompletedGoalsToday ? AppColors.accentGreen.withValues(alpha: 0.08) : AppColors.accentAmber.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    hasCompletedGoalsToday ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
                    color: hasCompletedGoalsToday ? AppColors.accentGreen : AppColors.accentAmber,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasCompletedGoalsToday
                          ? MotivationEngine.winningQuotes[_quoteIndex % MotivationEngine.winningQuotes.length]
                          : MotivationEngine.encouragementQuotes[_quoteIndex % MotivationEngine.encouragementQuotes.length],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: hasCompletedGoalsToday ? Colors.white : const Color(0xFFFED7AA),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                    tooltip: 'Boost Motivation',
                    onPressed: () {
                      setState(() => _quoteIndex++);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.surfaceElevated,
                          content: Text('⚡ Motivation Booster Applied! Focus and dominate today!', style: TextStyle(color: AppColors.secondaryGlow)),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // NIGHTLY 9:30 PM OVERALL TARGETS REPORT & MASTERY GREETING
            _buildNightlyMasteryReportCard(),

            // GREETING & VIEW FILTER BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DISCIPLINE & METRICS HUB',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 10, color: AppColors.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderLight)),
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedViewType.startsWith('Specific') ? Icons.calendar_month_rounded : Icons.filter_alt_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _selectedViewType == 'Weekly'
                                ? 'Week $_selectedWeek'
                                : (_selectedViewType == 'Monthly'
                                    ? '${_monthNames[_selectedMonth - 1].substring(0, 3)} $_selectedYear'
                                    : (_selectedViewType == 'Yearly'
                                        ? 'Year $_selectedYear'
                                        : (_selectedViewType.length > 9 ? '${_selectedViewType.substring(0, 8)}..' : _selectedViewType))),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'OpenCalendar') {
                      _openFinishedDatesCalendar();
                    } else if (val == 'OpenMonthPicker') {
                      _openMonthPicker(context);
                    } else if (val == 'OpenWeekPicker') {
                      _openWeekPicker(context);
                    } else if (val == 'OpenApologyArchive') {
                      _openApologyArchiveModal(context);
                    } else {
                      setState(() {
                        _selectedViewType = val;
                        _selectedFinishedDate = null;
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'Daily', child: Text('Daily Focus')),
                    const PopupMenuItem(value: 'Weekly', child: Text('Weekly Aggregate')),
                    const PopupMenuItem(value: 'Monthly', child: Text('Monthly Overview')),
                    const PopupMenuItem(value: 'Yearly', child: Text('Yearly Overview (12 Months)')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'OpenWeekPicker',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_view_week_rounded, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Text('Select Week...', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'OpenMonthPicker',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_view_month_rounded, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Text('Select Month...', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'OpenCalendar',
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, color: AppColors.accentGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Discipline Calendar', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'OpenApologyArchive',
                      child: Row(
                        children: [
                          Icon(Icons.history_edu_rounded, color: AppColors.accentRose, size: 18),
                          SizedBox(width: 8),
                          Text('Apology Archive', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // WEEK PICKER INTERACTIVE BAR (IF WEEKLY VIEW)
            if (isWeeklyView) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.secondary),
                      onPressed: () {
                        setState(() {
                          if (_selectedWeek > 1) {
                            _selectedWeek--;
                          } else {
                            _selectedWeek = 5;
                          }
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () => _openWeekPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_view_week_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text(
                              'Week $_selectedWeek (${(_selectedWeek - 1) * 7 + 1}-${math.min(_selectedWeek * 7, 31)} ${_monthNames[_selectedMonth - 1].substring(0, 3)})',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12.5),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                      onPressed: () {
                        setState(() {
                          if (_selectedWeek < 5) {
                            _selectedWeek++;
                          } else {
                            _selectedWeek = 1;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            // MONTH PICKER INTERACTIVE BAR (IF MONTHLY VIEW)
            if (isMonthlyView) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.secondary),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 1) {
                            _selectedMonth = 12;
                            _selectedYear--;
                          } else {
                            _selectedMonth--;
                          }
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () => _openMonthPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primaryGlow),
                            const SizedBox(width: 6),
                            Text(
                              '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 12) {
                            _selectedMonth = 1;
                            _selectedYear++;
                          } else {
                            _selectedMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            // YEAR PICKER INTERACTIVE BAR (IF YEARLY VIEW)
            if (isYearlyView) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.primaryGlow),
                      onPressed: () => setState(() => _selectedYear--),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGlow),
                          const SizedBox(width: 6),
                          Text('Yearly Discipline Overview: $_selectedYear', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGlow),
                      onPressed: () => setState(() => _selectedYear++),
                    ),
                  ],
                ),
              ),
            ],

            // TOTAL STREAK HERO BANNER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF261036), Color(0xFF161B30), Color(0xFF0F2027)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accentAmber, AppColors.accentRose]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.4), blurRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isYearlyView
                                    ? 'ANNUAL DISCIPLINE STREAKS'
                                    : (isMonthlyView
                                        ? 'MONTHLY DISCIPLINE STREAKS'
                                        : (isWeeklyView ? 'WEEK $_selectedWeek STREAKS' : 'DISCIPLINE STREAKS')),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isYearlyView
                                    ? '$_selectedYear Total Mastery'
                                    : (isMonthlyView
                                        ? '${_monthNames[_selectedMonth - 1]} Mastery'
                                        : (isWeeklyView ? 'Week $_selectedWeek Focus' : 'Active Cumulative Mastery')),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$_totalCumulativeStreaks Days 🔥',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentAmber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 1. MONTHLY WEIGHT LINE GRAPH OR TARGET PROGRESSION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF131D33), Color(0xFF1A1633)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HealthState.bmiColor.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: HealthState.bmiColor.withValues(alpha: 0.12), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isYearlyView
                                  ? 'YEARLY WEIGHT TREND & TRANSFORMATION'
                                  : (isMonthlyView ? '${_monthNames[_selectedMonth - 1].toUpperCase()} WEIGHT BEZIER GRAPH' : 'BODY TRANSFORMATION TARGET'),
                              style: const TextStyle(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  HealthState.weightKg > 0 ? '${HealthState.weightKg} kg' : '-- kg',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: HealthState.bmiColor),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white54),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    HealthState.targetWeightKg > 0 ? '${HealthState.targetWeightKg} kg target' : '-- kg target',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: HealthState.bmiColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HealthState.bmiColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          HealthState.weightKg == 0 || HealthState.targetWeightKg == 0
                              ? 'Set in Workout'
                              : (weightDiff > 0 ? '${weightDiff.toStringAsFixed(1)} kg to lose' : (weightDiff < 0 ? '${(-weightDiff).toStringAsFixed(1)} kg to gain' : 'Target Met! 🎉')),
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: HealthState.bmiColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isMonthlyView || isYearlyView) _buildMonthlyWeightLineChart() else _buildWeightProgressComparisonGraph(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. 4 GLOWING METRIC TILES
            Row(
              children: [
                _buildNeonTile('SETS', '${WorkoutState.completedSetsCount}', '/ ${WorkoutState.totalSetsCount}', Icons.repeat_rounded, AppColors.secondary),
                const SizedBox(width: 8),
                _buildNeonTile('REPS', '${WorkoutState.totalRepsCount}', 'total', Icons.bolt_rounded, AppColors.accentGreen),
                const SizedBox(width: 8),
                _buildNeonTile(
                  'STUDY',
                  _totalStudyHours < 1 ? '${(_totalStudyHours * 60).toInt()}m' : _totalStudyHours.toStringAsFixed(1),
                  _totalStudyHours < 1 ? 'mins' : 'hrs',
                  Icons.timer_rounded,
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildNeonTile('EXPENSE', '₹${_totalExpenseAmount.toInt()}', 'total', Icons.account_balance_wallet_rounded, AppColors.accentRose),
              ],
            ),
            const SizedBox(height: 14),

            // 2.5 WORKOUT, SETS & REPS TRACKER HUB
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F1E33), Color(0xFF131733), Color(0xFF1F132E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.1), blurRadius: 14),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.fitness_center_rounded, color: AppColors.accentBlue, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'WORKOUT, SETS & REPS TRACKER',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.accentBlue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (WorkoutState.completedExercisesCount == WorkoutState.totalExercisesCount && WorkoutState.totalExercisesCount > 0
                                  ? AppColors.accentGreen
                                  : AppColors.accentBlue)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: WorkoutState.completedExercisesCount == WorkoutState.totalExercisesCount && WorkoutState.totalExercisesCount > 0
                                ? AppColors.accentGreen
                                : AppColors.accentBlue,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          WorkoutState.totalExercisesCount == 0
                              ? 'No Exercises'
                              : '${WorkoutState.completedExercisesCount}/${WorkoutState.totalExercisesCount} Conquered',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: WorkoutState.completedExercisesCount == WorkoutState.totalExercisesCount && WorkoutState.totalExercisesCount > 0
                                ? AppColors.accentGreen
                                : AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkoutStatMini(
                          'EXERCISES',
                          '${WorkoutState.completedExercisesCount}/${WorkoutState.totalExercisesCount}',
                          'Logged',
                          Icons.fitness_center_rounded,
                          AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutStatMini(
                          'SETS',
                          '${WorkoutState.completedSetsCount}/${WorkoutState.totalSetsCount}',
                          'Total Sets',
                          Icons.repeat_rounded,
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutStatMini(
                          'REPS',
                          '${WorkoutState.totalRepsCount}',
                          '/ ${WorkoutState.totalTargetReps} Reps',
                          Icons.bolt_rounded,
                          AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (WorkoutState.exercises.isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.borderLight),
                    ...WorkoutState.exercises.take(3).map((ex) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      ex.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 15,
                                      color: ex.isDone ? AppColors.accentGreen : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ex.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: ex.isDone ? Colors.white70 : Colors.white,
                                          decoration: ex.isDone ? TextDecoration.lineThrough : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ex.formattedTarget,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (WorkoutState.exercises.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${WorkoutState.exercises.length - 3} more exercises tracked in Workout tab',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('No exercises added yet. Open Workout tab to log exercises, sets & reps!', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2.8 WALKING & JOGGING DISTANCE HUB & LINE GRAPH
            _buildWalkingJoggingDistanceCard(),
            const SizedBox(height: 16),

            // 3. DYNAMIC GLOWING TREND LINE CHART (WEEKLY / MONTHLY / YEARLY)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          isYearlyView
                              ? '12-MONTH YEARLY DISCIPLINE LINE TREND'
                              : (isMonthlyView
                                  ? '${_monthNames[_selectedMonth - 1].toUpperCase()} WEEKLY LINE BREAKDOWN'
                                  : (isWeeklyView
                                      ? 'WEEK $_selectedWeek LINE TREND (SUN - SAT)'
                                      : (_selectedViewType == 'Daily' ? 'TODAY\'S DISCIPLINE & MILESTONES' : 'WEEKLY DISCIPLINE LINE TREND (SUN - SAT)'))),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isWeeklyView
                              ? 'WEEK $_selectedWeek'
                              : (isMonthlyView
                                  ? '${_monthNames[_selectedMonth - 1].substring(0, 3).toUpperCase()} $_selectedYear'
                                  : (isYearlyView ? 'YEAR $_selectedYear' : _selectedViewType.toUpperCase())),
                          style: const TextStyle(color: AppColors.secondary, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardTrendLineChart(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. ACTIVE STRICT GOALS HUB
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ACTIVE STREAKS',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.accentRose),
                      tooltip: 'Apology Archive',
                      onPressed: () => _openApologyArchiveModal(context),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      onPressed: _showAddGoalDialog,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Goal', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_goals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
                  child: Text('No active strict goals. Tap "+ Add Goal" to start your streak!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              )
            else
              ..._goals.map((g) {
                final progress = (g.currentStreak / g.targetDays).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Day ${g.currentStreak}/${g.targetDays}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
                                tooltip: 'Delete & Sign Apology',
                                onPressed: () => _showAccountabilityApologyDialog(context, g),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text('${(progress * 100).toInt()}% Achieved 🎯', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: g.isCompletedToday ? AppColors.surfaceElevated : AppColors.accentGreen.withValues(alpha: 0.18),
                              foregroundColor: g.isCompletedToday ? Colors.white54 : AppColors.accentGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: g.isCompletedToday ? Colors.white24 : AppColors.accentGreen.withValues(alpha: 0.5)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 30),
                            ),
                            onPressed: () async {
                              final done = g.completeToday();
                              if (done) {
                                await DBHelper.instance.updateGoal(g.id, g.currentStreak, g.lastCompletedDate?.toIso8601String());
                                _loadDashboardData();
                                if (context.mounted) {
                                  DisciplineFeedback.showCelebration(
                                    context: context,
                                    title: '🏆 STREAK CONQUERED!',
                                    message: 'Day ${g.currentStreak} achieved for "${g.title}"! Your consistency is building an unbreakable habit.',
                                    disciplineQuote: 'Success is the sum of small efforts repeated day in and day out.',
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  DisciplineFeedback.showEncouragement(
                                    context: context,
                                    title: '✅ Daily Check-in Completed!',
                                    message: 'You have already conquered "${g.title}" today. Rest and recharge for Day ${g.currentStreak + 1} tomorrow!',
                                    confidenceQuote: 'Recovery is part of the discipline. Trust the process and return energized.',
                                  );
                                }
                              }
                            },
                            icon: Icon(g.isCompletedToday ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, size: 14),
                            label: Text(g.isCompletedToday ? 'Done Today ✅' : 'Check In', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyWeightLineChart() {
    if (HealthState.monthlyWeightHistory.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('Log weight entries in Workout to generate line trend chart.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: MonthlyWeightLinePainter(
              weights: HealthState.monthlyWeightHistory,
              targetWeight: HealthState.targetWeightKg,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            HealthState.monthlyWeightHistory.length,
            (i) => Text(
              i == HealthState.monthlyWeightHistory.length - 1 ? 'Current' : 'Week ${i + 1}',
              style: TextStyle(
                fontSize: 10,
                color: i == HealthState.monthlyWeightHistory.length - 1 ? AppColors.secondary : AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightProgressComparisonGraph() {
    if (HealthState.weightKg == 0 && HealthState.targetWeightKg == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Log Current & Target Weight in Workout tab to activate progress track.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      );
    }
    double current = HealthState.weightKg;
    double target = HealthState.targetWeightKg;
    double maxScale = (current > target ? current : target) + 10;

    double currentBarWidth = maxScale > 0 ? (current / maxScale).clamp(0.05, 1.0) : 0.0;
    double targetBarWidth = maxScale > 0 ? (target / maxScale).clamp(0.05, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Current', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted))),
            Expanded(
              child: Stack(
                children: [
                  Container(height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
                  FractionallySizedBox(
                    widthFactor: currentBarWidth,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryGlow]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${current.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Target Goal', style: TextStyle(fontSize: 11.5, color: AppColors.secondary))),
            Expanded(
              child: Stack(
                children: [
                  Container(height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
                  FractionallySizedBox(
                    widthFactor: targetBarWidth,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.secondaryGlow]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${target.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildNeonTile(String title, String val, String unit, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
            Text(unit, style: const TextStyle(fontSize: 8, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStatMini(String title, String val, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(child: Text(title, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 3),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildNightlyMasteryReportCard() {
    final now = DateTime.now();
    final bool isNightTime = (now.hour > 21 || (now.hour == 21 && now.minute >= 30));
    final bool showReport = isNightTime || _previewNightlyReport;

    if (!showReport) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.nights_stay_rounded, size: 16, color: AppColors.primaryGlow),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Nightly 9:30 PM Target Mastery Report', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: const Size(0, 26)),
              onPressed: () => setState(() => _previewNightlyReport = true),
              child: const Text('Preview Now 🌙', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
            ),
          ],
        ),
      );
    }

    final int totalGoals = _goals.length;
    final int goalsCompleted = _goals.where((g) => g.isCompletedToday).length;
    final double goalScore = totalGoals == 0 ? 1.0 : (goalsCompleted / totalGoals);
    final double workoutScore = WorkoutState.totalExercisesCount == 0 ? 1.0 : (WorkoutState.completedExercisesCount / WorkoutState.totalExercisesCount);
    final int overallPct = ((goalScore * 0.5 + workoutScore * 0.5) * 100).toInt();

    String greeting;
    String greetingSubtitle;
    Color greetingColor;
    if (overallPct >= 80) {
      greeting = '👑 Masterful Daily Triumph!';
      greetingSubtitle = 'Outstanding! You dominated today\'s targets with exceptional discipline and focus. Rest deeply!';
      greetingColor = AppColors.accentGreen;
    } else if (overallPct >= 50) {
      greeting = '⚡ Strong Discipline Momentum!';
      greetingSubtitle = 'Great progress today! Finish any remaining night logs and wake up even hungrier tomorrow.';
      greetingColor = AppColors.secondary;
    } else {
      greeting = '🛡️ Daily Review & Accountability!';
      greetingSubtitle = 'Today tested your grit. Reflect on your goals, learn from gaps, and execute relentlessly at dawn.';
      greetingColor = AppColors.accentAmber;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1436), Color(0xFF131A33), Color(0xFF0D242B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: greetingColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: greetingColor.withValues(alpha: 0.16), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: greetingColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.nights_stay_rounded, color: greetingColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('9:30 PM OVERALL TARGETS REPORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white70), overflow: TextOverflow.ellipsis),
                          Text(greeting, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: greetingColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_previewNightlyReport && !isNightTime)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  tooltip: 'Hide Preview',
                  onPressed: () => setState(() => _previewNightlyReport = false),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            greetingSubtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildNightlyBadge('Strict Goals', '$goalsCompleted/$totalGoals Conquered', AppColors.primary),
              _buildNightlyBadge('Workout', '${WorkoutState.completedExercisesCount}/${WorkoutState.totalExercisesCount} Ex (${WorkoutState.totalRepsCount} Reps)', AppColors.accentGreen),
              _buildNightlyBadge('Distance', '${WorkoutState.totalDistanceKm.toStringAsFixed(1)} km Covered', AppColors.secondary),
              _buildNightlyBadge('Study', _totalStudyHours < 1 ? '${(_totalStudyHours * 60).toInt()} mins' : '${_totalStudyHours.toStringAsFixed(1)} hrs', AppColors.primaryGlow),
              _buildNightlyBadge('Daily Master Score', '$overallPct% Complete', greetingColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNightlyBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$label: ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          Text(val, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showLogDistanceDialog() {
    final walkKmCtrl = TextEditingController(text: WorkoutState.walkDistanceKm.toStringAsFixed(1));
    final jogKmCtrl = TextEditingController(text: WorkoutState.jogDistanceKm.toStringAsFixed(1));
    final walkMinsCtrl = TextEditingController(text: WorkoutState.walkMins.toString());
    final jogMinsCtrl = TextEditingController(text: WorkoutState.jogMins.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final currentWalkKm = double.tryParse(walkKmCtrl.text.trim()) ?? 0.0;
          final currentJogKm = double.tryParse(jogKmCtrl.text.trim()) ?? 0.0;
          final totalKm = currentWalkKm + currentJogKm;

          void updateFromWalkKm(String val) {
            final km = double.tryParse(val) ?? 0.0;
            final mins = (km / 0.08).round();
            walkMinsCtrl.text = mins.toString();
            setModalState(() {});
          }

          void updateFromWalkMins(String val) {
            final mins = int.tryParse(val) ?? 0;
            final km = mins * 0.08;
            walkKmCtrl.text = km.toStringAsFixed(1);
            setModalState(() {});
          }

          void updateFromJogKm(String val) {
            final km = double.tryParse(val) ?? 0.0;
            final mins = (km / 0.15).round();
            jogMinsCtrl.text = mins.toString();
            setModalState(() {});
          }

          void updateFromJogMins(String val) {
            final mins = int.tryParse(val) ?? 0;
            final km = mins * 0.15;
            jogKmCtrl.text = km.toStringAsFixed(1);
            setModalState(() {});
          }

          void addPresetKm(double km, bool isJog) {
            if (isJog) {
              final newKm = currentJogKm + km;
              jogKmCtrl.text = newKm.toStringAsFixed(1);
              jogMinsCtrl.text = (newKm / 0.15).round().toString();
            } else {
              final newKm = currentWalkKm + km;
              walkKmCtrl.text = newKm.toStringAsFixed(1);
              walkMinsCtrl.text = (newKm / 0.08).round().toString();
            }
            setModalState(() {});
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.accentBlue, width: 1.2)),
            title: const Row(
              children: [
                Icon(Icons.directions_run_rounded, color: AppColors.accentBlue, size: 22),
                SizedBox(width: 8),
                Text('Log Daily Distance (KM)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your Walking & Jogging distance in Kilometers or Minutes:', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                  const SizedBox(height: 14),

                  // 1. WALKING INPUT (KM + MINS)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white70),
                            SizedBox(width: 6),
                            Text('🚶 WALKING DISTANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: walkKmCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Distance (KM)', isDense: true),
                                onChanged: updateFromWalkKm,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: walkMinsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Mins', isDense: true),
                                onChanged: updateFromWalkMins,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ActionChip(label: const Text('+1.0 km'), onPressed: () => addPresetKm(1.0, false)),
                              const SizedBox(width: 4),
                              ActionChip(label: const Text('+2.0 km'), onPressed: () => addPresetKm(2.0, false)),
                              const SizedBox(width: 4),
                              ActionChip(label: const Text('+3.0 km'), onPressed: () => addPresetKm(3.0, false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. JOGGING INPUT (KM + MINS)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_run_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text('🏃 JOGGING / RUNNING DISTANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: jogKmCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Distance (KM)', isDense: true),
                                onChanged: updateFromJogKm,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: jogMinsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Mins', isDense: true),
                                onChanged: updateFromJogMins,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ActionChip(label: const Text('+1.0 km'), onPressed: () => addPresetKm(1.0, true)),
                              const SizedBox(width: 4),
                              ActionChip(label: const Text('+2.0 km'), onPressed: () => addPresetKm(2.0, true)),
                              const SizedBox(width: 4),
                              ActionChip(label: const Text('+5.0 km'), onPressed: () => addPresetKm(5.0, true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // TOTAL PREVIEW
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL DISTANCE TODAY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                        Text('${totalKm.toStringAsFixed(1)} KM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accentGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                onPressed: () async {
                  final wKm = double.tryParse(walkKmCtrl.text.trim()) ?? ((int.tryParse(walkMinsCtrl.text.trim()) ?? 0) * 0.08);
                  final jKm = double.tryParse(jogKmCtrl.text.trim()) ?? ((int.tryParse(jogMinsCtrl.text.trim()) ?? 0) * 0.15);
                  final wM = int.tryParse(walkMinsCtrl.text.trim()) ?? (wKm / 0.08).round();
                  final jM = int.tryParse(jogMinsCtrl.text.trim()) ?? (jKm / 0.15).round();

                  setState(() {
                    WorkoutState.updateDistance(
                      walkKm: wKm,
                      jogKm: jKm,
                      walkMinutes: wM,
                      jogMinutes: jM,
                    );
                  });

                  await HierarchicalStorageManager.saveDailyRecord(
                    date: DateTime.now(),
                    data: {
                      'type': 'DistanceLog',
                      'walkKm': wKm,
                      'jogKm': jKm,
                      'walkMins': wM,
                      'jogMins': jM,
                      'totalKm': WorkoutState.totalDistanceKm,
                    },
                  );

                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    DisciplineFeedback.showCelebration(
                      context: context,
                      title: '🏃 ${WorkoutState.totalDistanceKm.toStringAsFixed(1)} KM Distance Logged!',
                      message: 'Walk: ${wKm.toStringAsFixed(1)} km ($wM mins) | Jog: ${jKm.toStringAsFixed(1)} km ($jM mins).\nYour physical engine is built one stride at a time!',
                      disciplineQuote: 'Continuous improvement is better than delayed perfection.',
                      color: AppColors.accentBlue,
                      icon: Icons.directions_run_rounded,
                    );
                  }
                },
                child: const Text('Save & Update Graph', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalkingJoggingDistanceCard() {
    final double totalKm = WorkoutState.totalDistanceKm;
    final double walkKm = WorkoutState.walkDistanceKm;
    final double jogKm = WorkoutState.jogDistanceKm;
    final List<double> history = WorkoutState.weeklyDistanceHistory;
    final int todayIdx = (DateTime.now().weekday % 7);
    final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2533), Color(0xFF132038), Color(0xFF151930)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.12), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.directions_run_rounded, color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'WALKING & JOGGING DISTANCE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: AppColors.accentBlue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  minimumSize: const Size(0, 26),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _showLogDistanceDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 14, color: Colors.white),
                label: const Text('Log 🏃', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Walk: ${WorkoutState.walkMins}m (~${walkKm.toStringAsFixed(1)}km)', style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const Text('•', style: TextStyle(color: Colors.white30)),
                  Text('Jog: ${WorkoutState.jogMins}m (~${jogKm.toStringAsFixed(1)}km)', style: const TextStyle(fontSize: 10.5, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  const Text('•', style: TextStyle(color: Colors.white30)),
                  const Text('5.0 km Goal', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${totalKm.toStringAsFixed(1)} km Today',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accentGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: WalkingJoggingDistanceLinePainter(
                distances: history,
                days: days,
                currentDayIndex: todayIdx,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(days.length, (i) {
              final isCurrent = i == todayIdx;
              return Text(
                days[i],
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                  color: isCurrent ? AppColors.accentGreen : AppColors.textMuted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTrendLineChart() {
    final int totalGoals = _goals.length;
    final int goalsCompleted = _goals.where((g) => g.isCompletedToday).length;
    final double goalScore = totalGoals == 0 ? 100.0 : ((goalsCompleted / totalGoals) * 100.0);
    final double workoutScore = WorkoutState.totalExercisesCount == 0 ? 100.0 : ((WorkoutState.completedExercisesCount / WorkoutState.totalExercisesCount) * 100.0);
    final double cardioScore = (WorkoutState.totalDistanceKm / 5.0).clamp(0.0, 1.0) * 100.0;
    final double todayScore = ((goalScore * 0.45 + workoutScore * 0.40 + cardioScore * 0.15)).clamp(10.0, 100.0);

    if (_selectedViewType == 'Yearly') {
      List<String> yearMonths = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      int currentMonthIndex = DateTime.now().month - 1;
      List<double> values = [65, 72, 80, 75, 88, 92, 85, 90, 84, 89, 94, 91];
      if (_selectedYear == DateTime.now().year && currentMonthIndex < values.length) {
        values[currentMonthIndex] = double.parse(todayScore.toStringAsFixed(1));
      }

      return Column(
        children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: DashboardTrendLinePainter(
                values: values,
                labels: yearMonths,
                activeIndex: _selectedYear == DateTime.now().year ? currentMonthIndex : -1,
                startColor: AppColors.primary,
                endColor: AppColors.secondary,
                unit: '%',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(yearMonths.length, (i) {
              final isCurrent = i == currentMonthIndex && _selectedYear == DateTime.now().year;
              return Text(
                yearMonths[i],
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                  color: isCurrent ? AppColors.secondary : AppColors.textMuted,
                ),
              );
            }),
          ),
        ],
      );
    }

    if (_selectedViewType == 'Monthly') {
      List<String> weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      int currentWeekIndex = math.min(_selectedWeek - 1, 3);
      List<double> values = [70, 78, 85, 92];
      if (currentWeekIndex < values.length) {
        values[currentWeekIndex] = double.parse(todayScore.toStringAsFixed(1));
      }

      return Column(
        children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: DashboardTrendLinePainter(
                values: values,
                labels: weeks,
                activeIndex: currentWeekIndex,
                startColor: AppColors.secondary,
                endColor: AppColors.accentGreen,
                unit: '%',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(weeks.length, (i) {
              final isCurrent = i == currentWeekIndex;
              return Text(
                weeks[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                  color: isCurrent ? AppColors.accentGreen : AppColors.textMuted,
                ),
              );
            }),
          ),
        ],
      );
    }

    List<String> labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    int currentWeekdayIndex = (DateTime.now().weekday % 7);
    List<double> values = [65, 75, 80, 70, 85, 90, 75];
    if (currentWeekdayIndex < values.length) {
      values[currentWeekdayIndex] = double.parse(todayScore.toStringAsFixed(1));
    }

    return Column(
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: DashboardTrendLinePainter(
              values: values,
              labels: labels,
              activeIndex: currentWeekdayIndex,
              startColor: AppColors.primary,
              endColor: AppColors.secondaryGlow,
              unit: '%',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(labels.length, (i) {
            final isToday = i == currentWeekdayIndex;
            return Text(
              labels[i],
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                color: isToday ? AppColors.secondary : AppColors.textMuted,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------- CUSTOM PAINTER FOR WALKING & JOGGING DISTANCE LINE GRAPH (CYBER VFX) ----------------
class WalkingJoggingDistanceLinePainter extends CustomPainter {
  final List<double> distances;
  final List<String> days;
  final int currentDayIndex;

  WalkingJoggingDistanceLinePainter({
    required this.distances,
    required this.days,
    required this.currentDayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty) return;

    double maxVal = distances.reduce(math.max);
    if (maxVal < 8.0) maxVal = 8.0;
    maxVal += 1.5;

    final double stepX = distances.length > 1 ? size.width / (distances.length - 1) : size.width;

    // 1. Cyber VFX Matrix Grid Dots
    final dotGridPaint = Paint()..color = Colors.white.withValues(alpha: 0.09);
    for (double gx = 12; gx < size.width; gx += 26) {
      for (double gy = 8; gy < size.height; gy += 20) {
        canvas.drawCircle(Offset(gx, gy), 0.75, dotGridPaint);
      }
    }

    // 2. Horizontal Cyber Guide Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final y = size.height * (g / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Target 5.0 KM Glowing Laser Reference Line
    final targetY = size.height - (5.0 / maxVal) * size.height;
    final targetGlowPaint = Paint()
      ..color = AppColors.accentGreen.withValues(alpha: 0.25)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetGlowPaint);

    final targetPaint = Paint()
      ..color = AppColors.accentGreen.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetPaint);

    // Compute points
    List<Offset> points = [];
    for (int i = 0; i < distances.length; i++) {
      final x = distances.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - (distances[i] / maxVal) * size.height;
      points.add(Offset(x, y.clamp(14, size.height - 14)));
    }

    // Build smooth Bezier path
    final linePath = Path();
    final fillPath = Path();

    if (points.length == 1) {
      linePath.moveTo(0, points[0].dy);
      linePath.lineTo(size.width, points[0].dy);
      fillPath.moveTo(0, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
    } else {
      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
    }

    // 4. VFX Gradient Aura Under Curve
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.accentBlue.withValues(alpha: 0.4),
        AppColors.accentGreen.withValues(alpha: 0.12),
        Colors.transparent,
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final lineShader = const LinearGradient(
      colors: [AppColors.accentBlue, AppColors.accentGreen],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 5. VFX Glowing Neon Stroke Aura
    final glowAura = Paint()
      ..shader = lineShader
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, glowAura);

    // 6. Crisp Core Neon Line Stroke
    final linePaint = Paint()
      ..shader = lineShader
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 7. Active Day Radar Laser Beam
    if (currentDayIndex >= 0 && currentDayIndex < points.length) {
      final activeNode = points[currentDayIndex];
      final beaconPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accentGreen.withValues(alpha: 0.7), Colors.transparent],
        ).createShader(Rect.fromLTWH(activeNode.dx - 1, 0, 2, size.height))
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(activeNode.dx, 0), Offset(activeNode.dx, size.height), beaconPaint);
    }

    // 8. Nodes with Multi-Ring Cyber Halos
    for (int i = 0; i < points.length; i++) {
      final isCurrent = i == currentDayIndex;
      final nodeCenter = points[i];

      if (isCurrent) {
        canvas.drawCircle(nodeCenter, 14, Paint()..color = AppColors.accentGreen.withValues(alpha: 0.15)..style = PaintingStyle.fill);
        canvas.drawCircle(nodeCenter, 8, Paint()..color = AppColors.accentGreen.withValues(alpha: 0.4)..style = PaintingStyle.fill);
      }

      final innerPaint = Paint()
        ..color = isCurrent ? AppColors.accentGreen : AppColors.accentBlue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodeCenter, isCurrent ? 5 : 3.5, innerPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(nodeCenter, isCurrent ? 5 : 3.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- CUSTOM PAINTER FOR DASHBOARD GLOWING LINE GRAPH (CYBER VFX) ----------------
class DashboardTrendLinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final int activeIndex;
  final Color startColor;
  final Color endColor;
  final String unit;

  DashboardTrendLinePainter({
    required this.values,
    required this.labels,
    this.activeIndex = -1,
    this.startColor = AppColors.primary,
    this.endColor = AppColors.secondary,
    this.unit = '%',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double minV = values.reduce(math.min);
    double maxV = values.reduce(math.max);
    if (maxV == minV) maxV += 10.0;
    minV = math.max(0.0, minV - (maxV - minV) * 0.1);
    maxV = maxV + (maxV - minV) * 0.15;

    final double stepX = values.length > 1 ? size.width / (values.length - 1) : size.width;

    // 1. Cyber VFX Matrix Grid Dots
    final dotGridPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (double gx = 12; gx < size.width; gx += 26) {
      for (double gy = 8; gy < size.height; gy += 20) {
        canvas.drawCircle(Offset(gx, gy), 0.75, dotGridPaint);
      }
    }

    // 2. Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final y = size.height * (g / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Points
    List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final x = values.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - ((values[i] - minV) / (maxV - minV)) * size.height;
      points.add(Offset(x, y.clamp(12, size.height - 12)));
    }

    // Path
    final linePath = Path();
    final fillPath = Path();

    if (points.length == 1) {
      linePath.moveTo(0, points[0].dy);
      linePath.lineTo(size.width, points[0].dy);
      fillPath.moveTo(0, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
    } else {
      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
    }

    // 3. Gradient fill
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        endColor.withValues(alpha: 0.35),
        startColor.withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final lineShader = LinearGradient(colors: [startColor, endColor]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 4. Outer Neon Aura Layer (VFX)
    final glowAura = Paint()
      ..shader = lineShader
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, glowAura);

    // 5. Core Crisp Line stroke
    final linePaint = Paint()
      ..shader = lineShader
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 6. Active Node Radar Laser Beam
    if (activeIndex >= 0 && activeIndex < points.length) {
      final activeNode = points[activeIndex];
      final beaconPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [endColor.withValues(alpha: 0.7), Colors.transparent],
        ).createShader(Rect.fromLTWH(activeNode.dx - 1, 0, 2, size.height))
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(activeNode.dx, 0), Offset(activeNode.dx, size.height), beaconPaint);
    }

    // 7. Nodes with glowing halos
    for (int i = 0; i < points.length; i++) {
      final isCurrent = i == activeIndex;
      final node = points[i];

      if (isCurrent) {
        canvas.drawCircle(node, 12, Paint()..color = endColor.withValues(alpha: 0.15)..style = PaintingStyle.fill);
        canvas.drawCircle(node, 8, Paint()..color = endColor.withValues(alpha: 0.4)..style = PaintingStyle.fill);
      }

      final circlePaint = Paint()
        ..color = isCurrent ? endColor : startColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node, isCurrent ? 4.8 : 3.2, circlePaint);

      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(node, isCurrent ? 4.8 : 3.2, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- CUSTOM PAINTER FOR MONTHLY WEIGHT LINE GRAPH (CYBER VFX) ----------------
class MonthlyWeightLinePainter extends CustomPainter {
  final List<double> weights;
  final double targetWeight;

  MonthlyWeightLinePainter({required this.weights, required this.targetWeight});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    double minW = weights.reduce(math.min);
    double maxW = weights.reduce(math.max);
    if (targetWeight > 0) {
      minW = math.min(minW, targetWeight);
      maxW = math.max(maxW, targetWeight);
    }
    minW = math.max(0, minW - 5);
    maxW = maxW + 5;
    if (maxW == minW) maxW += 10;

    final double stepX = weights.length > 1 ? size.width / (weights.length - 1) : size.width;

    // 1. Cyber Matrix Dot Grid
    final dotGridPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (double gx = 12; gx < size.width; gx += 26) {
      for (double gy = 8; gy < size.height; gy += 20) {
        canvas.drawCircle(Offset(gx, gy), 0.75, dotGridPaint);
      }
    }

    // 2. Horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final y = size.height * (g / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Compute points
    List<Offset> points = [];
    for (int i = 0; i < weights.length; i++) {
      final x = weights.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - ((weights[i] - minW) / (maxW - minW)) * size.height;
      points.add(Offset(x, y.clamp(10, size.height - 10)));
    }

    // Build smooth Bezier path
    final linePath = Path();
    final fillPath = Path();

    if (points.length == 1) {
      linePath.moveTo(0, points[0].dy);
      linePath.lineTo(size.width, points[0].dy);
      fillPath.moveTo(0, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
    } else {
      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
    }

    // 3. Glowing gradient fill under curve
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.secondary.withValues(alpha: 0.38),
        AppColors.primary.withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final lineShader = const LinearGradient(
      colors: [AppColors.primaryGlow, AppColors.secondary, AppColors.secondaryGlow],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 4. Outer Neon Aura Layer
    final glowAura = Paint()
      ..shader = lineShader
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, glowAura);

    // 5. Crisp glowing line stroke
    final linePaint = Paint()
      ..shader = lineShader
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 6. Draw target glowing laser line if set
    if (targetWeight > 0) {
      final targetY = size.height - ((targetWeight - minW) / (maxW - minW)) * size.height;
      final targetGlow = Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.25)
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetGlow);

      final targetPaint = Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      double dashWidth = 5, dashSpace = 4, startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, targetY), Offset(startX + dashWidth, targetY), targetPaint);
        startX += dashWidth + dashSpace;
      }
    }

    // 7. Draw point nodes with glowing halos and radar beacon on latest
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isLast = i == points.length - 1;

      if (isLast) {
        // Vertical Laser Beacon
        final beaconPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondaryGlow.withValues(alpha: 0.7), Colors.transparent],
          ).createShader(Rect.fromLTWH(p.dx - 1, 0, 2, size.height))
          ..strokeWidth = 1.6;
        canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), beaconPaint);

        canvas.drawCircle(p, 13, Paint()..color = AppColors.secondary.withValues(alpha: 0.2)..style = PaintingStyle.fill);
        canvas.drawCircle(p, 8, Paint()..color = AppColors.secondary.withValues(alpha: 0.45)..style = PaintingStyle.fill);
      }

      // Inner circle
      canvas.drawCircle(
        p,
        isLast ? 5.0 : 3.5,
        Paint()..color = isLast ? AppColors.secondaryGlow : Colors.white,
      );

      canvas.drawCircle(
        p,
        isLast ? 5.0 : 3.5,
        Paint()..color = Colors.white..strokeWidth = 1.4..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- TAB 8: WEEKLY & MONTHLY REPORTS HUB ----------------
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> with SingleTickerProviderStateMixin {
  late TabController _reportTabController;

  @override
  void initState() {
    super.initState();
    _reportTabController = TabController(length: 2, vsync: this);
  }

  void _triggerHierarchicalExport() async {
    final path = await HierarchicalStorageManager.exportFullTreeBackup();
    if (mounted) {
      DisciplineFeedback.showCelebration(
        context: context,
        title: '📁 Data Tree Exported!',
        message: 'Hierarchical backup successfully stored at:\n$path',
        disciplineQuote: 'Order in your data reflects order in your mind. Mastery is built on organization.',
        color: AppColors.secondary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isSunday = now.weekday == DateTime.sunday;
    final bool isEligibleForMonthlyReport = now.day == 1; // Unlocks strictly on 1st of every month
    final formattedDateTime = '${now.day}/${now.month}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final daysUntilSunday = isSunday ? 0 : (7 - now.weekday);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _reportTabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            tabs: const [
              Tab(text: 'Weekly Report (Sundays)'),
              Tab(text: 'Monthly Report (1st)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _reportTabController,
        children: [
          // 1. WEEKLY REPORT GENERATED EVERY SUNDAY
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF192A3E), Color(0xFF131D33), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.date_range_rounded, color: AppColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('WEEKLY DISCIPLINE AUDIT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('Auto-Generates Every Sunday • Audit: $formattedDateTime', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // HIERARCHICAL STORAGE BACKUP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _triggerHierarchicalExport,
                    icon: const Icon(Icons.folder_zip_rounded, color: AppColors.secondary, size: 16),
                    label: const Flexible(
                      child: Text(
                        'Save & Export Data Tree (Month > Week > Day)',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (!isSunday)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: AppColors.accentAmber, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Weekly Report Locks Until Sunday',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentAmber, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Weekly performance audits and 7-day consistency scores generate automatically every Sunday. Next weekly unlock in $daysUntilSunday day${daysUntilSunday == 1 ? "" : "s"}.',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.1), blurRadius: 16),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sunday Weekly Audit Unlocked 🎉',
                                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGreen, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAuditRow('7-Day Discipline Score', 'Grade A+ (96%)', AppColors.accentGreen),
                        _buildAuditRow('Average Wake-up Consistency', '4:55 AM (Target Met)', AppColors.accentAmber),
                        _buildAuditRow('Weekly Focus & Study Time', 'Accurately Tracked', AppColors.primary),
                        _buildAuditRow('Clean Nutrition & Fasting', 'Optimal Whole Foods', AppColors.secondary),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 2. MONTHLY REPORT GENERATED ON 1ST OF EVERY MONTH
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1738), Color(0xFF111E2E), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assessment_rounded, color: AppColors.primaryGlow, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MONTHLY DISCIPLINE REPORT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryGlow, letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('Auto-Generates on 1st • Audit: $formattedDateTime', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!isEligibleForMonthlyReport)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: AppColors.accentAmber, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Report Locked Until 1st of Month',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentAmber, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Monthly performance audits, discipline scorecards, and cumulative mastery reports automatically unlock on the 1st of every month.',
                          style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.1), blurRadius: 16),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Official Monthly Report Unlocked',
                                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGreen, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAuditRow('Total Discipline Compliance', 'Optimal (98%)', AppColors.accentGreen),
                        _buildAuditRow('Average Wake-up Discipline', '5:00 AM (Target Met)', AppColors.accentAmber),
                        _buildAuditRow('Study & Mastery Hours', 'Exact Logged Calculation', AppColors.primary),
                        _buildAuditRow('Physique & Workout Target', 'Consistent Progress', AppColors.secondary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.white70), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ---------------- TAB 2: ROUTINE & RECHARGE SECTION ----------------
class RoutineActivityFeedback {
  final String activityName;
  final IconData icon;
  final String loggedValue;
  final String targetValue;
  final bool isMet;
  final String greetingOrEncouragementTitle;
  final String message;
  final String motivationQuote;
  final Color themeColor;

  RoutineActivityFeedback({
    required this.activityName,
    required this.icon,
    required this.loggedValue,
    required this.targetValue,
    required this.isMet,
    required this.greetingOrEncouragementTitle,
    required this.message,
    required this.motivationQuote,
    required this.themeColor,
  });
}

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  TimeOfDay? _wakeTime;
  TimeOfDay? _rechargeStart;
  TimeOfDay? _awakeningEnd;

  final _stepsController = TextEditingController();
  final _screenTimeController = TextEditingController();
  final _activeMinController = TextEditingController();

  List<RoutineActivityFeedback> _activityFeedbacks = [];
  bool _targetMet = false;

  void _checkSleepRechargeFeedback() {
    if (_rechargeStart != null && _awakeningEnd != null) {
      double start = _rechargeStart!.hour + (_rechargeStart!.minute / 60.0);
      double end = _awakeningEnd!.hour + (_awakeningEnd!.minute / 60.0);
      if (end < start) end += 24.0;
      double hours = end - start;
      final isMet = hours >= 7.0;

      if (mounted) {
        if (isMet) {
          DisciplineFeedback.showCelebration(
            context: context,
            title: '🔋 100% RECHARGE BATTERY ACHIEVED!',
            message: 'Full Recharge Restored (${hours.toStringAsFixed(1)} hrs of deep rest)! Your cognitive bandwidth, muscular repair, and willpower are fully primed.',
            disciplineQuote: 'Deep rest is not laziness—it is the biological fuel of world-class performance.',
            color: AppColors.primaryGlow,
          );
        } else {
          DisciplineFeedback.showEncouragement(
            context: context,
            title: '⚡ SLEEP DEFICIT RECOVERY PLAN',
            message: 'Logged ${hours.toStringAsFixed(1)} hrs of rest (Target is ≥ 7.0 hrs). Operating on a lighter battery today. Stay hydrated, avoid heavy carbs, and lock in an early 10 PM sleep tonight!',
            confidenceQuote: 'Listen to your body today. True discipline knows when to push and when to protect recovery.',
            color: AppColors.primaryGlow,
          );
        }
      }
    }
  }

  void _calculateDailyFeedback() async {
    final List<RoutineActivityFeedback> items = [];

    // 1. MORNING AWAKENING (4:00 - 5:30 AM)
    if (_wakeTime != null) {
      final wakeMin = _wakeTime!.hour * 60 + _wakeTime!.minute;
      final bool wakeMet = wakeMin >= 240 && wakeMin <= 330;
      items.add(RoutineActivityFeedback(
        activityName: 'Morning Awakening',
        icon: Icons.wb_sunny_rounded,
        loggedValue: _wakeTime!.format(context),
        targetValue: '4:00 AM – 5:30 AM',
        isMet: wakeMet,
        greetingOrEncouragementTitle: wakeMet ? '🌅 EARLY AWAKENING CHAMPION' : '⏰ MORNING AWAKENING RESET',
        message: wakeMet
            ? 'Discipline Champion! You conquered the dawn and woke up at ${_wakeTime!.format(context)}. Your day begins with victory!'
            : 'Wake-up logged at ${_wakeTime!.format(context)}. A delayed morning does not stop a relentless mind—win the rest of your day and set a 10:00 PM sleep target tonight!',
        motivationQuote: wakeMet
            ? 'Master your morning, master your mind, master your destiny.'
            : 'It is not how the morning started, but how furiously you conquer the remaining hours that defines your character.',
        themeColor: AppColors.accentAmber,
      ));
    } else {
      items.add(RoutineActivityFeedback(
        activityName: 'Morning Awakening',
        icon: Icons.wb_sunny_rounded,
        loggedValue: 'Not Logged',
        targetValue: '4:00 AM – 5:30 AM',
        isMet: false,
        greetingOrEncouragementTitle: '⏰ MORNING WAKE-UP PENDING',
        message: 'Awakening time has not been recorded yet. Set your alarm for 5:00 AM tomorrow!',
        motivationQuote: 'The early morning belongs to those who chase greatness before the world wakes up.',
        themeColor: AppColors.accentAmber,
      ));
    }

    // 2. SLEEP RECHARGE (>= 7.0 Hours)
    if (_rechargeStart != null && _awakeningEnd != null) {
      double start = _rechargeStart!.hour + (_rechargeStart!.minute / 60.0);
      double end = _awakeningEnd!.hour + (_awakeningEnd!.minute / 60.0);
      if (end < start) end += 24.0;
      double hours = end - start;
      final bool sleepMet = hours >= 7.0;
      items.add(RoutineActivityFeedback(
        activityName: 'Sleep & Deep Rest Battery',
        icon: Icons.nightlight_round,
        loggedValue: '${hours.toStringAsFixed(1)} hrs (${_rechargeStart!.format(context)} → ${_awakeningEnd!.format(context)})',
        targetValue: '≥ 7.0 Hours Rest',
        isMet: sleepMet,
        greetingOrEncouragementTitle: sleepMet ? '🔋 100% RECHARGE BATTERY' : '⚡ SLEEP DEFICIT RECOVERY PLAN',
        message: sleepMet
            ? 'Full 7+ Hour Battery Restored! Your cognitive bandwidth, muscular repair, and neural focus are primed for high performance.'
            : 'Logged ${hours.toStringAsFixed(1)} hrs of sleep (Target is ≥ 7.0 hrs). Operating on a lighter battery today. Stay hydrated and get to bed early tonight!',
        motivationQuote: sleepMet
            ? 'Deep rest is not laziness—it is the biological fuel of world-class discipline.'
            : 'Listen to your body today. True discipline knows when to push and when to protect recovery.',
        themeColor: AppColors.primaryGlow,
      ));
    } else {
      items.add(RoutineActivityFeedback(
        activityName: 'Sleep & Deep Rest Battery',
        icon: Icons.nightlight_round,
        loggedValue: 'Not Logged',
        targetValue: '≥ 7.0 Hours Rest',
        isMet: false,
        greetingOrEncouragementTitle: '🔋 SLEEP METRIC PENDING',
        message: 'Log both bedtime and rise time to compute your daily neural recharge battery.',
        motivationQuote: 'Sleep is the foundation of high cognitive performance and physical resilience.',
        themeColor: AppColors.primaryGlow,
      ));
    }

    // 3. DAILY STEPS (10,000 Steps)
    final int steps = int.tryParse(_stepsController.text.trim()) ?? 0;
    final bool stepsMet = steps >= 10000;
    if (_stepsController.text.trim().isNotEmpty) {
      items.add(RoutineActivityFeedback(
        activityName: 'Daily Steps Activity',
        icon: Icons.directions_walk_rounded,
        loggedValue: '$steps steps',
        targetValue: '10,000 Steps',
        isMet: stepsMet,
        greetingOrEncouragementTitle: stepsMet ? '👟 10,000+ STEPS DOMINATED!' : '🚶 DAILY STEPS IN PROGRESS',
        message: stepsMet
            ? 'Relentless Physical Momentum! You logged $steps steps, defeating sedentary inertia and keeping your metabolic engine roaring.'
            : 'Logged $steps steps (${10000 - steps > 0 ? '${10000 - steps} steps remaining' : 'Keep pushing'}). Take a brisk 15-minute walk after dinner to hit 10k before bed!',
        motivationQuote: stepsMet
            ? 'Movement is medicine. 10,000 steps a day builds relentless vitality.'
            : 'Small continuous steps turn into monumental distances. Lace up and conquer the pavement!',
        themeColor: AppColors.secondary,
      ));
    } else {
      items.add(RoutineActivityFeedback(
        activityName: 'Daily Steps Activity',
        icon: Icons.directions_walk_rounded,
        loggedValue: 'Not Logged',
        targetValue: '10,000 Steps',
        isMet: false,
        greetingOrEncouragementTitle: '🚶 STEPS TARGET PENDING',
        message: 'Track your daily steps. Aim for 10,000 steps of active daily movement.',
        motivationQuote: 'Every step under gravity counts toward vitality. Stay on your feet and stay active!',
        themeColor: AppColors.secondary,
      ));
    }

    // 4. SCREEN TIME CONTROL (< 4.0 Hours)
    final double? screenHrs = double.tryParse(_screenTimeController.text.trim());
    if (screenHrs != null) {
      final bool screenMet = screenHrs < 4.0;
      items.add(RoutineActivityFeedback(
        activityName: 'Screen Time Control',
        icon: Icons.smartphone_rounded,
        loggedValue: '${screenHrs.toStringAsFixed(1)} hrs',
        targetValue: '< 4.0 Hours',
        isMet: screenMet,
        greetingOrEncouragementTitle: screenMet ? '📱 DIGITAL DISCIPLINE CHAMPION!' : '📵 DIGITAL DETOX RESET',
        message: screenMet
            ? 'Protected Focus (${screenHrs.toStringAsFixed(1)} hrs)! You shielded your brain from endless digital dopamine traps and retained mental clarity.'
            : 'High Screen Time Logged (${screenHrs.toStringAsFixed(1)} hrs). Disconnect from social algorithms, turn off notifications, and practice a 1-hour screen-free sunset tonight!',
        motivationQuote: screenMet
            ? 'When you control your screen, you control your attention. When you control your attention, you command your life.'
            : 'Cut the digital noise. Reclaim your focus for the things that truly shape your future.',
        themeColor: screenMet ? AppColors.accentGreen : AppColors.accentRose,
      ));
    } else {
      items.add(RoutineActivityFeedback(
        activityName: 'Screen Time Control',
        icon: Icons.smartphone_rounded,
        loggedValue: 'Not Logged',
        targetValue: '< 4.0 Hours',
        isMet: false,
        greetingOrEncouragementTitle: '📱 SCREEN TIME TARGET PENDING',
        message: 'Log your non-productive screen hours. Keep digital consumption strictly below 4 hours.',
        motivationQuote: 'Do not trade your real potential for cheap digital dopamine.',
        themeColor: AppColors.accentRose,
      ));
    }

    // 5. ACTIVE WORKOUT MINUTES (>= 90 Mins)
    final int activeMins = int.tryParse(_activeMinController.text.trim()) ?? 0;
    final bool activeMet = activeMins >= 90;
    if (_activeMinController.text.trim().isNotEmpty) {
      items.add(RoutineActivityFeedback(
        activityName: 'Active Workout Minutes',
        icon: Icons.fitness_center_rounded,
        loggedValue: '$activeMins mins',
        targetValue: '≥ 90 Active Minutes',
        isMet: activeMet,
        greetingOrEncouragementTitle: activeMet ? '🔥 90+ MINS BEAST MODE ACHIEVED!' : '⚡ ACTIVE MINUTES IN PROGRESS',
        message: activeMet
            ? 'High Energy Standard ($activeMins mins)! You pushed your physical limits, burned resistance, and forged unbreakable grit in the arena.'
            : 'Logged $activeMins active mins (${90 - activeMins > 0 ? '${90 - activeMins} mins remaining' : 'Keep moving'}). Add a quick 20-minute stretching or brisk workout session to reach 90 minutes!',
        motivationQuote: activeMet
            ? 'The pain of discipline weighs ounces; the pain of regret weighs tons. Be proud of your sweat today.'
            : 'Consistency beats perfection every single time. Show up, move your body, and never break the chain!',
        themeColor: activeMet ? AppColors.accentGreen : AppColors.accentAmber,
      ));
    } else {
      items.add(RoutineActivityFeedback(
        activityName: 'Active Workout Minutes',
        icon: Icons.fitness_center_rounded,
        loggedValue: 'Not Logged',
        targetValue: '≥ 90 Active Minutes',
        isMet: false,
        greetingOrEncouragementTitle: '🔥 ACTIVE MINUTES PENDING',
        message: 'Log your active physical minutes. Target is minimum 90 minutes of dedicated physical movement.',
        motivationQuote: 'Start where you are. Even 15 minutes of intensity transforms your body.',
        themeColor: AppColors.accentAmber,
      ));
    }

    final int conqueredCount = items.where((i) => i.isMet).length;
    final bool overallTargetMet = conqueredCount >= 3;

    setState(() {
      _activityFeedbacks = items;
      _targetMet = overallTargetMet;
    });

    // AUTO STORE TO HIERARCHICAL STORAGE
    await HierarchicalStorageManager.saveDailyRecord(
      date: DateTime.now(),
      data: {
        'wakeTime': _wakeTime?.format(context),
        'rechargeStart': _rechargeStart?.format(context),
        'awakeningEnd': _awakeningEnd?.format(context),
        'steps': _stepsController.text,
        'screenTime': _screenTimeController.text,
        'activeMinutes': _activeMinController.text,
        'targetMet': _targetMet,
        'conqueredCount': conqueredCount,
        'feedback': items.map((i) => '${i.activityName}: ${i.greetingOrEncouragementTitle}').toList(),
      },
    );

    if (mounted) {
      _showRoutineBreakdownDialog(items, conqueredCount);
    }
  }

  void _showRoutineBreakdownDialog(List<RoutineActivityFeedback> items, int conqueredCount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: conqueredCount >= 3 ? AppColors.accentGreen : AppColors.secondary, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (conqueredCount >= 3 ? AppColors.accentGreen : AppColors.secondary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                conqueredCount >= 3 ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                color: conqueredCount >= 3 ? AppColors.accentGreen : AppColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conqueredCount >= 3 ? '🌅 ROUTINE MASTERY CONQUERED!' : '🛡️ ROUTINE SCORE & COACHING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: conqueredCount >= 3 ? AppColors.accentGreen : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$conqueredCount of 5 Daily Targets Conquered',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) => _buildActivityFeedbackCard(item)).toList(),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: conqueredCount >= 3 ? AppColors.accentGreen : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Acknowledge & Execute Daily Plan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedbackCard(RoutineActivityFeedback item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isMet ? AppColors.accentGreen.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isMet ? AppColors.accentGreen.withValues(alpha: 0.6) : item.themeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: item.themeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.activityName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isMet ? AppColors.accentGreen.withValues(alpha: 0.2) : AppColors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item.isMet ? AppColors.accentGreen : AppColors.accentAmber, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.isMet ? Icons.check_circle_rounded : Icons.bolt_rounded, size: 11, color: item.isMet ? AppColors.accentGreen : AppColors.accentAmber),
                    const SizedBox(width: 4),
                    Text(
                      item.isMet ? 'CONQUERED' : 'ENCOURAGE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: item.isMet ? AppColors.accentGreen : AppColors.accentAmber,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Logged: ${item.loggedValue} • Target: ${item.targetValue}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            item.message,
            style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.themeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, size: 14, color: item.themeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.motivationQuote,
                    style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: AppColors.accentAmber, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'MORNING AWAKENING & SLEEP TARGETS',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12, color: AppColors.accentAmber),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1F11), Color(0xFF161F33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.12), blurRadius: 14),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DISCIPLINE TARGET: 4:00 AM - 5:30 AM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        _wakeTime == null ? 'Not Logged' : _wakeTime!.format(context),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber, foregroundColor: Colors.black),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 5, minute: 0));
                    if (t != null) {
                      setState(() => _wakeTime = t);
                      final wakeMin = t.hour * 60 + t.minute;
                      final isMet = wakeMin >= 240 && wakeMin <= 330;
                      if (context.mounted) {
                        if (isMet) {
                          DisciplineFeedback.showCelebration(
                            context: context,
                            title: '🌅 MORNING MASTERY CONQUERED!',
                            message: 'Woke up at ${t.format(context)} (4:00–5:30 AM Target Met)! You seized the dawn and unlocked elite daily discipline.',
                            disciplineQuote: 'Master your morning, master your mind, master your destiny.',
                            color: AppColors.accentAmber,
                          );
                        } else {
                          DisciplineFeedback.showEncouragement(
                            context: context,
                            title: '⏰ MORNING AWAKENING LOGGED',
                            message: 'Wakeup logged at ${t.format(context)}. A delayed morning does not stop a relentless mind—win the rest of your day and set a 10:00 PM sleep target tonight!',
                            confidenceQuote: 'It is not how the morning started, but how furiously you conquer the remaining hours that defines your character.',
                            color: AppColors.accentAmber,
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.wb_sunny_rounded, size: 16),
                  label: const Text('Log Wakeup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                    if (t != null) {
                      setState(() => _rechargeStart = t);
                      _checkSleepRechargeFeedback();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.nightlight_round, size: 14, color: AppColors.primaryGlow),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _rechargeStart == null ? 'Recharge Start' : 'Bed: ${_rechargeStart!.format(context)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 5, minute: 0));
                    if (t != null) {
                      setState(() => _awakeningEnd = t);
                      _checkSleepRechargeFeedback();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_rounded, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _awakeningEnd == null ? 'Awake Time' : 'Rise: ${_awakeningEnd!.format(context)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ACTIVITY & DISCIPLINE TARGETS',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12, color: AppColors.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _stepsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Steps Target (10,000)', prefixIcon: Icon(Icons.directions_walk_rounded, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: _screenTimeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Screen Time Hours (<4h)', prefixIcon: Icon(Icons.smartphone_rounded, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: _activeMinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Active Minutes (>90m)', prefixIcon: Icon(Icons.fitness_center_rounded, size: 18))),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              onPressed: _calculateDailyFeedback,
              icon: const Icon(Icons.analytics_rounded, color: Colors.white),
              label: const Text('Analyze & Save Routine Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),

          if (_activityFeedbacks.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.assessment_rounded, color: AppColors.primaryGlow, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ACTIVITY GREETINGS & COACHING',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12, color: AppColors.primaryGlow),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_targetMet ? AppColors.accentGreen : AppColors.secondary).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_activityFeedbacks.where((f) => f.isMet).length}/5 Conquered',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _targetMet ? AppColors.accentGreen : AppColors.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activityFeedbacks.map((item) => _buildActivityFeedbackCard(item)),
          ],
        ],
      ),
    );
  }
}

// ---------------- TAB 3: NUTRITION ----------------
class FoodAndSnacksScreen extends StatefulWidget {
  const FoodAndSnacksScreen({super.key});

  @override
  State<FoodAndSnacksScreen> createState() => _FoodAndSnacksScreenState();
}

class _FoodAndSnacksScreenState extends State<FoodAndSnacksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FoodItem> _foodItems = [];

  final List<String> _mealSlots = ['Breakfast', 'Morning Snack', 'Lunch', 'Evening Snack', 'Dinner', 'Pre-Workout', 'Post-Workout', 'Late Night'];
  final List<String> _typeCategories = ['Natural / Whole Food 🥬', 'Daily Meals 🍲', 'Fried / Junk 🍟', 'Others 🍽️'];
  final List<String> _unitOptions = ['Pcs (Pieces)', 'Cups', 'Bowls (Katori)', 'Spoons (tbsp)', 'Grams (g)'];

  double get _dailyCalorieTarget => HealthState.dynamicDailyCalorieTarget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFoodItems();
    AppSyncBus.syncTick.addListener(_fetchFoodItems);
  }

  @override
  void dispose() {
    AppSyncBus.syncTick.removeListener(_fetchFoodItems);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFoodItems() async {
    final rows = await DBHelper.instance.fetchFoodLogs();
    if (mounted) {
      setState(() {
        _foodItems = rows.map((r) => FoodItem.fromMap(r)).toList();
      });
    }
  }

  double get _totalDailyCalories => _foodItems.fold(0.0, (sum, item) => sum + item.calories);
  double get _totalDailyProtein => _foodItems.fold(0.0, (sum, item) => sum + item.protein);
  double get _totalDailyCarbs => _foodItems.fold(0.0, (sum, item) => sum + item.carbs);
  double get _totalDailyFat => _foodItems.fold(0.0, (sum, item) => sum + item.fat);

  void _showAddDialog(String mealOrSnack, {InbuiltFood? preset}) {
    final nameCtrl = TextEditingController(text: preset?.name ?? '');
    final qtyCtrl = TextEditingController(text: (preset?.defaultQuantity ?? 1.0).toString());
    final calCtrl = TextEditingController(text: (preset?.calories ?? 120.0).toStringAsFixed(0));
    final proteinCtrl = TextEditingController(text: (preset?.protein ?? 5.0).toStringAsFixed(1));
    final carbsCtrl = TextEditingController(text: (preset?.carbs ?? 20.0).toStringAsFixed(1));
    final fatCtrl = TextEditingController(text: (preset?.fat ?? 3.0).toStringAsFixed(1));

    String selectedSlot = preset?.defaultMealSlot ?? (mealOrSnack == 'Snack' ? 'Evening Snack' : 'Breakfast');
    String selectedType = preset?.type ?? 'Natural / Whole Food 🥬';
    String selectedUnit = preset?.defaultUnit ?? 'Pcs (Pieces)';
    TimeOfDay selectedTime = TimeOfDay.now();

    void applyPreset(InbuiltFood p, StateSetter setModalState) {
      nameCtrl.text = p.name;
      qtyCtrl.text = (p.defaultQuantity == p.defaultQuantity.toInt() ? p.defaultQuantity.toInt() : p.defaultQuantity).toString();
      selectedUnit = p.defaultUnit;
      selectedSlot = p.defaultMealSlot;
      selectedType = p.type;
      final result = CalorieEstimationEngine.calculate(p.name, p.defaultQuantity, p.defaultUnit);
      setModalState(() {
        calCtrl.text = (result['calories'] ?? p.calories).toStringAsFixed(0);
        proteinCtrl.text = (result['protein'] ?? p.protein).toStringAsFixed(1);
        carbsCtrl.text = (result['carbs'] ?? p.carbs).toStringAsFixed(1);
        fatCtrl.text = (result['fat'] ?? p.fat).toStringAsFixed(1);
      });
    }

    void updateEstimatedNutrients(StateSetter setModalState) {
      final name = nameCtrl.text.trim();
      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
      final result = CalorieEstimationEngine.calculate(name, qty, selectedUnit);
      setModalState(() {
        calCtrl.text = result['calories']!.toStringAsFixed(0);
        proteinCtrl.text = result['protein']!.toStringAsFixed(1);
        carbsCtrl.text = result['carbs']!.toStringAsFixed(1);
        fatCtrl.text = result['fat']!.toStringAsFixed(1);
      });
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.borderLight)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(mealOrSnack == 'Snack' ? Icons.cookie_outlined : Icons.restaurant_rounded, color: AppColors.accentGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  preset != null ? 'Log ${preset.name}' : 'Log $mealOrSnack & Calories',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick pick presets strip inside dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text('⚡ QUICK PICK INBUILT FOOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _openInbuiltFoodLibraryModal();
                      },
                      child: const Text('All 30+ 📚', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: InbuiltFoodLibrary.popularPresets.take(7).map((p) {
                      final isSelected = nameCtrl.text.trim().toLowerCase() == p.name.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: isSelected ? AppColors.secondary.withValues(alpha: 0.25) : AppColors.surface,
                          side: BorderSide(color: isSelected ? AppColors.secondary : AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          label: Text('${p.emoji} ${p.name.split(" ").first}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isSelected ? AppColors.secondary : Colors.white70)),
                          onPressed: () => applyPreset(p, setModalState),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Food Name (e.g. Rice, Chapati, Poori, Curd Rice)',
                    prefixIcon: Icon(Icons.fastfood_rounded, size: 18),
                  ),
                  onChanged: (_) => updateEstimatedNutrients(setModalState),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity (e.g. 2, 1.5)'),
                        onChanged: (_) => updateEstimatedNutrients(setModalState),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _unitOptions.contains(selectedUnit) ? selectedUnit : _unitOptions.first,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        decoration: const InputDecoration(labelText: 'Unit / Measure'),
                        items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedUnit = val);
                            updateEstimatedNutrients(setModalState);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentAmber),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text('Auto-Calculated Nutrition & Macros', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentAmber), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: calCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Calories (kcal)', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentAmber),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: proteinCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Protein (g)', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: carbsCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Carbs (g)', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: fatCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Fat (g)', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGlow),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSlot,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(labelText: 'Meal Timing Slot'),
                  items: _mealSlots.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedSlot = val ?? 'Breakfast'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(labelText: 'Food Quality Category'),
                  items: _typeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedType = val ?? 'Natural / Whole Food 🥬'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.borderLight)),
                  leading: const Icon(Icons.schedule_rounded, color: AppColors.secondary),
                  title: const Text('Time Consumed', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  subtitle: Text(selectedTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) setModalState(() => selectedTime = picked);
                    },
                    child: const Text('Change', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                final cals = double.tryParse(calCtrl.text.trim()) ?? 100.0;
                final prot = double.tryParse(proteinCtrl.text.trim()) ?? 4.0;
                final carbs = double.tryParse(carbsCtrl.text.trim()) ?? 15.0;
                final fat = double.tryParse(fatCtrl.text.trim()) ?? 2.0;

                if (name.isNotEmpty) {
                  final newFood = FoodItem(
                    name: name,
                    mealSlot: selectedSlot,
                    type: selectedType,
                    category: mealOrSnack,
                    quantity: qty,
                    unit: selectedUnit,
                    calories: cals,
                    protein: prot,
                    carbs: carbs,
                    fat: fat,
                    time: selectedTime,
                    loggedAt: DateTime.now(),
                  );

                  await DBHelper.instance.insertFoodLog(newFood.toMap());
                  await HierarchicalStorageManager.saveDailyRecord(
                    date: DateTime.now(),
                    data: {
                      'type': 'FoodLog',
                      'name': name,
                      'mealSlot': selectedSlot,
                      'foodType': selectedType,
                      'category': mealOrSnack,
                      'calories': cals,
                      'protein': prot,
                      'carbs': carbs,
                      'fat': fat,
                      'quantity': qty,
                      'unit': selectedUnit,
                    },
                  );

                  await _fetchFoodItems();

                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    if (selectedType.contains('Natural') || selectedType.contains('Daily')) {
                      DisciplineFeedback.showCelebration(
                        context: context,
                        title: '🥬 Clean Fuel Logged!',
                        message: 'Logged "$name" ($qty $selectedUnit • ${cals.toInt()} kcal). High-quality whole fuel empowering your physical engine!',
                        disciplineQuote: 'You do not rise to the level of your goals, you fall to the level of your systems.',
                      );
                    } else {
                      DisciplineFeedback.showEncouragement(
                        context: context,
                        title: '🛡️ Nutrition Awareness',
                        message: 'Logged "$name" ($qty $selectedUnit • ${cals.toInt()} kcal). Balance this with high-protein whole foods in your next meal!',
                        confidenceQuote: 'One meal does not define your discipline. Your consistency over time does.',
                      );
                    }
                  }
                }
              },
              child: const Text('Save Food & Calories'),
            ),
          ],
        ),
      ),
    );
  }

  void _openInbuiltFoodLibraryModal() {
    String selectedCategory = 'All';
    String searchQuery = '';
    final categories = ['All', 'Staples & Rice', 'Breads & Breakfast', 'Fruits', 'Curries & Proteins', 'Dairy & Drinks'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filteredList = InbuiltFoodLibrary.allFoods.where((f) {
            final matchesCat = selectedCategory == 'All' || f.category == selectedCategory;
            final matchesSearch = searchQuery.isEmpty || f.name.toLowerCase().contains(searchQuery.toLowerCase()) || f.category.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesCat && matchesSearch;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: AppColors.secondary, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'INBUILT FOOD LIBRARY',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('${InbuiltFoodLibrary.allFoods.length} Foods', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search Rice, Chapati, Poori, Fruits, Dal...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (val) => setSheetState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withValues(alpha: 0.35),
                            checkmarkColor: Colors.white,
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
                            label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
                            onSelected: (_) => setSheetState(() => selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text('No matching foods found. Try another search!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: filteredList.length,
                            itemBuilder: (context, idx) {
                              final f = filteredList[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                                      alignment: Alignment.center,
                                      child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(f.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text('${f.defaultQuantity == f.defaultQuantity.toInt() ? f.defaultQuantity.toInt() : f.defaultQuantity} ${f.defaultUnit} • ${f.calories.toInt()} kcal', style: const TextStyle(fontSize: 11, color: AppColors.accentAmber, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 3),
                                          Text('P: ${f.protein}g • C: ${f.carbs}g • F: ${f.fat}g', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(modalCtx);
                                        _showAddDialog(f.category == 'Fruits' || f.defaultMealSlot.contains('Snack') ? 'Snack' : 'Meal', preset: f);
                                      },
                                      child: const Text('Log +', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteFoodItem(FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accentRose, width: 1.2)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 22),
            SizedBox(width: 8),
            Text('Delete Food Entry?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text('Remove "${item.name}" (${item.quantity} ${item.unit} • ${item.calories.toInt()} kcal) from your logs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () async {
              Navigator.pop(ctx);
              if (item.id != null) {
                await DBHelper.instance.deleteFoodLog(item.id!);
              }
              await _fetchFoodItems();
            },
            child: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCalorieBudgetDialog() {
    final weightCtrl = TextEditingController(text: HealthState.weightKg > 0 ? HealthState.weightKg.toStringAsFixed(1) : '');
    final heightCtrl = TextEditingController(text: HealthState.heightCm > 0 ? HealthState.heightCm.toStringAsFixed(0) : '');
    final targetCtrl = TextEditingController(text: HealthState.dynamicDailyCalorieTarget.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final w = double.tryParse(weightCtrl.text.trim()) ?? HealthState.weightKg;
          final h = double.tryParse(heightCtrl.text.trim()) ?? HealthState.heightCm;
          double calculated = 2200.0;
          if (w > 0 && h > 0) {
            final bmr = (10 * w) + (6.25 * h) - (5 * 25) + 5;
            calculated = (bmr * 1.35).clamp(1400.0, 3800.0);
          } else if (w > 0) {
            calculated = (w * 30.0).clamp(1500.0, 3500.0);
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.accentAmber, width: 1.2)),
            title: const Row(
              children: [
                Icon(Icons.calculate_rounded, color: AppColors.accentAmber, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calorie Budget Calculator',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Daily Calorie Budget is automatically computed using your Height & Weight (Mifflin-St Jeor TDEE formula):', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true),
                          onChanged: (_) {
                            setModalState(() {});
                            targetCtrl.text = calculated.toInt().toString();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Height (cm)', isDense: true),
                          onChanged: (_) {
                            setModalState(() {});
                            targetCtrl.text = calculated.toInt().toString();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily Target (kcal/day)',
                      prefixIcon: Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.accentAmber),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentAmber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Estimated BMR/TDEE: ${calculated.toInt()} kcal/day',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentAmber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
                onPressed: () {
                  final newWeight = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                  final newHeight = double.tryParse(heightCtrl.text.trim()) ?? 0.0;
                  final customTarget = double.tryParse(targetCtrl.text.trim()) ?? 2200.0;

                  setState(() {
                    if (newWeight > 0) HealthState.weightKg = newWeight;
                    if (newHeight > 0) HealthState.heightCm = newHeight;
                    HealthState.customDailyCalorieBudget = customTarget;
                  });

                  Navigator.pop(ctx);
                  DisciplineFeedback.showCelebration(
                    context: context,
                    title: '🔥 Calorie Target Calibrated!',
                    message: 'Daily Budget set to ${customTarget.toInt()} kcal based on Weight (${newWeight > 0 ? "$newWeight kg" : "N/A"}) and Height (${newHeight > 0 ? "$newHeight cm" : "N/A"}).',
                    disciplineQuote: 'Energy in versus energy out mastered with absolute mathematical precision.',
                    color: AppColors.accentAmber,
                    icon: Icons.local_fire_department_rounded,
                  );
                },
                child: const Text('Save Target', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearAllFoodLogs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accentRose, width: 1.2)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.accentRose, size: 22),
            SizedBox(width: 8),
            Text('Clear All Food Logs?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: const Text('Remove all logged food items? This will reset your food list to completely empty and will not automatically restore any dummy items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var item in _foodItems) {
                if (item.id != null) {
                  await DBHelper.instance.deleteFoodLog(item.id!);
                }
              }
              await _fetchFoodItems();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.contains('Natural')) return AppColors.accentGreen;
    if (type.contains('Daily')) return AppColors.secondary;
    if (type.contains('Fried')) return AppColors.accentRose;
    return AppColors.accentAmber;
  }

  @override
  Widget build(BuildContext context) {
    final mealsList = _foodItems.where((f) => f.category == 'Meal').toList();
    final snacksList = _foodItems.where((f) => f.category == 'Snack').toList();
    final double calProgress = (_totalDailyCalories / _dailyCalorieTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [Tab(text: 'Meals & Food'), Tab(text: 'Snacks & Bites')],
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. DAILY CALORIE & MACRO SUMMARY BAR
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2838), Color(0xFF131D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.08), blurRadius: 12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: AppColors.accentAmber, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'DAILY CALORIE BUDGET',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppColors.accentAmber),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_totalDailyCalories.toInt()} / ${_dailyCalorieTarget.toInt()} kcal',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _showCalorieBudgetDialog,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.settings_suggest_rounded, color: AppColors.accentAmber, size: 14),
                          ),
                        ),
                        if (_foodItems.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _clearAllFoodLogs,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.accentRose, size: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: calProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentAmber),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroPill('Protein', '${_totalDailyProtein.toStringAsFixed(0)}g', AppColors.secondary),
                    _buildMacroPill('Carbs', '${_totalDailyCarbs.toStringAsFixed(0)}g', AppColors.accentGreen),
                    _buildMacroPill('Fat', '${_totalDailyFat.toStringAsFixed(0)}g', AppColors.primaryGlow),
                  ],
                ),
              ],
            ),
          ),

          // 2. INBUILT FOOD QUICK PRESETS HORIZONTAL BAR
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 15, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'INBUILT FOOD PRESETS',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _openInbuiltFoodLibraryModal,
                      icon: const Icon(Icons.menu_book_rounded, size: 13, color: AppColors.secondary),
                      label: const Text('Browse 30+ 📚', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: InbuiltFoodLibrary.popularPresets.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _showAddDialog(p.category == 'Fruits' || p.defaultMealSlot.contains('Snack') ? 'Snack' : 'Meal', preset: p),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.emoji, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.calories.toInt()}k',
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.accentAmber, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodList(mealsList, 'Meal'),
                _buildFoodList(snacksList, 'Snack'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddDialog(_tabController.index == 0 ? 'Meal' : 'Snack'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Log Meal & Qty' : 'Log Snack & Qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildFoodList(List<FoodItem> items, String label) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text('No $label logged yet.', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Tap "+" below or pick an inbuilt food above to calculate calories!', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final f = items[i];
        final typeColor = _getTypeColor(f.type);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              f.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${f.quantity == f.quantity.toInt() ? f.quantity.toInt() : f.quantity} ${f.unit}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 18),
                      tooltip: 'Delete food entry',
                      onPressed: () => _deleteFoodItem(f),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4))),
                            child: Text(f.mealSlot, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: typeColor.withValues(alpha: 0.5))),
                              child: Text(f.type, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: typeColor), overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.accentAmber),
                          const SizedBox(width: 3),
                          Text('${f.calories.toInt()} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accentAmber)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('P: ${f.protein.toStringAsFixed(1)}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    const SizedBox(width: 10),
                    Text('C: ${f.carbs.toStringAsFixed(1)}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                    const SizedBox(width: 10),
                    Text('F: ${f.fat.toStringAsFixed(1)}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                    const Spacer(),
                    Text(f.time.format(context), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- TAB 4: EXPENSE TRACKER ----------------
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Snacks', 'Stationery', 'Clothes', 'Fruits', 'Flowers', 'Transport', 'Other'];
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

  void _addExpense() async {
    final item = _itemController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (item.isNotEmpty && amount > 0) {
      await DBHelper.instance.insertExpense({'item': item, 'category': _selectedCategory, 'amount': amount, 'date': DateTime.now().toIso8601String()});
      _itemController.clear();
      _amountController.clear();
      _fetchExpenses();
      if (mounted) {
        DisciplineFeedback.showCelebration(
          context: context,
          title: '💼 Financial Discipline Logged!',
          message: '₹$amount for "$item" tracked under $_selectedCategory.',
          disciplineQuote: 'Financial freedom is available to those who learn about it and work for it with discipline.',
          color: AppColors.accentRose,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentRose, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Financial Entry?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove the wrong/fake entry "${exp['item']}" of ₹${exp['amount']} (${exp['category']})?',
          style: const TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () async {
              Navigator.pop(ctx);
              if (exp['id'] != null) {
                await DBHelper.instance.deleteExpense(exp['id'] as int);
                _fetchExpenses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('🗑️ Entry "${exp['item']}" removed successfully.', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Food':
        return AppColors.accentGreen;
      case 'Snacks':
        return AppColors.accentAmber;
      case 'Stationery':
        return AppColors.primary;
      case 'Clothes':
        return AppColors.accentPurple;
      case 'Fruits':
        return AppColors.accentGreen;
      case 'Transport':
        return AppColors.secondary;
      default:
        return AppColors.accentRose;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSpent = 0;
    for (var e in _expenses) {
      totalSpent += (e['amount'] as num).toDouble();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // TOTAL EXPENSE SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1220), Color(0xFF161F33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(color: AppColors.accentRose.withValues(alpha: 0.12), blurRadius: 14),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL EXPENSES LOGGED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text('₹${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.accentRose)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentRose, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // QUICK ADD FORM
          Row(
            children: [
              Expanded(flex: 2, child: TextField(controller: _itemController, decoration: const InputDecoration(labelText: 'Expense Item'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '₹ Amount'))),
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
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? 'Food'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                ),
                onPressed: _addExpense,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // EXPENSE TRANSACTIONS LIST
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('No expenses recorded yet.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (ctx, i) {
                      final exp = _expenses[i];
                      final catColor = _getCategoryColor(exp['category']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.shopping_bag_outlined, color: catColor, size: 20),
                          ),
                          title: Text(exp['item'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          subtitle: Text(exp['category'], style: TextStyle(color: catColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${exp['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                                tooltip: 'Delete wrong entry',
                                onPressed: () => _deleteExpense(exp),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------- TAB 5: STRICT GOALS (NO OVERFLOW) ----------------
class StrictGoalsScreen extends StatefulWidget {
  const StrictGoalsScreen({super.key});

  @override
  State<StrictGoalsScreen> createState() => _StrictGoalsScreenState();
}

class _StrictGoalsScreenState extends State<StrictGoalsScreen> {
  List<GoalItem> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    AppSyncBus.syncTick.addListener(_loadGoals);
  }

  @override
  void dispose() {
    AppSyncBus.syncTick.removeListener(_loadGoals);
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final data = await DBHelper.instance.fetchGoals();
    if (mounted) {
      setState(() => _goals = data.map((e) => GoalItem.fromMap(e)).toList());
      NotificationService.instance.syncGoalNotifications(_goals);
    }
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final daysCtrl = TextEditingController();
    bool enableNotification = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.borderLight)),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add Strict Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Goal Title (e.g. 30 Days No Sugar)')),
              const SizedBox(height: 12),
              TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Days (e.g. 30)')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(enableNotification ? Icons.notifications_active_rounded : Icons.notifications_off_outlined, color: enableNotification ? AppColors.accentAmber : AppColors.textMuted, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('3x Daily Goal Reminders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                Text(enableNotification ? 'Alerts if incomplete today' : 'No alerts for this goal', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enableNotification,
                      activeThumbColor: AppColors.accentAmber,
                      onChanged: (val) => setModalState(() => enableNotification = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
                if (title.isNotEmpty && days > 0) {
                  final newGoal = GoalItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    targetDays: days,
                    notifyUser: enableNotification,
                  );
                  await DBHelper.instance.insertGoal(newGoal.toMap());
                  _loadGoals();
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (mounted) {
                    DisciplineFeedback.showCelebration(
                      context: context,
                      title: '🎯 Strict Goal Committed!',
                      message: 'You committed to "$title" for $days Days ${enableNotification ? "with 3x daily goal alerts" : ""}. Stand firm!',
                      disciplineQuote: 'Commitment is making the choice to give up other choices.',
                      color: AppColors.primary,
                    );
                  }
                }
              },
              child: const Text('Commit Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountabilityApologyDialog(BuildContext context, GoalItem goal) {
    final apologyCtrl = TextEditingController();
    String selectedReason = 'Lost Motivation / Inconsistency';
    final reasons = [
      'Lost Motivation / Inconsistency',
      'Target was Unrealistic / Overwhelming',
      'Procrastination & Distractions',
      'Health / Emergency Reason',
      'Replacing with Higher Standard Goal',
      'Other Personal Reason',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.accentRose, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Apology & Accountability',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breaking streak for "${goal.title}"',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Achieved Day ${goal.currentStreak} of ${goal.targetDays} Days. All broken streaks are permanently tracked in your Apology Archive.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('1. Why are you deleting / quitting this goal?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedReason = val ?? reasons[0]),
                ),
                const SizedBox(height: 14),
                const Text('2. Apology Letter & Reflection (Min 10 chars):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: apologyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'I apologize to myself because I lost discipline... I resolve to recommit by...',
                    hintStyle: TextStyle(fontSize: 11.5, color: Colors.white30),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Keep Goal & Persevere 💪', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
              onPressed: () async {
                final text = apologyCtrl.text.trim();
                if (text.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a genuine apology & reflection (at least 10 characters).')),
                  );
                  return;
                }
                await DBHelper.instance.insertDeletedGoal({
                  'title': goal.title,
                  'streakAchieved': goal.currentStreak,
                  'targetDays': goal.targetDays,
                  'apologyLetter': '[Reason: $selectedReason]\n$text',
                  'deletedAt': DateTime.now().toIso8601String(),
                });
                await DBHelper.instance.deleteGoal(goal.id);
                _loadGoals();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  DisciplineFeedback.showEncouragement(
                    context: context,
                    title: '🛡️ Apology Archived & Recommitment',
                    message: 'Your reflection has been recorded. Setbacks are just setups for a comeback. Recommit soon!',
                    confidenceQuote: 'A champion is not defined by their falls, but by how relentlessly they rise. Rebuild your standard now!',
                  );
                }
              },
              child: const Text('Sign Apology & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openApologyArchiveModal(BuildContext context) async {
    final deletedRecords = await DBHelper.instance.fetchDeletedGoals();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.accentRose, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BROKEN STREAKS & APOLOGY ARCHIVE', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.accentRose)),
                      Text('Learn from past setbacks & stay accountable', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: deletedRecords.isEmpty
                    ? const Center(
                        child: Text('No broken goals recorded! You have maintained complete streak integrity! 🏆', textAlign: TextAlign.center, style: TextStyle(color: AppColors.accentGreen, fontSize: 13)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: deletedRecords.length,
                        itemBuilder: (ctx, i) {
                          final rec = deletedRecords[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderLight)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(rec['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white), overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                        child: Text('Ended at Day ${rec['streakAchieved']}/${rec['targetDays']}', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                                    child: Text(
                                      rec['apologyLetter'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Deleted: ${rec['deletedAt']?.toString().substring(0, 10)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('No strict goals committed yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Tap "+" below to commit to your first streak!', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openApologyArchiveModal(context),
                    icon: const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.accentRose),
                    label: const Text('View Apology Archive', style: TextStyle(color: AppColors.accentRose)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'ACTIVE DISCIPLINE COMMITMENTS',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _openApologyArchiveModal(context),
                          icon: const Icon(Icons.history_edu_rounded, size: 14, color: AppColors.accentRose),
                          label: const Text('Apology Archive', style: TextStyle(fontSize: 11, color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }

                final g = _goals[i - 1];
                final progress = (g.currentStreak / g.targetDays).clamp(0.0, 1.0);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      final newNotify = !g.notifyUser;
                                      setState(() => g.notifyUser = newNotify);
                                      final messenger = ScaffoldMessenger.of(context);
                                      await DBHelper.instance.updateGoalNotification(g.id, newNotify);
                                      NotificationService.instance.syncGoalNotifications(_goals);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.surfaceElevated,
                                          duration: const Duration(seconds: 2),
                                          content: Text(
                                            newNotify ? '🔔 3x Daily Alerts ON for "${g.title}"' : '🔕 Goal Alerts OFF for "${g.title}"',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: g.notifyUser ? AppColors.accentAmber.withValues(alpha: 0.15) : Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        g.notifyUser ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                        size: 13,
                                        color: g.notifyUser ? AppColors.accentAmber : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Day ${g.currentStreak}/${g.targetDays} 🔥', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
                                  tooltip: 'Delete & Sign Apology',
                                  onPressed: () => _showAccountabilityApologyDialog(context, g),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('${(progress * 100).toInt()}% Done 🎯', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: g.isCompletedToday ? AppColors.surfaceElevated : AppColors.accentGreen.withValues(alpha: 0.18),
                                foregroundColor: g.isCompletedToday ? Colors.white54 : AppColors.accentGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: g.isCompletedToday ? Colors.white24 : AppColors.accentGreen.withValues(alpha: 0.5)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: () async {
                                final done = g.completeToday();
                                if (done) {
                                  await DBHelper.instance.updateGoal(g.id, g.currentStreak, g.lastCompletedDate?.toIso8601String());
                                  _loadGoals();
                                  if (context.mounted) {
                                    DisciplineFeedback.showCelebration(
                                      context: context,
                                      title: '🏆 STREAK CONQUERED!',
                                      message: 'Day ${g.currentStreak} achieved for "${g.title}"! Goal completed -> alerts auto-silenced.',
                                      disciplineQuote: 'Discipline is choosing between what you want now and what you want most.',
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    DisciplineFeedback.showEncouragement(
                                      context: context,
                                      title: '✅ Daily Check-in Completed!',
                                      message: 'You have already conquered "${g.title}" today. Rest and recharge for Day ${g.currentStreak + 1} tomorrow!',
                                      confidenceQuote: 'Consistency isn\'t about perfection. It\'s about simply never quitting.',
                                    );
                                  }
                                }
                              },
                              icon: Icon(g.isCompletedToday ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, size: 14),
                              label: Text(g.isCompletedToday ? 'Done Today ✅' : 'Done Today', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---------------- TAB 6: WORKOUT & WEEKLY WEIGH-IN ----------------
class WorkoutAndPhotosScreen extends StatefulWidget {
  const WorkoutAndPhotosScreen({super.key});

  @override
  State<WorkoutAndPhotosScreen> createState() => _WorkoutAndPhotosScreenState();
}

class _WorkoutAndPhotosScreenState extends State<WorkoutAndPhotosScreen> {
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  final _walkController = TextEditingController(text: '${WorkoutState.walkMins}');
  final _jogController = TextEditingController(text: '${WorkoutState.jogMins}');
  final _walkKmController = TextEditingController(text: WorkoutState.walkDistanceKm.toStringAsFixed(1));
  final _jogKmController = TextEditingController(text: WorkoutState.jogDistanceKm.toStringAsFixed(1));
  final _gymController = TextEditingController(text: '${WorkoutState.gymMins}');
  final _exerciseNameController = TextEditingController();
  final _exerciseWeightController = TextEditingController(text: '0');

  ExerciseTrackingType _selectedTrackingType = ExerciseTrackingType.reps;
  int _selectedSets = 4;
  int _selectedReps = 12;
  int _selectedDurationSeconds = 60;

  String _selectedCategory = 'Biceps';
  final List<String> _categories = ['Biceps', 'Chest', 'Back', 'Legs', 'Shoulders', 'Triceps', 'Core', 'Cardio'];

  String? _workoutFeedbackMessage;
  bool _workoutSuccess = false;

  XFile? _face;
  XFile? _front;
  XFile? _side;

  final ImagePicker _picker = ImagePicker();

  void _saveCardioAndDistance() async {
    final walkKm = double.tryParse(_walkKmController.text.trim()) ?? ((int.tryParse(_walkController.text.trim()) ?? 0) * 0.08);
    final jogKm = double.tryParse(_jogKmController.text.trim()) ?? ((int.tryParse(_jogController.text.trim()) ?? 0) * 0.15);
    final walkM = int.tryParse(_walkController.text.trim()) ?? (walkKm / 0.08).round();
    final jogM = int.tryParse(_jogController.text.trim()) ?? (jogKm / 0.15).round();
    final gymM = int.tryParse(_gymController.text.trim()) ?? 0;

    setState(() {
      WorkoutState.walkMins = walkM;
      WorkoutState.jogMins = jogM;
      WorkoutState.gymMins = gymM;
      WorkoutState.updateDistance(
        walkKm: walkKm,
        jogKm: jogKm,
        walkMinutes: walkM,
        jogMinutes: jogM,
      );
      AppSyncBus.notifyDataChanged();
    });

    await HierarchicalStorageManager.saveDailyRecord(
      date: DateTime.now(),
      data: {
        'type': 'CardioDistanceSession',
        'walkKm': walkKm,
        'jogKm': jogKm,
        'walkMins': walkM,
        'jogMins': jogM,
        'gymMins': gymM,
        'totalKm': WorkoutState.totalDistanceKm,
      },
    );

    if (mounted) {
      DisciplineFeedback.showCelebration(
        context: context,
        title: '⚡ ${WorkoutState.totalDistanceKm.toStringAsFixed(1)} KM Distance & Cardio Saved!',
        message: 'Walk: ${walkKm.toStringAsFixed(1)} km ($walkM mins) | Jog: ${jogKm.toStringAsFixed(1)} km ($jogM mins) | Gym: $gymM mins.\nDashboard line graphs updated!',
        disciplineQuote: 'Every single mile logged compounds into unbeatable physical mastery.',
        color: AppColors.accentBlue,
        icon: Icons.directions_run_rounded,
      );
    }
  }

  Color _getMuscleCategoryColor(String cat) {
    switch (cat) {
      case 'Chest':
        return AppColors.accentRose;
      case 'Back':
        return AppColors.accentBlue;
      case 'Biceps':
        return AppColors.accentAmber;
      case 'Triceps':
        return AppColors.primaryGlow;
      case 'Legs':
        return AppColors.accentGreen;
      case 'Shoulders':
        return AppColors.secondary;
      case 'Core':
        return AppColors.accentPurple;
      case 'Cardio':
        return AppColors.secondaryGlow;
      default:
        return AppColors.primary;
    }
  }

  void _updateWeeklyBodyMetrics({bool force = false}) {
    if (!HealthState.canLogWeeklyWeight && !force) {
      DisciplineFeedback.showEncouragement(
        context: context,
        title: '⚖️ Weekly Weigh-in Protocol',
        message: 'Weight is tracked once per week to filter out daily water fluctuations. Next weigh-in opens in ${HealthState.daysUntilNextWeighIn} day(s).',
        confidenceQuote: 'True transformation takes weekly compounding. Focus on your daily nutrition and training reps!',
      );
      return;
    }

    double w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    double tw = double.tryParse(_targetWeightCtrl.text.trim()) ?? 0.0;
    double h = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;

    setState(() {
      HealthState.weightKg = w;
      HealthState.targetWeightKg = tw;
      HealthState.heightCm = h;
      HealthState.lastWeightLogDate = DateTime.now();

      if (w > 0) {
        if (HealthState.monthlyWeightHistory.length >= 4) HealthState.monthlyWeightHistory.removeAt(0);
        HealthState.monthlyWeightHistory.add(w);
      }
    });

    DisciplineFeedback.showCelebration(
      context: context,
      title: '⚖️ Body Metrics Saved!',
      message: 'Weekly weight logged: ${HealthState.weightKg} kg | Target: ${HealthState.targetWeightKg} kg | BMI: ${HealthState.bmi > 0 ? HealthState.bmi.toStringAsFixed(1) : "--"} (${HealthState.bmiCategory})',
      disciplineQuote: 'You do not build a masterpiece in a day, you build it brick by brick, session by session.',
      color: HealthState.bmiColor,
    );
  }

  Future<void> _uploadPhoto(String angle) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null && mounted) {
        setState(() {
          if (angle == 'Face') _face = photo;
          if (angle == 'Front') _front = photo;
          if (angle == 'Side') _side = photo;
        });
        DisciplineFeedback.showCelebration(
          context: context,
          title: '📸 Physique Snapshot Saved!',
          message: '$angle profile photo logged for today. Visual progress compounding!',
          disciplineQuote: 'Look in the mirror. That is your only competition.',
          color: AppColors.secondary,
        );
      }
    } catch (_) {}
  }

  void _addExercise() {
    final name = _exerciseNameController.text.trim();
    if (name.isNotEmpty) {
      final w = double.tryParse(_exerciseWeightController.text.trim()) ?? 0.0;
      setState(() {
        WorkoutState.exercises.add(ExerciseItem(
          name: name,
          category: _selectedCategory,
          trackingType: _selectedTrackingType,
          sets: _selectedSets,
          reps: _selectedReps,
          durationSeconds: _selectedDurationSeconds,
          weightKg: w,
          completedSets: 0,
          isDone: false,
        ));
      });
      _exerciseNameController.clear();
      _exerciseWeightController.text = '0';
    }
  }

  void _finishWorkoutSession() {
    if (WorkoutState.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your exercises for today first!')));
      return;
    }

    final total = WorkoutState.totalExercisesCount;
    final finished = WorkoutState.completedExercisesCount;
    final totalSets = WorkoutState.totalSetsCount;
    final finishedSets = WorkoutState.completedSetsCount;
    final totalReps = WorkoutState.totalRepsCount;

    setState(() {
      WorkoutState.walkMins = int.tryParse(_walkController.text.trim()) ?? WorkoutState.walkMins;
      WorkoutState.jogMins = int.tryParse(_jogController.text.trim()) ?? WorkoutState.jogMins;
      WorkoutState.gymMins = int.tryParse(_gymController.text.trim()) ?? WorkoutState.gymMins;

      if (finished == total && WorkoutState.warmupCompleted) {
        _workoutSuccess = true;
        _workoutFeedbackMessage = '🔥 CHAMPION WORKOUT! Finished all $total exercises, $finishedSets sets & $totalReps reps!';
      } else {
        _workoutSuccess = false;
        final missed = total - finished;
        _workoutFeedbackMessage = '💪 Workout Logged: $finished/$total exercises ($finishedSets/$totalSets sets, $totalReps reps done, $missed remaining). Rise stronger tomorrow!';
      }
    });

    if (_workoutSuccess) {
      DisciplineFeedback.showCelebration(
        context: context,
        title: '🏋️ BEAST MODE UNLOCKED!',
        message: 'All $total exercises, $finishedSets sets, and $totalReps reps completed with zero compromises! Total active training: ${WorkoutState.totalWorkoutMinutes} mins.',
        disciplineQuote: 'The iron never lies to you. Greatness is earned in the arena, rep by rep.',
        color: AppColors.accentBlue,
      );
    } else {
      DisciplineFeedback.showEncouragement(
        context: context,
        title: '💪 VALIANT EFFORT IN THE ARENA!',
        message: '$finished of $total exercises ($finishedSets/$totalSets sets, $totalReps reps) completed. Showing up builds unstoppable mental grit!',
        confidenceQuote: 'Champions are made on the days they don\'t feel like showing up. Rest, refuel, and conquer tomorrow!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLogWeight = HealthState.canLogWeeklyWeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WEEKLY BODY COMPOSITION & TARGET CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HealthState.bmiColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: HealthState.bmiColor.withValues(alpha: 0.08), blurRadius: 14),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text('⚖️ WEEKLY BODY COMPOSITION & BMI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HealthState.bmiColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        HealthState.bmi > 0 ? 'BMI ${HealthState.bmi.toStringAsFixed(1)} • ${HealthState.bmiCategory}' : 'BMI: --',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: HealthState.bmiColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  canLogWeight
                      ? '📅 Weekly Weigh-In Protocol: Ready for this week\'s measurement.'
                      : '🔒 Weekly Weigh-In Protocol: Logged for this week (${HealthState.daysUntilNextWeighIn} days until next weigh-in).',
                  style: TextStyle(fontSize: 11.5, color: canLogWeight ? AppColors.accentGreen : AppColors.accentAmber, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _targetWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Goal (kg)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Height (cm)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateWeeklyBodyMetrics(force: false),
                        child: Text(canLogWeight ? 'Save Weekly Weigh-In' : 'Weekly Weigh-In Saved ✅', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (!canLogWeight) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _updateWeeklyBodyMetrics(force: true),
                        child: const Text('Calibrate'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_workoutFeedbackMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _workoutSuccess ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _workoutSuccess ? AppColors.accentGreen : AppColors.accentAmber),
              ),
              child: Row(
                children: [
                  Icon(_workoutSuccess ? Icons.workspace_premium_rounded : Icons.fitness_center_rounded, color: _workoutSuccess ? AppColors.accentGreen : AppColors.accentAmber, size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_workoutFeedbackMessage!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _workoutSuccess ? AppColors.accentGreen : AppColors.accentAmber))),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // LIVE WORKOUT SESSION SUMMARY BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1E33), Color(0xFF14223D), Color(0xFF1F132E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.12), blurRadius: 14),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: AppColors.accentBlue, size: 18),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'LIVE WORKOUT VOLUME & SETS',
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11.5, color: AppColors.accentBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (WorkoutState.completedExercisesCount == WorkoutState.totalExercisesCount && WorkoutState.totalExercisesCount > 0
                                ? AppColors.accentGreen
                                : AppColors.secondary)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${WorkoutState.completedExercisesCount}/${WorkoutState.totalExercisesCount} Conquered',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: WorkoutState.completedExercisesCount == WorkoutState.totalExercisesCount && WorkoutState.totalExercisesCount > 0
                              ? AppColors.accentGreen
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSessionMetricMini(
                        'EXERCISES',
                        '${WorkoutState.completedExercisesCount}/${WorkoutState.totalExercisesCount}',
                        Icons.fitness_center_rounded,
                        AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSessionMetricMini(
                        'SETS COMPLETED',
                        '${WorkoutState.completedSetsCount}/${WorkoutState.totalSetsCount}',
                        Icons.repeat_rounded,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSessionMetricMini(
                        'REPS / TIME',
                        '${WorkoutState.totalRepsCount} Reps',
                        Icons.flash_on_rounded,
                        AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Card(
            child: CheckboxListTile(
              activeColor: AppColors.accentGreen,
              title: const Text('Pre-Workout Warmup Completed?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              value: WorkoutState.warmupCompleted,
              onChanged: (v) => setState(() => WorkoutState.warmupCompleted = v ?? false),
            ),
          ),
          const SizedBox(height: 10),
          // CARDIO & DISTANCE TRACKING CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.directions_run_rounded, color: AppColors.accentBlue, size: 18),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '🏃 DAILY CARDIO & DISTANCE',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: AppColors.accentBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${WorkoutState.totalDistanceKm.toStringAsFixed(1)} KM Total', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.accentGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. WALKING INPUTS ROW
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _walkKmController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Walk (KM)',
                          prefixIcon: Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white70),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onChanged: (val) {
                          final km = double.tryParse(val) ?? 0.0;
                          _walkController.text = (km / 0.08).round().toString();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _walkController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Walk Mins', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                        onChanged: (val) {
                          final mins = int.tryParse(val) ?? 0;
                          _walkKmController.text = (mins * 0.08).toStringAsFixed(1);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. JOGGING & GYM INPUTS ROW
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _jogKmController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Jog (KM)',
                          prefixIcon: Icon(Icons.directions_run_rounded, size: 16, color: AppColors.secondary),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onChanged: (val) {
                          final km = double.tryParse(val) ?? 0.0;
                          _jogController.text = (km / 0.15).round().toString();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _jogController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jog Mins', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                        onChanged: (val) {
                          final mins = int.tryParse(val) ?? 0;
                          _jogKmController.text = (mins * 0.15).toStringAsFixed(1);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _gymController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Gym (m)',
                          prefixIcon: Icon(Icons.fitness_center_rounded, size: 14, color: AppColors.accentBlue),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                    onPressed: _saveCardioAndDistance,
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                    label: const Text('Save Daily Distance & Cardio 🏃', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 28),

          // ADD EXERCISE WITH REPS OR TIME FORM
          const Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: AppColors.accentBlue, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '🏋️ ADD EXERCISE (REPS OR TIME TRACKING)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TRACKING MODE TOGGLE (REPS vs TIME)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTrackingType = ExerciseTrackingType.reps),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTrackingType == ExerciseTrackingType.reps
                                  ? AppColors.secondary.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedTrackingType == ExerciseTrackingType.reps
                                    ? AppColors.secondary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.repeat_rounded, size: 16, color: _selectedTrackingType == ExerciseTrackingType.reps ? AppColors.secondary : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Reps-Based',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTrackingType == ExerciseTrackingType.reps ? Colors.white : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTrackingType = ExerciseTrackingType.time),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTrackingType == ExerciseTrackingType.time
                                  ? AppColors.accentAmber.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedTrackingType == ExerciseTrackingType.time
                                    ? AppColors.accentAmber
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer_rounded, size: 16, color: _selectedTrackingType == ExerciseTrackingType.time ? AppColors.accentAmber : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Time-Based',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTrackingType == ExerciseTrackingType.time ? Colors.white : AppColors.textMuted,
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
                const SizedBox(height: 12),

                // 2. MUSCLE GROUP & NAME
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        decoration: const InputDecoration(labelText: 'Muscle', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val ?? 'Biceps'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _exerciseNameController,
                        decoration: InputDecoration(
                          labelText: _selectedTrackingType == ExerciseTrackingType.reps
                              ? 'Exercise (e.g. Incline Bench)'
                              : 'Exercise (e.g. Plank Hold)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. SETS COUNT & REPS / DURATION STEPPERS (SPACIOUS 2-COLUMN LAYOUT)
                Row(
                  children: [
                    // SETS / ROUNDS STEPPER
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTrackingType == ExerciseTrackingType.reps ? 'Sets Count' : 'Rounds Count',
                              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_selectedSets > 1) setState(() => _selectedSets--);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.remove, size: 14, color: AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$_selectedSets ${_selectedTrackingType == ExerciseTrackingType.reps ? "Sets" : "Rnds"}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    if (_selectedSets < 15) setState(() => _selectedSets++);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.add, size: 14, color: AppColors.secondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // REPS OR DURATION STEPPER
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_selectedTrackingType == ExerciseTrackingType.reps ? AppColors.accentGreen : AppColors.accentAmber)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTrackingType == ExerciseTrackingType.reps ? 'Reps / Set' : 'Duration / Round',
                              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_selectedTrackingType == ExerciseTrackingType.reps) {
                                      if (_selectedReps > 1) setState(() => _selectedReps--);
                                    } else {
                                      if (_selectedDurationSeconds > 5) setState(() => _selectedDurationSeconds -= 5);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                    child: Icon(Icons.remove, size: 14, color: _selectedTrackingType == ExerciseTrackingType.reps ? AppColors.accentGreen : AppColors.accentAmber),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _selectedTrackingType == ExerciseTrackingType.reps
                                          ? '$_selectedReps Reps'
                                          : (_selectedDurationSeconds >= 60
                                              ? '${_selectedDurationSeconds ~/ 60}m${_selectedDurationSeconds % 60 > 0 ? " ${_selectedDurationSeconds % 60}s" : ""}'
                                              : '$_selectedDurationSeconds s'),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    if (_selectedTrackingType == ExerciseTrackingType.reps) {
                                      if (_selectedReps < 100) setState(() => _selectedReps++);
                                    } else {
                                      if (_selectedDurationSeconds < 3600) setState(() => _selectedDurationSeconds += 5);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                    child: Icon(Icons.add, size: 14, color: _selectedTrackingType == ExerciseTrackingType.reps ? AppColors.accentGreen : AppColors.accentAmber),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. WEIGHT / RESISTANCE LOAD INPUT (SPACIOUS DEDICATED ROW)
                TextField(
                  controller: _exerciseWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight / Load (kg) • 0 for Bodyweight',
                    prefixIcon: Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.secondary),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // QUICK TIME PRESETS IF TIME-BASED
                if (_selectedTrackingType == ExerciseTrackingType.time) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [30, 45, 60, 90, 120].map((secs) {
                      final isSelected = _selectedDurationSeconds == secs;
                      return ActionChip(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        backgroundColor: isSelected ? AppColors.accentAmber.withValues(alpha: 0.3) : AppColors.surfaceElevated,
                        side: BorderSide(color: isSelected ? AppColors.accentAmber : AppColors.borderLight),
                        label: Text('${secs}s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? AppColors.accentAmber : Colors.white70)),
                        onPressed: () => setState(() => _selectedDurationSeconds = secs),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _selectedTrackingType == ExerciseTrackingType.reps
                          ? 'Add Reps Exercise ($_selectedSets Sets × $_selectedReps Reps)'
                          : 'Add Time Exercise ($_selectedSets Rounds × ${_selectedDurationSeconds}s)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // EXERCISE CARDS WITH INTERACTIVE SETS & REPS / TIME CHIPS
          if (WorkoutState.exercises.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'ACTIVE EXERCISE ROUTINE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${WorkoutState.exercises.length} Exercises Logged',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => WorkoutState.exercises.clear()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 13, color: AppColors.accentRose),
                            SizedBox(width: 3),
                            Text('Clear All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...WorkoutState.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final ex = entry.value;
              final catColor = _getMuscleCategoryColor(ex.category);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ex.isDone ? AppColors.accentGreen.withValues(alpha: 0.08) : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ex.isDone ? AppColors.accentGreen.withValues(alpha: 0.5) : catColor.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ex.isRepsBased
                                      ? AppColors.secondary.withValues(alpha: 0.18)
                                      : AppColors.accentAmber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: ex.isRepsBased ? AppColors.secondary : AppColors.accentAmber,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  ex.isRepsBased ? 'REPS' : 'TIME',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: ex.isRepsBased ? AppColors.secondary : AppColors.accentAmber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: catColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  ex.category.toUpperCase(),
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: catColor, letterSpacing: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: TextStyle(
                                    decoration: ex.isDone ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: ex.isDone ? AppColors.textMuted : Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: AppColors.accentGreen,
                              value: ex.isDone,
                              onChanged: (v) => setState(() => ex.toggleDone(v ?? false)),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.close_rounded, color: AppColors.accentRose, size: 18),
                              onPressed: () => setState(() => WorkoutState.exercises.removeAt(index)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            ex.formattedTarget,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: Text(
                            ex.formattedProgress,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ex.isDone ? AppColors.accentGreen : AppColors.textMuted),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // INTERACTIVE SET / ROUND CHIPS (Tap to log each set)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(ex.sets, (setIdx) {
                        final isSetCompleted = setIdx < (ex.isDone ? ex.sets : ex.completedSets);
                        return InkWell(
                          onTap: () => setState(() => ex.toggleSet(setIdx)),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSetCompleted ? AppColors.accentGreen.withValues(alpha: 0.25) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSetCompleted ? AppColors.accentGreen : AppColors.borderLight,
                                width: isSetCompleted ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSetCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 12,
                                  color: isSetCompleted ? AppColors.accentGreen : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ex.setChipLabel(setIdx),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSetCompleted ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text('No exercises added yet. Use the form above to log exercises, sets, reps or time!', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ),
            ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _finishWorkoutSession,
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              label: const Text('Finish Workout & Verify Sets, Reps & Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5), overflow: TextOverflow.ellipsis),
            ),
          ),
          const Divider(height: 28),

          const Text('📸 Daily Physique Photos (Upload 3 Angles)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Select photos from your gallery:', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              _photoUploadBox('Face', _face),
              const SizedBox(width: 8),
              _photoUploadBox('Front', _front),
              const SizedBox(width: 8),
              _photoUploadBox('Side', _side),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetricMini(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _photoUploadBox(String title, XFile? f) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _uploadPhoto(title),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: f != null ? AppColors.accentGreen : AppColors.borderLight, width: f != null ? 2 : 1),
            boxShadow: [
              if (f != null) BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.2), blurRadius: 10),
            ],
          ),
          child: f != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(f.path, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Center(child: Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28))),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_camera_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Text('Tap to upload', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------- TAB 7: STUDY & ENGLISH ----------------
class StudyAndEnglishScreen extends StatefulWidget {
  const StudyAndEnglishScreen({super.key});

  @override
  State<StudyAndEnglishScreen> createState() => _StudyAndEnglishScreenState();
}

class _StudyAndEnglishScreenState extends State<StudyAndEnglishScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Timer? _studyTimer;
  int _studySeconds = 0;
  bool _isTimerRunning = false;
  final _subjectCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<Map<String, dynamic>> _studyList = [];

  final _listenVideoNameCtrl = TextEditingController();
  final _listenVideoLinkCtrl = TextEditingController();
  final _listenUserTitleCtrl = TextEditingController();
  final _listenContentCtrl = TextEditingController();
  final List<EnglishListeningLog> _listeningHistory = [];

  XFile? _uploadedEnglishVideo;

  final _wordCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  final List<VocabularyWord> _vocabularyList = [];

  Timer? _readingTimer;
  int _readingRemainingSeconds = 15 * 60;
  int _selectedReadingMinutes = 15;
  bool _isReadingTimerActive = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
    AppSyncBus.syncTick.addListener(_fetch);
  }

  @override
  void dispose() {
    AppSyncBus.syncTick.removeListener(_fetch);
    _studyTimer?.cancel();
    _readingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final data = await DBHelper.instance.fetchStudyLogs();
    if (mounted) setState(() => _studyList = data);
  }

  void _toggleStudyTimer() {
    if (_isTimerRunning) {
      _studyTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _studySeconds++);
      });
      setState(() => _isTimerRunning = true);
    }
  }

  void _resetStudyTimer() {
    _studyTimer?.cancel();
    setState(() {
      _studySeconds = 0;
      _isTimerRunning = false;
    });
  }

  String _formatTimer(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _saveStudySession() async {
    final topic = _topicCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (topic.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter topic title and notes!')));
      return;
    }

    final formattedTimeSpent = _formatTimer(_studySeconds);
    final subject = _subjectCtrl.text.isEmpty ? 'General' : _subjectCtrl.text.trim();

    await DBHelper.instance.insertStudyLog({
      'subject': subject,
      'topic': topic,
      'desc': desc,
      'timeSpent': formattedTimeSpent,
      'date': DateTime.now().toIso8601String(),
    });

    // STORE TO HIERARCHICAL STORAGE
    await HierarchicalStorageManager.saveDailyRecord(
      date: DateTime.now(),
      data: {
        'type': 'StudySession',
        'subject': subject,
        'topic': topic,
        'desc': desc,
        'timeSpent': formattedTimeSpent,
        'seconds': _studySeconds,
      },
    );

    _subjectCtrl.clear();
    _topicCtrl.clear();
    _descCtrl.clear();
    _resetStudyTimer();
    _fetch();

    if (mounted) {
      DisciplineFeedback.showCelebration(
        context: context,
        title: '🧠 DEEP FOCUS LOGGED!',
        message: 'Topic: "$topic" ($subject) | Focus Time: $formattedTimeSpent.\nKnowledge compounded daily creates unstoppable mastery!',
        disciplineQuote: 'An investment in knowledge always pays the best interest.',
        color: AppColors.primary,
        icon: Icons.psychology_rounded,
      );
    }
  }

  void _saveListeningSession() async {
    final videoName = _listenVideoNameCtrl.text.trim();
    final videoLink = _listenVideoLinkCtrl.text.trim();
    final userTitle = _listenUserTitleCtrl.text.trim();
    final content = _listenContentCtrl.text.trim();

    if (userTitle.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide your title and listened content summary!')));
      return;
    }

    setState(() {
      _listeningHistory.insert(0, EnglishListeningLog(videoName: videoName.isEmpty ? 'Podcast' : videoName, videoLink: videoLink.isEmpty ? 'N/A' : videoLink, userTitle: userTitle, content: content, loggedAt: DateTime.now()));
    });

    await HierarchicalStorageManager.saveDailyRecord(
      date: DateTime.now(),
      data: {
        'type': 'EnglishListening',
        'videoName': videoName,
        'videoLink': videoLink,
        'userTitle': userTitle,
        'content': content,
      },
    );

    _listenVideoNameCtrl.clear();
    _listenVideoLinkCtrl.clear();
    _listenUserTitleCtrl.clear();
    _listenContentCtrl.clear();

    if (mounted) {
      DisciplineFeedback.showCelebration(
        context: context,
        title: '🎧 LISTENING SUMMARY SAVED!',
        message: 'Takeaways from "$userTitle" ($videoName) recorded into your growth bank!',
        disciplineQuote: 'Master communicators are first master listeners.',
        color: AppColors.secondary,
        icon: Icons.headphones_rounded,
      );
    }
  }

  Future<void> _uploadEnglishSpeakingVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        setState(() => _uploadedEnglishVideo = video);
        DisciplineFeedback.showCelebration(
          context: context,
          title: '🌟 SPEAKING VIDEO LOGGED!',
          message: 'Today\'s English speaking recording successfully attached. Your articulation standard is set!',
          disciplineQuote: 'Confidence is built by doing what you feared until fear disappears.',
          color: AppColors.accentAmber,
          icon: Icons.video_call_rounded,
        );
      }
    } catch (_) {}
  }

  void _addVocabularyWord() {
    final word = _wordCtrl.text.trim();
    final meaning = _meaningCtrl.text.trim();
    final example = _exampleCtrl.text.trim();

    if (word.isNotEmpty && meaning.isNotEmpty) {
      setState(() {
        _vocabularyList.insert(0, VocabularyWord(word: word, meaning: meaning, example: example, loggedAt: DateTime.now()));
      });
      _wordCtrl.clear();
      _meaningCtrl.clear();
      _exampleCtrl.clear();

      DisciplineFeedback.showCelebration(
        context: context,
        title: '📖 VOCABULARY EXPANDED!',
        message: 'New word added: "$word" - $meaning',
        disciplineQuote: 'The limits of my language mean the limits of my world.',
        color: AppColors.accentPurple,
        icon: Icons.menu_book_rounded,
      );
    }
  }

  void _startReadingTimer() {
    _readingTimer?.cancel();
    setState(() => _isReadingTimerActive = true);
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_readingRemainingSeconds > 0) {
        setState(() => _readingRemainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isReadingTimerActive = false);
        if (mounted) {
          DisciplineFeedback.showCelebration(
            context: context,
            title: '📚 READING SPRINT CONQUERED!',
            message: 'Completed $_selectedReadingMinutes minutes of distraction-free reading! Your mind is sharpened.',
            disciplineQuote: 'Reading is to the mind what exercise is to the body.',
            color: AppColors.accentGreen,
          );
        }
      }
    });
  }

  void _pauseReadingTimer() {
    _readingTimer?.cancel();
    setState(() => _isReadingTimerActive = false);
  }

  void _resetReadingTimer(int minutes) {
    _readingTimer?.cancel();
    setState(() {
      _selectedReadingMinutes = minutes;
      _readingRemainingSeconds = minutes * 60;
      _isReadingTimerActive = false;
    });
  }

  void _deleteStudyLog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentRose, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Study Log?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove the wrong/fake study session "${item['topic']}" (${item['subject']})?',
          style: const TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () async {
              Navigator.pop(ctx);
              if (item['id'] != null) {
                await DBHelper.instance.deleteStudyLog(item['id'] as int);
                _fetch();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('🗑️ Study session "${item['topic']}" removed.', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteListeningLog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentRose, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Listening Entry?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove the listening log "${_listeningHistory[index].userTitle}"?',
          style: const TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _listeningHistory.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Text('🗑️ Listening entry removed.', style: TextStyle(color: Colors.white)),
                ),
              );
            },
            child: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteVocabularyWord(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentRose, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Word?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove the vocabulary word "${_vocabularyList[index].word}"?',
          style: const TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _vocabularyList.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Text('🗑️ Vocabulary word removed.', style: TextStyle(color: Colors.white)),
                ),
              );
            },
            child: const Text('Delete Word', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.timer_outlined, size: 16), text: 'Study Tracker'),
              Tab(icon: Icon(Icons.record_voice_over_outlined, size: 16), text: 'English Studio'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIVE STUDY FOCUS STOPWATCH
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F1538), Color(0xFF131D33)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 14),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Live Study Focus Stopwatch', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(_formatTimer(_studySeconds), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.secondary)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: _toggleStudyTimer,
                            icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                            label: Text(_isTimerRunning ? 'Pause' : 'Start Focus', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(onPressed: _resetStudyTimer, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Reset')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject (e.g. VLSI Design / Math)')),
                const SizedBox(height: 10),
                TextField(controller: _topicCtrl, decoration: const InputDecoration(labelText: 'Topic Title')),
                const SizedBox(height: 10),
                TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Learnings & Revision Notes')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveStudySession,
                    child: const Text('Save Study Session & Time Log'),
                  ),
                ),
                const Divider(height: 28),
                const Text('Logged Study Sessions:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                if (_studyList.isEmpty)
                  const Text('No study sessions saved yet.', style: TextStyle(color: AppColors.textMuted))
                else
                  ..._studyList.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${item['topic']} (${item['subject']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${item['desc']}', style: const TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${item['timeSpent']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                                tooltip: 'Delete wrong entry',
                                onPressed: () => _deleteStudyLog(item),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.headphones_rounded, color: AppColors.secondary, size: 18),
                    SizedBox(width: 6),
                    Text('Daily English Video Listening Hub', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Listen to any English video/podcast and log your learnings:', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                TextField(controller: _listenVideoNameCtrl, decoration: const InputDecoration(labelText: '1. Video Name / Speaker')),
                const SizedBox(height: 10),
                TextField(controller: _listenVideoLinkCtrl, decoration: const InputDecoration(labelText: '2. Video Link / URL')),
                const SizedBox(height: 10),
                TextField(controller: _listenUserTitleCtrl, decoration: const InputDecoration(labelText: '3. Your Title / Main Takeaway Heading')),
                const SizedBox(height: 10),
                TextField(controller: _listenContentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '4. Listened Content (Key learnings)')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveListeningSession,
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: const Text('Save Video Listening Summary'),
                  ),
                ),
                const SizedBox(height: 14),
                if (_listeningHistory.isNotEmpty) ...[
                  const Text('Logged Listening History:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  ..._listeningHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(item.userTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 18),
                                  tooltip: 'Delete listening log',
                                  onPressed: () => _deleteListeningLog(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Source: ${item.videoName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                            const Divider(height: 16),
                            Text(item.content, style: const TextStyle(fontSize: 12.5, color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const Divider(height: 28),

                const Row(
                  children: [
                    Icon(Icons.video_call_rounded, color: AppColors.accentAmber, size: 18),
                    SizedBox(width: 6),
                    Text('Daily English Speaking Video Upload', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentAmber)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, size: 36, color: _uploadedEnglishVideo != null ? AppColors.accentGreen : AppColors.accentAmber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_uploadedEnglishVideo == null ? 'No speaking video uploaded' : 'Today\'s Speaking Video Attached ✅', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Upload 1-2 min video of yourself speaking English', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _uploadEnglishSpeakingVideo,
                        child: Text(_uploadedEnglishVideo == null ? 'Upload' : 'Change', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),

                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: AppColors.accentPurple, size: 18),
                    SizedBox(width: 6),
                    Text('New Words & Meaning Bank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentPurple)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _wordCtrl, decoration: const InputDecoration(labelText: 'Word'))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: _meaningCtrl, decoration: const InputDecoration(labelText: 'Meaning'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _exampleCtrl, decoration: const InputDecoration(labelText: 'Example Sentence (Optional)'))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _addVocabularyWord,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_vocabularyList.isNotEmpty)
                  ..._vocabularyList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final v = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(v.word, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14.5)),
                        subtitle: Text('${v.meaning}${v.example.isNotEmpty ? '\nEx: "${v.example}"' : ''}', style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                          tooltip: 'Delete word',
                          onPressed: () => _deleteVocabularyWord(index),
                        ),
                      ),
                    );
                  }),
                const Divider(height: 28),

                const Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: AppColors.accentGreen, size: 18),
                    SizedBox(width: 6),
                    Text('Distraction-Free Reading Timer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentGreen)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [10, 15, 20, 30].map((mins) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text('$mins min'),
                                selected: _selectedReadingMinutes == mins,
                                selectedColor: AppColors.accentGreen.withValues(alpha: 0.25),
                                onSelected: (sel) {
                                  if (sel) _resetReadingTimer(mins);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_formatTimer(_readingRemainingSeconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.accentGreen)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.black),
                            onPressed: _isReadingTimerActive ? _pauseReadingTimer : _startReadingTimer,
                            icon: Icon(_isReadingTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            label: Text(_isReadingTimerActive ? 'Pause' : 'Start Reading', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(onPressed: () => _resetReadingTimer(_selectedReadingMinutes), icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Reset')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
