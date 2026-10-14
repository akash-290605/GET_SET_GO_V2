import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/study_english_models.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  final List<Map<String, dynamic>> _inMemoryGoals = [];
  final List<Map<String, dynamic>> _inMemoryDeleted = [];
  final List<Map<String, dynamic>> _inMemoryExpenses = [];
  final List<Map<String, dynamic>> _inMemoryStudy = [];
  final List<Map<String, dynamic>> _inMemorySpeakingRecords = [];
  final List<Map<String, dynamic>> _inMemoryLiveConversations = [];

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
      version: 6,
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
        if (oldVersion < 6) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS speaking_records (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                topic TEXT NOT NULL,
                durationSeconds INTEGER NOT NULL,
                transcript TEXT NOT NULL,
                correctionsJson TEXT NOT NULL,
                vocabularySuggestionsJson TEXT NOT NULL,
                fluencyScore REAL NOT NULL,
                wordsCount INTEGER NOT NULL,
                wordsPerMinute INTEGER NOT NULL,
                fillerWordsCount INTEGER NOT NULL,
                fillerDetailsJson TEXT NOT NULL,
                longPausesCount INTEGER NOT NULL,
                pronunciationTipsJson TEXT NOT NULL,
                whatYouDidWellJson TEXT NOT NULL,
                improveTheseJson TEXT NOT NULL,
                betterVersion TEXT NOT NULL,
                isVideoSaved INTEGER NOT NULL,
                videoPath TEXT,
                createdAt TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS live_conversations (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                date TEXT NOT NULL,
                topic TEXT NOT NULL,
                durationSeconds INTEGER NOT NULL,
                mode TEXT NOT NULL,
                level TEXT NOT NULL,
                isCorrectionEnabled INTEGER NOT NULL,
                messagesJson TEXT NOT NULL,
                wordsSpokenApprox INTEGER NOT NULL,
                commonFillersJson TEXT NOT NULL,
                grammarIssuesJson TEXT NOT NULL,
                newVocabularyJson TEXT NOT NULL,
                recommendedPractice TEXT NOT NULL,
                whatToPracticeNext TEXT NOT NULL,
                createdAt TEXT NOT NULL
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
      CREATE TABLE speaking_records (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        topic TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        transcript TEXT NOT NULL,
        correctionsJson TEXT NOT NULL,
        vocabularySuggestionsJson TEXT NOT NULL,
        fluencyScore REAL NOT NULL,
        wordsCount INTEGER NOT NULL,
        wordsPerMinute INTEGER NOT NULL,
        fillerWordsCount INTEGER NOT NULL,
        fillerDetailsJson TEXT NOT NULL,
        longPausesCount INTEGER NOT NULL,
        pronunciationTipsJson TEXT NOT NULL,
        whatYouDidWellJson TEXT NOT NULL,
        improveTheseJson TEXT NOT NULL,
        betterVersion TEXT NOT NULL,
        isVideoSaved INTEGER NOT NULL,
        videoPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE live_conversations (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        topic TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        mode TEXT NOT NULL,
        level TEXT NOT NULL,
        isCorrectionEnabled INTEGER NOT NULL,
        messagesJson TEXT NOT NULL,
        wordsSpokenApprox INTEGER NOT NULL,
        commonFillersJson TEXT NOT NULL,
        grammarIssuesJson TEXT NOT NULL,
        newVocabularyJson TEXT NOT NULL,
        recommendedPractice TEXT NOT NULL,
        whatToPracticeNext TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ================= STRICT DISCIPLINE GOALS CRUD =================

  Future<void> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    if (db == null) {
      _inMemoryGoals.removeWhere((g) => g['id'] == goal['id']);
      _inMemoryGoals.add(Map<String, dynamic>.from(goal));
      return;
    }
    await db.insert('goals', goal, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final db = await database;
    if (db == null) return List<Map<String, dynamic>>.from(_inMemoryGoals);
    return await db.query('goals');
  }

  Future<List<Map<String, dynamic>>> getGoals() => fetchGoals();

  Future<void> updateGoal(String id, int streak, String? lastDate) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryGoals.indexWhere((g) => g['id'] == id);
      if (idx != -1) {
        _inMemoryGoals[idx]['currentStreak'] = streak;
        _inMemoryGoals[idx]['lastCompletedDate'] = lastDate;
      }
      return;
    }
    await db.update(
      'goals',
      {
        'currentStreak': streak,
        'lastCompletedDate': lastDate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateGoalNotification(String id, bool notifyUser) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryGoals.indexWhere((g) => g['id'] == id);
      if (idx != -1) {
        _inMemoryGoals[idx]['notifyUser'] = notifyUser ? 1 : 0;
      }
      return;
    }
    await db.update(
      'goals',
      {
        'notifyUser': notifyUser ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    if (db == null) {
      _inMemoryGoals.removeWhere((g) => g['id'] == id);
      return;
    }
    await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertDeletedGoal(Map<String, dynamic> record) async {
    final db = await database;
    if (db == null) {
      _inMemoryDeleted.add(Map<String, dynamic>.from(record));
      return;
    }
    await db.insert('deleted_goals', record);
  }

  Future<List<Map<String, dynamic>>> fetchDeletedGoals() async {
    final db = await database;
    if (db == null) return List<Map<String, dynamic>>.from(_inMemoryDeleted);
    return await db.query('deleted_goals', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getDeletedGoals() => fetchDeletedGoals();

  // ================= EXPENSES & FINANCE CRUD =================

  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    if (db == null) {
      final copy = Map<String, dynamic>.from(expense);
      copy['id'] = _inMemoryExpenses.length + 1;
      _inMemoryExpenses.add(copy);
      return;
    }
    await db.insert('expenses', expense);
  }

  Future<void> addExpense(Map<String, dynamic> expense) => insertExpense(expense);

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final db = await database;
    if (db == null) return List<Map<String, dynamic>>.from(_inMemoryExpenses);
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getExpenses() => fetchExpenses();

  Future<void> updateExpense(int id, Map<String, dynamic> updated) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryExpenses.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _inMemoryExpenses[idx] = Map<String, dynamic>.from(updated);
        _inMemoryExpenses[idx]['id'] = id;
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

  // ================= STUDY & ACADEMICS CRUD =================

  Future<void> insertStudyLog(Map<String, dynamic> log) async {
    final db = await database;
    if (db == null) {
      final copy = Map<String, dynamic>.from(log);
      copy['id'] = _inMemoryStudy.length + 1;
      _inMemoryStudy.add(copy);
      return;
    }
    await db.insert('study_logs', log);
  }

  Future<List<Map<String, dynamic>>> fetchStudyLogs() async {
    final db = await database;
    if (db == null) return List<Map<String, dynamic>>.from(_inMemoryStudy);
    return await db.query('study_logs', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getStudyLogs() => fetchStudyLogs();
  Future<void> addStudyLog(Map<String, dynamic> log) => insertStudyLog(log);

  Future<void> deleteStudyLog(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryStudy.removeWhere((s) => s['id'] == id);
      return;
    }
    await db.delete('study_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ENGLISH MASTERY: SPEAKING RECORDS & CONVERSATIONS =================

  Future<void> insertSpeakingRecord(SpeakingPracticeRecord record) async {
    final db = await database;
    if (db == null) {
      _inMemorySpeakingRecords.removeWhere((r) => r['id'] == record.id);
      _inMemorySpeakingRecords.add(record.toMap());
      return;
    }
    await db.insert('speaking_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SpeakingPracticeRecord>> fetchSpeakingRecords() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List<Map<String, dynamic>>.from(_inMemorySpeakingRecords);
    } else {
      maps = await db.query('speaking_records', orderBy: 'createdAt DESC');
    }
    return maps.map((m) => SpeakingPracticeRecord.fromMap(m)).toList();
  }

  Future<void> deleteSpeakingRecord(String id) async {
    final db = await database;
    if (db == null) {
      _inMemorySpeakingRecords.removeWhere((r) => r['id'] == id);
      return;
    }
    await db.delete('speaking_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertLiveConversation(LiveConversationSession session) async {
    final db = await database;
    if (db == null) {
      _inMemoryLiveConversations.removeWhere((s) => s['id'] == session.id);
      _inMemoryLiveConversations.add(session.toMap());
      return;
    }
    await db.insert('live_conversations', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LiveConversationSession>> fetchLiveConversations() async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (db == null) {
      maps = List<Map<String, dynamic>>.from(_inMemoryLiveConversations);
    } else {
      maps = await db.query('live_conversations', orderBy: 'createdAt DESC');
    }
    return maps.map((m) => LiveConversationSession.fromMap(m)).toList();
  }

  Future<void> deleteLiveConversation(String id) async {
    final db = await database;
    if (db == null) {
      _inMemoryLiveConversations.removeWhere((s) => s['id'] == id);
      return;
    }
    await db.delete('live_conversations', where: 'id = ?', whereArgs: [id]);
  }
}