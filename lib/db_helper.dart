import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  final List<Map<String, dynamic>> _inMemoryGoals = [];
  final List<Map<String, dynamic>> _inMemoryDeleted = [];
  final List<Map<String, dynamic>> _inMemoryExpenses = [];
  final List<Map<String, dynamic>> _inMemoryStudy = [];
  final List<Map<String, dynamic>> _inMemoryFood = [];

  DBHelper._init();

  // Returns true if running on Web OR Flutter Test environment
  bool get isMockEnvironment => kIsWeb || (PlatformDispatcher.instance.views.isEmpty);

  Future<Database?> get database async {
    if (isMockEnvironment) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('growth_tracker.db');
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS food_logs (
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
          } catch (_) {}
        }
      },
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE goals ADD COLUMN notifyUser INTEGER DEFAULT 1');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS food_logs (
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
        } catch (_) {}
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
        date TEXT NOT NULL
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

  // --- EXPENSES CRUD ---
  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    if (db == null) {
      _inMemoryExpenses.insert(0, expense);
      return;
    }
    await db.insert('expenses', expense);
   }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryExpenses);
    return await db.query('expenses', orderBy: 'date DESC');
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

  Future<void> deleteStudyLog(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryStudy.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('study_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- FOOD LOGS CRUD ---
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

  Future<List<Map<String, dynamic>>> fetchFoodLogs() async {
    final db = await database;
    if (db == null) return List.from(_inMemoryFood);
    return await db.query('food_logs', orderBy: 'id DESC');
  }

  Future<void> deleteFoodLog(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryFood.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }
}