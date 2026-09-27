import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_english_models.dart';

class StudyEnglishService extends ChangeNotifier {
  static final StudyEnglishService instance = StudyEnglishService._internal();
  StudyEnglishService._internal();

  static const String _subjectsKey = 'gsg_study_subjects_v1';
  static const String _plannerKey = 'gsg_study_planner_v1';
  static const String _vocabularyKey = 'gsg_english_vocab_v1';
  static const String _grammarStatsKey = 'gsg_grammar_stats_v1';

  List<StudySubject> _subjects = [];
  List<StudyPlannerSession> _plannerSessions = [];
  List<EnglishVocabularyWord> _vocabularyList = [];
  int _grammarQuizzesTaken = 0;
  int _grammarCorrectAnswers = 0;
  final int _dailyStudyTargetMinutes = 120;
  final int _studyStreakDays = 5;

  List<StudySubject> get subjects => _subjects;
  List<StudyPlannerSession> get plannerSessions => _plannerSessions;
  List<EnglishVocabularyWord> get vocabularyList => _vocabularyList;
  int get grammarQuizzesTaken => _grammarQuizzesTaken;
  int get grammarCorrectAnswers => _grammarCorrectAnswers;
  int get dailyStudyTargetMinutes => _dailyStudyTargetMinutes;
  int get studyStreakDays => _studyStreakDays;

  double get grammarScorePercentage =>
      _grammarQuizzesTaken > 0 ? (_grammarCorrectAnswers / _grammarQuizzesTaken) * 100 : 85.0;

  int get totalCompletedTopics => _subjects.fold(
      0, (sum, s) => sum + s.topics.where((t) => t.isCompleted).length);

  int get totalPendingTopics => _subjects.fold(
      0, (sum, s) => sum + s.topics.where((t) => !t.isCompleted).length);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Subjects
      final subStr = prefs.getString(_subjectsKey);
      if (subStr != null) {
        final list = json.decode(subStr) as List<dynamic>;
        _subjects = list.map((e) => StudySubject.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _subjects = _getDefaultSubjects();
        await saveSubjects();
      }

      // 2. 7-Day Study Planner
      final planStr = prefs.getString(_plannerKey);
      if (planStr != null) {
        final list = json.decode(planStr) as List<dynamic>;
        _plannerSessions = list.map((e) => StudyPlannerSession.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _plannerSessions = _getDefaultPlannerSessions();
        await savePlannerSessions();
      }

      // 3. Vocabulary
      final vocabStr = prefs.getString(_vocabularyKey);
      if (vocabStr != null) {
        final list = json.decode(vocabStr) as List<dynamic>;
        _vocabularyList = list.map((e) => EnglishVocabularyWord.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _vocabularyList = _getDefaultVocabulary();
        await saveVocabulary();
      }

      // 4. Grammar stats
      final gStats = prefs.getString(_grammarStatsKey);
      if (gStats != null) {
        final map = json.decode(gStats) as Map<String, dynamic>;
        _grammarQuizzesTaken = map['taken'] ?? 0;
        _grammarCorrectAnswers = map['correct'] ?? 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('StudyEnglishService init error: $e');
    }
  }

  // --- Subjects & Topics CRUD ---
  Future<void> saveSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _subjects.map((s) => s.toMap()).toList();
      await prefs.setString(_subjectsKey, json.encode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving subjects: $e');
    }
  }

  Future<void> addSubject(StudySubject subject) async {
    _subjects.add(subject);
    await saveSubjects();
  }

  Future<void> updateSubject(StudySubject subject) async {
    final idx = _subjects.indexWhere((s) => s.id == subject.id);
    if (idx != -1) {
      _subjects[idx] = subject;
      await saveSubjects();
    }
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await saveSubjects();
  }

  Future<void> toggleTopicCompletion(String subjectId, String topicId) async {
    final s = _subjects.firstWhere((s) => s.id == subjectId);
    final t = s.topics.firstWhere((t) => t.id == topicId);
    t.isCompleted = !t.isCompleted;
    t.completedAt = t.isCompleted ? DateTime.now() : null;
    await saveSubjects();
  }

  // --- 7-Day Study Planner CRUD ---
  Future<void> savePlannerSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _plannerSessions.map((p) => p.toMap()).toList();
      await prefs.setString(_plannerKey, json.encode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving planner sessions: $e');
    }
  }

  Future<void> addPlannerSession(StudyPlannerSession session) async {
    _plannerSessions.add(session);
    await savePlannerSessions();
  }

