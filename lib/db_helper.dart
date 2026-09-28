import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/workout_template_models.dart';
import 'models/food_models.dart';
import 'models/body_photo_model.dart';
import 'models/physique_measurement_model.dart';
import 'models/weight_entry_model.dart';
import 'models/workout_history_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  final List<Map<String, dynamic>> _inMemoryGoals = [];
  final List<Map<String, dynamic>> _inMemoryDeleted = [];
  final List<Map<String, dynamic>> _inMemoryExpenses = [];
  final List<Map<String, dynamic>> _inMemoryStudy = [];
  final List<Map<String, dynamic>> _inMemoryFood = [];
  final List<Map<String, dynamic>> _inMemoryMeals = [];
  final Map<String, Map<String, dynamic>> _inMemoryWorkouts = {};
  final List<Map<String, dynamic>> _inMemoryBodyPhotos = [];
  final List<Map<String, dynamic>> _inMemoryPhysique = [];
  final List<Map<String, dynamic>> _inMemoryWeeklyWeights = [];
  final List<Map<String, dynamic>> _inMemoryWorkoutLogs = [];
  final List<Map<String, dynamic>> _inMemoryWorkoutSessions = [];
  final Map<String, Map<String, dynamic>> _inMemoryPersonalRecords = {};

  DBHelper._init();

  // Returns true if running on Web OR Flutter Test environment
  bool get isMockEnvironment => kIsWeb || (PlatformDispatcher.instance.views.isEmpty);

  Future<Database?> get database async {
    if (isMockEnvironment) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('growth_tracker_v4.db');
      return _database!;
    } catch (_) {
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS meals (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                mealType TEXT NOT NULL,
                date TEXT NOT NULL,
                photoPath TEXT,
                photoBase64 TEXT,
                foodItemsJson TEXT NOT NULL,
                totalCalories REAL NOT NULL,
                totalProtein REAL NOT NULL,
                totalCarbs REAL NOT NULL,
                totalFat REAL NOT NULL,
                totalFiber REAL NOT NULL,
                notes TEXT,
                isAiAnalyzed INTEGER DEFAULT 1
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS workout_days (
                dayName TEXT PRIMARY KEY,
                workoutName TEXT NOT NULL,
                targetMuscleGroup TEXT NOT NULL,
                estimatedMinutes INTEGER NOT NULL,
                difficulty TEXT NOT NULL,
                status TEXT NOT NULL,
                exercisesJson TEXT NOT NULL,
                notes TEXT
              )
            ''');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS body_photos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                photoBase64 TEXT,
                photoPath TEXT,
                weightKg REAL,
                note TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS physique_measurements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                unit TEXT NOT NULL,
                chest REAL,
                waist REAL,
                abdomen REAL,
                hip REAL,
                neck REAL,
                leftArm REAL,
                rightArm REAL,
                leftThigh REAL,
                rightThigh REAL,
                comment TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS weekly_weight_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                weekKey TEXT NOT NULL,
                weightKg REAL NOT NULL,
                comment TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS workout_history_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                dayName TEXT NOT NULL,
                workoutName TEXT NOT NULL,
                completedExercisesCount INTEGER NOT NULL,
                totalExercisesCount INTEGER NOT NULL,
                durationMinutes INTEGER NOT NULL,
                notes TEXT,
                completedAt TEXT NOT NULL
              )
            ''');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS workout_sessions (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                date TEXT NOT NULL,
                dayName TEXT NOT NULL,
                workoutTemplateId TEXT,
                workoutVersion INTEGER NOT NULL,
                workoutName TEXT NOT NULL,
                muscleGroup TEXT NOT NULL,
                startTime TEXT NOT NULL,
                endTime TEXT,
                durationMinutes INTEGER NOT NULL,
                exercises TEXT NOT NULL,
                status TEXT NOT NULL,
                comments TEXT,
                createdAt TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS personal_records (
                exerciseName TEXT PRIMARY KEY,
                heaviestWeightKg REAL NOT NULL,
                heaviestWeightDate TEXT,
                maxReps INTEGER NOT NULL,
                maxRepsWeightKg REAL NOT NULL,
                maxRepsDate TEXT,
                maxDurationSeconds INTEGER NOT NULL,
                maxDurationDate TEXT
              )
            ''');
          } catch (_) {}
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        targetDays INTEGER NOT NULL,
        currentStreak INTEGER NOT NULL,
        lastCompletedDate TEXT,
        notifyUser INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE deleted_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        streakAchieved INTEGER NOT NULL,
        targetDays INTEGER NOT NULL,
        apologyLetter TEXT NOT NULL,
        deletedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        isCredit INTEGER DEFAULT 0,
        partyName TEXT DEFAULT '',
        paymentMethod TEXT DEFAULT 'UPI / Card',
        isRecurring INTEGER DEFAULT 0,
        notes TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE study_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        desc TEXT NOT NULL,
        timeSpent TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mealSlot TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        timeHour INTEGER NOT NULL,
        timeMinute INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealType TEXT NOT NULL,
        date TEXT NOT NULL,
        photoPath TEXT,
        photoBase64 TEXT,
        foodItemsJson TEXT NOT NULL,
        totalCalories REAL NOT NULL,
        totalProtein REAL NOT NULL,
        totalCarbs REAL NOT NULL,
        totalFat REAL NOT NULL,
        totalFiber REAL NOT NULL,
        notes TEXT,
        isAiAnalyzed INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_days (
        dayName TEXT PRIMARY KEY,
        workoutName TEXT NOT NULL,
        targetMuscleGroup TEXT NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        status TEXT NOT NULL,
        exercisesJson TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE body_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        photoBase64 TEXT,
        photoPath TEXT,
        weightKg REAL,
        note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE physique_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        unit TEXT NOT NULL,
        chest REAL,
        waist REAL,
        abdomen REAL,
        hip REAL,
        neck REAL,
        leftArm REAL,
        rightArm REAL,
        leftThigh REAL,
        rightThigh REAL,
        comment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE weekly_weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weekKey TEXT NOT NULL,
        weightKg REAL NOT NULL,
        comment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_history_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        dayName TEXT NOT NULL,
        workoutName TEXT NOT NULL,
        completedExercisesCount INTEGER NOT NULL,
        totalExercisesCount INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        notes TEXT,
        completedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        dayName TEXT NOT NULL,
        workoutTemplateId TEXT,
        workoutVersion INTEGER NOT NULL,
        workoutName TEXT NOT NULL,
        muscleGroup TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        durationMinutes INTEGER NOT NULL,
        exercises TEXT NOT NULL,
        status TEXT NOT NULL,
        comments TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personal_records (
        exerciseName TEXT PRIMARY KEY,
        heaviestWeightKg REAL NOT NULL,
        heaviestWeightDate TEXT,
        maxReps INTEGER NOT NULL,
        maxRepsWeightKg REAL NOT NULL,
        maxRepsDate TEXT,
        maxDurationSeconds INTEGER NOT NULL,
        maxDurationDate TEXT
      )
    ''');
  }

  // --- GOALS CRUD ---
  Future<void> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    if (db == null) {
      _inMemoryGoals.removeWhere((e) => e['id'] == goal['id']);
      _inMemoryGoals.add(goal);
      return;
    }
    await db.insert('goals', goal, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryGoals);
    return await db.query('goals');
  }

  Future<List<Map<String, dynamic>>> getGoals() => fetchGoals();

  Future<void> updateGoal(String id, int streak, String? lastDate) async {
    final db = await database;
    if (db == null) {
      final index = _inMemoryGoals.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _inMemoryGoals[index]['currentStreak'] = streak;
        _inMemoryGoals[index]['lastCompletedDate'] = lastDate;
      }
      return;
    }
    await db.update(
      'goals',
      {'currentStreak': streak, 'lastCompletedDate': lastDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateGoalNotification(String id, bool notifyUser) async {
    final db = await database;
    if (db == null) {
      final index = _inMemoryGoals.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _inMemoryGoals[index]['notifyUser'] = notifyUser ? 1 : 0;
      }
      return;
    }
    await db.update(
      'goals',
      {'notifyUser': notifyUser ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    if (db == null) {
      _inMemoryGoals.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // --- APOLOGY ARCHIVE CRUD ---
  Future<void> insertDeletedGoal(Map<String, dynamic> record) async {
    final db = await database;
    if (db == null) {
      _inMemoryDeleted.insert(0, record);
      return;
    }
    await db.insert('deleted_goals', record);
  }

  Future<List<Map<String, dynamic>>> fetchDeletedGoals() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryDeleted);
    return await db.query('deleted_goals', orderBy: 'deletedAt DESC');
  }

  Future<List<Map<String, dynamic>>> getDeletedGoals() => fetchDeletedGoals();

  // --- EXPENSES CRUD ---
  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    if (db == null) {
      final newMap = Map<String, dynamic>.from(expense);
      newMap['id'] = _inMemoryExpenses.length + 1;
      _inMemoryExpenses.insert(0, newMap);
      return;
    }
    await db.insert('expenses', expense);
  }

  Future<void> addExpense(Map<String, dynamic> expense) => insertExpense(expense);

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryExpenses);
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getExpenses() => fetchExpenses();

  Future<void> updateExpense(int id, Map<String, dynamic> updated) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryExpenses.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _inMemoryExpenses[idx] = {..._inMemoryExpenses[idx], ...updated};
      }
      return;
    }
    await db.update('expenses', updated, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryExpenses.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- STUDY LOGS CRUD ---
  Future<void> insertStudyLog(Map<String, dynamic> log) async {
    final db = await database;
    if (db == null) {
      _inMemoryStudy.insert(0, log);
      return;
    }
    await db.insert('study_logs', log);
  }

  Future<List<Map<String, dynamic>>> fetchStudyLogs() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryStudy);
    return await db.query('study_logs', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getStudyLogs() => fetchStudyLogs();
  Future<void> addStudyLog(Map<String, dynamic> log) => insertStudyLog(log);

  Future<void> deleteStudyLog(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryStudy.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('study_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- FOOD LOGS CRUD (Legacy & Quick Log) ---
  Future<int> insertFoodLog(Map<String, dynamic> log) async {
    final db = await database;
    if (db == null) {
      final newMap = Map<String, dynamic>.from(log);
      newMap['id'] = _inMemoryFood.length + 1;
      _inMemoryFood.insert(0, newMap);
      return newMap['id'];
    }
    return await db.insert('food_logs', log);
  }

  Future<int> addFoodLog(Map<String, dynamic> log) => insertFoodLog(log);

  Future<List<Map<String, dynamic>>> fetchFoodLogs() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryFood);
    return await db.query('food_logs', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getFoodLogs() => fetchFoodLogs();

  Future<void> deleteFoodLog(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryFood.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- MEALS CRUD (Photo AI & Structured Food Records) ---
  Future<int> insertMeal(MealRecord meal) async {
    final map = meal.toMap();
    final db = await database;
    if (db == null) {
      final newId = _inMemoryMeals.length + 1;
      map['id'] = newId;
      _inMemoryMeals.insert(0, map);
      return newId;
    }
    return await db.insert('meals', map);
  }

  Future<List<MealRecord>> fetchMeals() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryMeals);
    } else {
      maps = await db.query('meals', orderBy: 'date DESC');
    }
    return maps.map((e) => MealRecord.fromMap(e)).toList();
  }

  Future<List<MealRecord>> getMeals() => fetchMeals();

  Future<void> updateMeal(MealRecord meal) async {
    final map = meal.toMap();
    final db = await database;
    if (db == null) {
      final idx = _inMemoryMeals.indexWhere((e) => e['id'] == meal.id);
      if (idx != -1) {
        _inMemoryMeals[idx] = map;
      }
      return;
    }
    await db.update('meals', map, where: 'id = ?', whereArgs: [meal.id]);
  }

  Future<void> deleteMeal(dynamic id) async {
    final db = await database;
    final idStr = id.toString();
    if (db == null) {
      _inMemoryMeals.removeWhere((e) => e['id'].toString() == idStr);
      return;
    }
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  // --- 7-DAY WORKOUT PLANS CRUD ---
  Future<void> saveWorkoutDay(WorkoutDayPlan plan) async {
    final map = plan.toMap();
    final db = await database;
    if (db == null) {
      _inMemoryWorkouts[plan.dayName] = map;
      return;
    }
    await db.insert('workout_days', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveWorkoutPlan(WorkoutDayPlan plan) => saveWorkoutDay(plan);

  Future<List<WorkoutDayPlan>> fetchWorkoutPlans() async {
    final db = await database;
    List<Map<String, dynamic>> maps = [];
    if (db == null) {
      if (_inMemoryWorkouts.isEmpty) {
        final defaults = WorkoutPresetSplits.getDefaultWeeklyPlan();
        for (var p in defaults) {
          _inMemoryWorkouts[p.dayName] = p.toMap();
        }
      }
      maps = _inMemoryWorkouts.values.toList();
    } else {
      maps = await db.query('workout_days');
      if (maps.isEmpty) {
        final defaults = WorkoutPresetSplits.getDefaultWeeklyPlan();
        for (var p in defaults) {
          await db.insert('workout_days', p.toMap());
        }
        maps = await db.query('workout_days');
      }
    }

    final list = maps.map((e) => WorkoutDayPlan.fromMap(e)).toList();
    const order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    list.sort((a, b) => order.indexOf(a.dayName).compareTo(order.indexOf(b.dayName)));
    return list;
  }

  Future<List<WorkoutDayPlan>> getWorkoutPlans() => fetchWorkoutPlans();

  // --- BODY PHOTOS CRUD ---
  Future<int> insertBodyPhoto(BodyPhotoEntry photo) async {
    final map = photo.toMap();
    final db = await database;
    if (db == null) {
      final newId = _inMemoryBodyPhotos.length + 1;
      map['id'] = newId;
      _inMemoryBodyPhotos.insert(0, map);
      return newId;
    }
    return await db.insert('body_photos', map);
  }

  Future<List<BodyPhotoEntry>> fetchBodyPhotos() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryBodyPhotos);
    } else {
      maps = await db.query('body_photos', orderBy: 'date DESC, id DESC');
    }
    return maps.map((e) => BodyPhotoEntry.fromMap(e)).toList();
  }

  Future<void> updateBodyPhotoNote(int id, String note) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryBodyPhotos.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _inMemoryBodyPhotos[idx]['note'] = note;
      }
      return;
    }
    await db.update('body_photos', {'note': note}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBodyPhoto(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryBodyPhotos.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('body_photos', where: 'id = ?', whereArgs: [id]);
  }

  // --- PHYSIQUE MEASUREMENTS CRUD ---
  Future<int> insertPhysiqueMeasurement(PhysiqueMeasurement pm) async {
    final map = pm.toMap();
    final db = await database;
    if (db == null) {
      final newId = _inMemoryPhysique.length + 1;
      map['id'] = newId;
      _inMemoryPhysique.insert(0, map);
      return newId;
    }
    return await db.insert('physique_measurements', map);
  }

  Future<List<PhysiqueMeasurement>> fetchPhysiqueMeasurements() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryPhysique);
    } else {
      maps = await db.query('physique_measurements', orderBy: 'date DESC, id DESC');
    }
    return maps.map((e) => PhysiqueMeasurement.fromMap(e)).toList();
  }

  Future<void> deletePhysiqueMeasurement(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryPhysique.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('physique_measurements', where: 'id = ?', whereArgs: [id]);
  }

  // --- WEEKLY WEIGHT CHECK-INS CRUD ---
  Future<int> insertWeeklyWeight(WeeklyWeightEntry entry) async {
    final map = entry.toMap();
    final db = await database;
    if (db == null) {
      _inMemoryWeeklyWeights.removeWhere((e) => e['weekKey'] == entry.weekKey);
      final newId = _inMemoryWeeklyWeights.length + 1;
      map['id'] = newId;
      _inMemoryWeeklyWeights.insert(0, map);
      return newId;
    }
    await db.delete('weekly_weight_entries', where: 'weekKey = ?', whereArgs: [entry.weekKey]);
    return await db.insert('weekly_weight_entries', map);
  }

  Future<List<WeeklyWeightEntry>> fetchWeeklyWeights() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryWeeklyWeights);
    } else {
      maps = await db.query('weekly_weight_entries', orderBy: 'date DESC, id DESC');
    }
    return maps.map((e) => WeeklyWeightEntry.fromMap(e)).toList();
  }

  Future<void> deleteWeeklyWeight(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryWeeklyWeights.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('weekly_weight_entries', where: 'id = ?', whereArgs: [id]);
  }

  // --- WORKOUT HISTORY LOGS CRUD ---
  Future<int> insertWorkoutHistoryLog(WorkoutHistoryLog log) async {
    final map = log.toMap();
    final db = await database;
    if (db == null) {
      final newId = _inMemoryWorkoutLogs.length + 1;
      map['id'] = newId;
      _inMemoryWorkoutLogs.insert(0, map);
      return newId;
    }
    return await db.insert('workout_history_logs', map);
  }

  Future<List<WorkoutHistoryLog>> fetchWorkoutHistoryLogs() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryWorkoutLogs);
    } else {
      maps = await db.query('workout_history_logs', orderBy: 'date DESC, id DESC');
    }
    return maps.map((e) => WorkoutHistoryLog.fromMap(e)).toList();
  }

  // --- WORKOUT SESSIONS (Immutable Historical Executed Logs) ---
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final map = session.toMap();
    final db = await database;
    if (db == null) {
      _inMemoryWorkoutSessions.removeWhere((e) => e['id'] == session.id);
      _inMemoryWorkoutSessions.insert(0, map);
    } else {
      await db.insert('workout_sessions', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Automatically update Personal Records
    for (final ex in session.exercises) {
      for (final s in ex.actualSets) {
        if (s.isCompleted) {
          await _updatePersonalRecordIfBetter(
            exerciseName: ex.exerciseName,
            weightKg: s.weightKg,
            reps: s.reps,
            durationSeconds: s.durationSeconds,
            date: session.startTime,
          );
        }
      }
    }
  }

  Future<List<WorkoutSession>> getWorkoutSessions() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List.from(_inMemoryWorkoutSessions);
    } else {
      maps = await db.query('workout_sessions', orderBy: 'date DESC, createdAt DESC');
    }
    return maps.map((e) => WorkoutSession.fromMap(e)).toList();
  }

  Future<List<WorkoutSession>> getWorkoutSessionsForExercise(String exerciseName) async {
    final all = await getWorkoutSessions();
    return all.where((s) => s.exercises.any((e) => e.exerciseName.toLowerCase() == exerciseName.toLowerCase())).toList();
  }

  Future<WorkoutSession?> getLatestWorkoutSessionForExercise(String exerciseName) async {
    final list = await getWorkoutSessionsForExercise(exerciseName);
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<Map<String, PersonalRecord>> getPersonalRecords() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = _inMemoryPersonalRecords.values.toList();
    } else {
      maps = await db.query('personal_records');
    }
    final res = <String, PersonalRecord>{};
    for (var m in maps) {
      final pr = PersonalRecord.fromMap(m);
      res[pr.exerciseName] = pr;
    }
    return res;
  }

  Future<void> savePersonalRecord(PersonalRecord pr) async {
    final map = pr.toMap();
    final db = await database;
    if (db == null) {
      _inMemoryPersonalRecords[pr.exerciseName] = map;
      return;
    }
    await db.insert('personal_records', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _updatePersonalRecordIfBetter({
    required String exerciseName,
    required double weightKg,
    required int reps,
    required int durationSeconds,
    required DateTime date,
  }) async {
    final records = await getPersonalRecords();
    final existing = records[exerciseName];

    double newHeaviestWeight = existing?.heaviestWeightKg ?? 0.0;
    DateTime? newHeaviestDate = existing?.heaviestWeightDate;
    int newMaxReps = existing?.maxReps ?? 0;
    double newMaxRepsWeight = existing?.maxRepsWeightKg ?? 0.0;
    DateTime? newMaxRepsDate = existing?.maxRepsDate;
    int newMaxDuration = existing?.maxDurationSeconds ?? 0;
    DateTime? newMaxDurationDate = existing?.maxDurationDate;

    bool changed = false;
    if (weightKg > newHeaviestWeight) {
      newHeaviestWeight = weightKg;
      newHeaviestDate = date;
      changed = true;
    }
    if (reps > newMaxReps) {
      newMaxReps = reps;
      newMaxRepsWeight = weightKg;
      newMaxRepsDate = date;
      changed = true;
    }
    if (durationSeconds > newMaxDuration) {
      newMaxDuration = durationSeconds;
      newMaxDurationDate = date;
      changed = true;
    }

    if (changed || existing == null) {
      final updated = PersonalRecord(
        exerciseName: exerciseName,
        heaviestWeightKg: newHeaviestWeight,
        heaviestWeightDate: newHeaviestDate ?? date,
        maxReps: newMaxReps,
        maxRepsWeightKg: newMaxRepsWeight,
        maxRepsDate: newMaxRepsDate ?? date,
        maxDurationSeconds: newMaxDuration,
        maxDurationDate: newMaxDurationDate ?? date,
      );
      await savePersonalRecord(updated);
    }
  }
}