  Future<void> updatePlannerSession(StudyPlannerSession session) async {
    final idx = _plannerSessions.indexWhere((p) => p.id == session.id);
    if (idx != -1) {
      _plannerSessions[idx] = session;
      await savePlannerSessions();
    }
  }

  Future<void> deletePlannerSession(String id) async {
    _plannerSessions.removeWhere((p) => p.id == id);
    await savePlannerSessions();
  }

  Future<void> updateSessionStatus(String id, StudySessionStatus status) async {
    final session = _plannerSessions.firstWhere((p) => p.id == id);
    session.status = status;
    await savePlannerSessions();
  }

  // --- Vocabulary CRUD ---
  Future<void> saveVocabulary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _vocabularyList.map((v) => v.toMap()).toList();
      await prefs.setString(_vocabularyKey, json.encode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving vocabulary: $e');
    }
  }

  Future<void> addVocabulary(EnglishVocabularyWord word) async {
    _vocabularyList.insert(0, word);
    await saveVocabulary();
  }

  Future<void> updateVocabularyStatus(String id, VocabularyStatus status) async {
    final word = _vocabularyList.firstWhere((v) => v.id == id);
    word.status = status;
    await saveVocabulary();
  }

  Future<void> deleteVocabulary(String id) async {
    _vocabularyList.removeWhere((v) => v.id == id);
    await saveVocabulary();
  }

  // --- Grammar Quiz Stats ---
  Future<void> recordGrammarAnswer(bool isCorrect) async {
    _grammarQuizzesTaken++;
    if (isCorrect) _grammarCorrectAnswers++;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_grammarStatsKey, json.encode({
        'taken': _grammarQuizzesTaken,
        'correct': _grammarCorrectAnswers,
      }));
    } catch (_) {}
  }

  // --- Defaults ---
  List<StudySubject> _getDefaultSubjects() {
    return [
      StudySubject(
        id: 'sub_cs',
        name: 'Computer Science & Algorithms',
        colorValue: 0xFF8B5CF6,
        priority: StudyPriority.high,
        notes: 'Core focus: Graph algorithms, Dynamic Programming, System Design',
        topics: [
          StudyTopic(id: 't_cs1', title: 'Binary Search Trees & Red-Black Trees', estimatedMinutes: 60, isCompleted: true),
          StudyTopic(id: 't_cs2', title: 'Dynamic Programming (Knapsack & LCS)', estimatedMinutes: 90, isCompleted: true),
          StudyTopic(id: 't_cs3', title: 'Graph Traversal (Dijkstra & BFS/DFS)', estimatedMinutes: 75, isCompleted: false),
          StudyTopic(id: 't_cs4', title: 'Distributed Systems & Microservices', estimatedMinutes: 90, isCompleted: false),
        ],
      ),
      StudySubject(
        id: 'sub_math',
        name: 'Linear Algebra & Statistics',
        colorValue: 0xFF06B6D4,
        priority: StudyPriority.high,
        notes: 'Key for Machine Learning & Data Analytics',
        topics: [
          StudyTopic(id: 't_m1', title: 'Matrix Eigenvalues & Eigenvectors', estimatedMinutes: 60, isCompleted: true),
          StudyTopic(id: 't_m2', title: 'Probability Distributions & Bayes Theorem', estimatedMinutes: 60, isCompleted: false),
          StudyTopic(id: 't_m3', title: 'Multivariate Calculus & Gradients', estimatedMinutes: 45, isCompleted: false),
        ],
      ),
      StudySubject(
        id: 'sub_eng',
        name: 'English Fluency & Communication',
        colorValue: 0xFF10B981,
        priority: StudyPriority.medium,
        notes: 'Focus on Professional English, Speaking and Technical Writing',
        topics: [
          StudyTopic(id: 't_e1', title: 'Daily Spoken English Practice', estimatedMinutes: 30, isCompleted: true),
          StudyTopic(id: 't_e2', title: 'Professional Email & Report Writing', estimatedMinutes: 45, isCompleted: false),
          StudyTopic(id: 't_e3', title: 'Complex Tenses & Active Voice', estimatedMinutes: 40, isCompleted: false),
        ],
      ),
    ];
  }

  List<StudyPlannerSession> _getDefaultPlannerSessions() {
    return [
      StudyPlannerSession(
        id: 'plan_mon',
        dayName: 'Monday',
        subjectName: 'Computer Science',
        topicTitle: 'Dynamic Programming & Memoization',
        durationMinutes: 90,
        priority: StudyPriority.high,
        status: StudySessionStatus.completed,
      ),
      StudyPlannerSession(
        id: 'plan_tue',
        dayName: 'Tuesday',
        subjectName: 'Linear Algebra',
        topicTitle: 'Matrix Decomposition & SVD',
        durationMinutes: 60,
        priority: StudyPriority.high,
        status: StudySessionStatus.completed,
      ),
      StudyPlannerSession(
        id: 'plan_wed',
        dayName: 'Wednesday',
        subjectName: 'English Communication',
        topicTitle: 'Speech Practice & Tech Discussion',
        durationMinutes: 45,
        priority: StudyPriority.medium,
        status: StudySessionStatus.inProgress,
      ),
      StudyPlannerSession(
        id: 'plan_thu',
        dayName: 'Thursday',
        subjectName: 'Computer Science',
        topicTitle: 'Graph Algorithms & Shortest Path',
        durationMinutes: 90,
        priority: StudyPriority.high,
        status: StudySessionStatus.planned,
      ),
      StudyPlannerSession(
        id: 'plan_fri',
        dayName: 'Friday',
        subjectName: 'Statistics',
        topicTitle: 'Hypothesis Testing & Regression',
        durationMinutes: 60,
        priority: StudyPriority.medium,
        status: StudySessionStatus.planned,
      ),
      StudyPlannerSession(
        id: 'plan_sat',
        dayName: 'Saturday',
        subjectName: 'System Design',
        topicTitle: 'Caching & Database Sharding',
        durationMinutes: 120,
        priority: StudyPriority.high,
        status: StudySessionStatus.planned,
      ),
      StudyPlannerSession(
        id: 'plan_sun',
        dayName: 'Sunday',
        subjectName: 'Weekly Revision',
        topicTitle: 'Problem Solving & Mock Interview',
        durationMinutes: 90,
        priority: StudyPriority.medium,
        status: StudySessionStatus.planned,
      ),
    ];
  }

  List<EnglishVocabularyWord> _getDefaultVocabulary() {
    return [
      EnglishVocabularyWord(
        id: 'v1',
        word: 'Relentless',
        phonetic: '/rɪˈlɛnt.ləs/',
        partOfSpeech: 'adjective',
        meaning: 'Continuing without becoming weaker or less severe.',
        example: 'His relentless work ethic inspired the entire development team.',
        synonyms: ['Persistent', 'Untiring', 'Unyielding', 'Determined'],
        antonyms: ['Hesitant', 'Yielding', 'Lazy'],
        status: VocabularyStatus.learned,
      ),
      EnglishVocabularyWord(
        id: 'v2',
        word: 'Stoicism',
        phonetic: '/ˈstoʊ.ɪ.sɪ.zəm/',
        partOfSpeech: 'noun',
        meaning: 'The endurance of pain or hardship without display of feelings and without complaint.',
        example: 'She maintained a calm stoicism throughout the intense exam preparation.',
        synonyms: ['Fortitude', 'Equanimity', 'Resilience', 'Endurance'],
        antonyms: ['Impatience', 'Agitation', 'Weakness'],
        status: VocabularyStatus.learned,
      ),
      EnglishVocabularyWord(
        id: 'v3',
        word: 'Meticulous',
        phonetic: '/məˈtɪk.jə.ləs/',
        partOfSpeech: 'adjective',
        meaning: 'Showing great attention to detail; very careful and precise.',
        example: 'He kept meticulous records of every expense and study session.',
        synonyms: ['Precise', 'Scrupulous', 'Diligent', 'Thorough'],
        antonyms: ['Careless', 'Sloppy', 'Negligent'],
        status: VocabularyStatus.needRevision,
      ),
      EnglishVocabularyWord(
        id: 'v4',
        word: 'Articulate',
        phonetic: '/ɑːrˈtɪk.jə.leɪt/',
        partOfSpeech: 'verb / adj',
        meaning: 'Having or showing the ability to speak fluently and coherently.',
        example: 'She was able to articulate complex technical ideas clearly in the interview.',
        synonyms: ['Eloquent', 'Fluent', 'Expressive', 'Lucid'],
        antonyms: ['Inarticulate', 'Hesitant', 'Unclear'],
        status: VocabularyStatus.needRevision,
      ),
      EnglishVocabularyWord(
        id: 'v5',
        word: 'Pragmatic',
        phonetic: '/præɡˈmæt.ɪk/',
        partOfSpeech: 'adjective',
        meaning: 'Dealing with things sensibly and realistically based on practical considerations.',
        example: 'We took a pragmatic approach to optimizing our daily study and workout routines.',
        synonyms: ['Practical', 'Sensible', 'Realistic', 'Utilitarian'],
        antonyms: ['Idealistic', 'Impractical', 'Theoretical'],
        status: VocabularyStatus.difficult,
      ),
    ];
  }
}
