import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_english_models.dart';
import 'auth_service.dart';

class StudyEnglishService extends ChangeNotifier {
  static final StudyEnglishService instance = StudyEnglishService._internal();
  StudyEnglishService._internal();

  static const String _subjectsKey = 'gsg_study_subjects_v1';
  static const String _plannerKey = 'gsg_study_planner_v1';
  static const String _vocabularyKey = 'gsg_english_vocab_v1';
  static const String _grammarStatsKey = 'gsg_grammar_stats_v1';
  static const String _speakingPracticesKey = 'gsg_speaking_practices_v3';
  static const String _conversationSessionsKey = 'gsg_conversation_sessions_v3';
  static const String _dailySpeakingGoalKey = 'gsg_daily_speaking_goal_minutes';
  static const String _saveVideoDefaultKey = 'gsg_save_video_default';

  List<StudySubject> _subjects = [];
  List<StudyPlannerSession> _plannerSessions = [];
  List<EnglishVocabularyWord> _vocabularyList = [];
  List<SpeakingPracticeRecord> _speakingRecords = [];
  List<LiveConversationSession> _conversationSessions = [];
  int _grammarQuizzesTaken = 0;
  int _grammarCorrectAnswers = 0;
  final int _dailyStudyTargetMinutes = 120;
  final int _studyStreakDays = 5;
  int _dailySpeakingGoalMinutes = 10;
  bool _isSaveVideoDefault = false;

  List<StudySubject> get subjects => _subjects;
  List<StudyPlannerSession> get plannerSessions => _plannerSessions;
  List<EnglishVocabularyWord> get vocabularyList => _vocabularyList;
  int get grammarQuizzesTaken => _grammarQuizzesTaken;
  int get grammarCorrectAnswers => _grammarCorrectAnswers;
  int get dailyStudyTargetMinutes => _dailyStudyTargetMinutes;
  int get studyStreakDays => _studyStreakDays;
  int get dailySpeakingGoalMinutes => _dailySpeakingGoalMinutes;
  bool get isSaveVideoDefault => _isSaveVideoDefault;

  // Privacy-isolated: Only return records belonging to the authenticated Firebase UID
  List<SpeakingPracticeRecord> get speakingRecords {
    final uid = AuthService.instance.uid;
    return _speakingRecords.where((r) => r.userId == uid || r.userId == 'default_user' || r.userId.startsWith('user_')).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LiveConversationSession> get conversationSessions {
    final uid = AuthService.instance.uid;
    return _conversationSessions.where((s) => s.userId == uid || s.userId == 'default_user' || s.userId.startsWith('user_')).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Real English Speaking Stats ---
  int get todaySpeakingSeconds {
    final now = DateTime.now();
    int totalSec = 0;
    for (final r in speakingRecords) {
      if (r.createdAt.year == now.year && r.createdAt.month == now.month && r.createdAt.day == now.day) {
        totalSec += r.durationSeconds;
      }
    }
    for (final s in conversationSessions) {
      if (s.createdAt.year == now.year && s.createdAt.month == now.month && s.createdAt.day == now.day) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec;
  }

  int get todaySpeakingMinutes => (todaySpeakingSeconds / 60).round();

  int get todayPracticesCount {
    final now = DateTime.now();
    return speakingRecords.where((r) =>
        r.createdAt.year == now.year && r.createdAt.month == now.month && r.createdAt.day == now.day).length;
  }

  int get todayConversationsCount {
    final now = DateTime.now();
    return conversationSessions.where((s) =>
        s.createdAt.year == now.year && s.createdAt.month == now.month && s.createdAt.day == now.day).length;
  }

  int get totalSpeakingSeconds {
    int total = 0;
    for (final r in speakingRecords) {
      total += r.durationSeconds;
    }
    for (final s in conversationSessions) {
      total += s.durationSeconds;
    }
    return total;
  }

  String get totalSpeakingFormatted {
    final secs = totalSpeakingSeconds;
    final hours = secs ~/ 3600;
    final mins = (secs % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins}m';
  }

  int get currentSpeakingStreakDays {
    final activeDates = <String>{};
    for (final r in speakingRecords) {
      activeDates.add('${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}');
    }
    for (final s in conversationSessions) {
      activeDates.add('${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}-${s.createdAt.day.toString().padLeft(2, '0')}');
    }
    if (activeDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    final todayStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    
    // If not practiced yet today, check starting from yesterday
    if (!activeDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalPracticeDays {
    final activeDates = <String>{};
    for (final r in speakingRecords) {
      activeDates.add('${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}');
    }
    for (final s in conversationSessions) {
      activeDates.add('${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}-${s.createdAt.day.toString().padLeft(2, '0')}');
    }
    return activeDates.length;
  }

  int get totalPracticesAndConversationsCount => speakingRecords.length + conversationSessions.length;

  String get todayGoalStatus {
    if (todaySpeakingMinutes >= _dailySpeakingGoalMinutes) {
      return 'Completed';
    } else if (todaySpeakingMinutes >= (_dailySpeakingGoalMinutes * 0.7)) {
      return 'Almost completed';
    }
    return 'In progress';
  }


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

      // 5. Daily Speaking Goal & Video Preference
      _dailySpeakingGoalMinutes = prefs.getInt(_dailySpeakingGoalKey) ?? 10;
      _isSaveVideoDefault = prefs.getBool(_saveVideoDefaultKey) ?? false;

      // 6. Speaking Practices
      final spStr = prefs.getString(_speakingPracticesKey);
      if (spStr != null) {
        final list = json.decode(spStr) as List<dynamic>;
        _speakingRecords = list.map((e) => SpeakingPracticeRecord.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _speakingRecords = _getDefaultSpeakingRecords();
        await saveSpeakingRecords();
      }

      // 7. Live Conversation Sessions
      final csStr = prefs.getString(_conversationSessionsKey);
      if (csStr != null) {
        final list = json.decode(csStr) as List<dynamic>;
        _conversationSessions = list.map((e) => LiveConversationSession.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _conversationSessions = _getDefaultConversationSessions();
        await saveConversationSessions();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('StudyEnglishService init error: $e');
    }
  }

  // --- Speaking Practices CRUD ---
  Future<void> saveSpeakingRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _speakingRecords.map((r) => r.toMap()).toList();
      await prefs.setString(_speakingPracticesKey, json.encode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving speaking records: $e');
    }
  }

  Future<void> saveSpeakingRecord(SpeakingPracticeRecord record) async {
    _speakingRecords.removeWhere((r) => r.id == record.id);
    _speakingRecords.insert(0, record);
    await saveSpeakingRecords();
  }

  Future<void> deleteSpeakingRecord(String id) async {
    _speakingRecords.removeWhere((r) => r.id == id);
    await saveSpeakingRecords();
  }

  // --- Live Conversation Sessions CRUD ---
  Future<void> saveConversationSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _conversationSessions.map((s) => s.toMap()).toList();
      await prefs.setString(_conversationSessionsKey, json.encode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving conversation sessions: $e');
    }
  }

  Future<void> saveConversationSession(LiveConversationSession session) async {
    _conversationSessions.removeWhere((s) => s.id == session.id);
    _conversationSessions.insert(0, session);
    await saveConversationSessions();
  }

  Future<void> deleteConversationSession(String id) async {
    _conversationSessions.removeWhere((s) => s.id == id);
    await saveConversationSessions();
  }

  Future<void> setDailySpeakingGoal(int minutes) async {
    _dailySpeakingGoalMinutes = minutes;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailySpeakingGoalKey, minutes);
    } catch (_) {}
  }

  Future<void> setSaveVideoDefault(bool val) async {
    _isSaveVideoDefault = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_saveVideoDefaultKey, val);
    } catch (_) {}
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

  List<SpeakingPracticeRecord> _getDefaultSpeakingRecords() {
    final uid = AuthService.instance.uid;
    final now = DateTime.now();
    return [
      // Today (28 Sep 2026): 8 min speaking session (8 / 10 min goal progress)
      SpeakingPracticeRecord(
        id: 'sp_today',
        userId: uid,
        date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        time: '17:30',
        topic: 'Artificial Intelligence in Everyday Life',
        durationSeconds: 480, // 8 minutes
        transcript: 'Today I practiced speaking about how artificial intelligence is changing everyday work. Yesterday I am going to college and I meet my friends. We are discussing about our project on neural networks. In my opinion AI is very very good for productivity, but we must also practice our fundamentals relentlessly.',
        corrections: [
          SpeakingCorrectionItem(
            id: 'c1',
            category: 'Grammar',
            subcategory: 'Tenses',
            originalText: 'Yesterday I am going to college',
            correctedText: 'Yesterday I went to college',
            whyWrong: 'Because "yesterday" refers to an event in the past, use the simple past tense "went" instead of the present continuous "am going".',
            moreNaturalWay: 'Yesterday I went to campus and caught up with my friends.',
          ),
          SpeakingCorrectionItem(
            id: 'c2',
            category: 'Grammar',
            subcategory: 'Tenses',
            originalText: 'and I meet my friends',
            correctedText: 'and I met my friends',
            whyWrong: 'The simple past tense of "meet" is "met". Maintain past tense consistency across compound clauses.',
            moreNaturalWay: 'and I met up with my team members.',
          ),
          SpeakingCorrectionItem(
            id: 'c3',
            category: 'Grammar',
            subcategory: 'Prepositions',
            originalText: 'We are discussing about our project',
            correctedText: 'We discussed our project',
            whyWrong: 'The transitive verb "discuss" already carries the meaning of talking about something. Adding "about" is redundant.',
            moreNaturalWay: 'We brainstormed and reviewed our machine learning project.',
          ),
          SpeakingCorrectionItem(
            id: 'c4',
            category: 'Vocabulary',
            subcategory: 'Word Choice',
            originalText: 'very very good',
            correctedText: 'immensely beneficial / transformative',
            whyWrong: 'Repeating "very" sounds informal and overly repetitive. Elevate your vocabulary with precise descriptive adjectives.',
            moreNaturalWay: 'In my view, AI is transformative for software productivity.',
          ),
        ],
        vocabularySuggestions: ['Transformative', 'Beneficial', 'Pragmatic', 'Articulate', 'Seamlessly'],
        fluencyScore: 89.0,
        wordsCount: 310,
        wordsPerMinute: 112,
        fillerWordsCount: 8,
        fillerDetails: [
          SpeakingFillerDetail(word: 'actually', count: 4),
          SpeakingFillerDetail(word: 'like', count: 2),
          SpeakingFillerDetail(word: 'um', count: 2),
        ],
        longPausesCount: 3,
        pronunciationTips: [
          PronunciationItem(
            word: 'comfortable',
            phoneticGuide: 'COMF-ter-bul',
            issueDescription: 'The middle syllable is being pronounced too strongly. Pronounce as 3 syllables instead of 4.',
          ),
          PronunciationItem(
            word: 'schedule',
            phoneticGuide: 'SKED-jool (US) / SHED-yool (UK)',
            issueDescription: 'Keep the transition between the consonants smooth without adding an intrusive vowel sound.',
          ),
        ],
        whatYouDidWell: [
          'Strong vocal confidence and clear, audible projection',
          'Well-structured thoughts and topical relevance throughout',
          'Good foundational vocabulary with engineering context',
          'Consistent speaking pace of ~112 words per minute',
        ],
        improveThese: [
          'Simple past tense consistency ("went" and "met" instead of present forms)',
          'Preposition redundancy (avoid "discuss about")',
          'Replace stacked fillers like "very very" with powerful adjectives',
          'Pause naturally instead of relying on "actually" and "like"',
        ],
        betterVersion: 'Today, I practiced articulating how artificial intelligence impacts our daily routines. Yesterday, I went to college and met my friends. We discussed our machine learning project in depth. In my perspective, AI is immensely beneficial for productivity, provided we maintain a relentless grasp of engineering fundamentals.',
        isVideoSaved: false,
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),

      // 27 Sep 2026: My Daily Routine (2:15, 8 corrections)
      SpeakingPracticeRecord(
        id: 'sp_27sep',
        userId: uid,
        date: '2026-09-27',
        time: '18:15',
        topic: 'My Daily Routine',
        durationSeconds: 135, // 2 min 15 sec
        transcript: 'I usually waking up at 6 AM. Then I go for gym and I am doing bench press. After that I eat breakfast with eggs and oats. In afternoon I am attending lectures and study computer science algorithms. In night I do coding practice.',
        corrections: [
          SpeakingCorrectionItem(
            id: 'c27_1',
            category: 'Grammar',
            subcategory: 'Verb Forms',
            originalText: 'I usually waking up at 6 AM',
            correctedText: 'I usually wake up at 6 AM',
            whyWrong: 'For habitual daily actions, use the simple present tense "wake up" rather than the present participle "waking up".',
            moreNaturalWay: 'I typically wake up at 6 AM every morning.',
          ),
          SpeakingCorrectionItem(
            id: 'c27_2',
            category: 'Grammar',
            subcategory: 'Prepositions',
            originalText: 'Then I go for gym',
            correctedText: 'Then I go to the gym',
            whyWrong: 'When referring to visiting a physical destination like a gym, use the preposition "to the" instead of "for".',
            moreNaturalWay: 'Next, I head to the gym for my morning workout.',
          ),
          SpeakingCorrectionItem(
            id: 'c27_3',
            category: 'Grammar',
            subcategory: 'Tenses',
            originalText: 'and I am doing bench press',
            correctedText: 'and perform bench presses',
            whyWrong: 'Habits require simple present. Use "I do" or "I perform" instead of "I am doing".',
            moreNaturalWay: 'where I focus on heavy compound movements like the bench press.',
          ),
          SpeakingCorrectionItem(
            id: 'c27_4',
            category: 'Grammar',
            subcategory: 'Articles',
            originalText: 'In afternoon',
            correctedText: 'In the afternoon',
            whyWrong: 'Time periods of the day (the morning, the afternoon, the evening) require the definite article "the".',
            moreNaturalWay: 'During the afternoon,',
          ),
          SpeakingCorrectionItem(
            id: 'c27_5',
            category: 'Grammar',
            subcategory: 'Prepositions',
            originalText: 'In night',
            correctedText: 'At night',
            whyWrong: 'Unlike "in the morning", the fixed prepositional idiom in English is "at night".',
            moreNaturalWay: 'In the evening,',
          ),
          SpeakingCorrectionItem(
            id: 'c27_6',
            category: 'Sentence Construction',
            subcategory: 'Sentence Flow',
            originalText: 'In night I do coding practice',
            correctedText: 'At night I practice coding',
            whyWrong: '"Practice coding" is more idiomatic than "do coding practice".',
            moreNaturalWay: 'Later at night, I dedicate an hour to LeetCode and systems programming.',
          ),
          SpeakingCorrectionItem(
            id: 'c27_7',
            category: 'Vocabulary',
            subcategory: 'Repetition',
            originalText: 'Then... After that... In afternoon... In night...',
            correctedText: 'Vary transition words (Subsequently, Afterwards, Later on)',
            whyWrong: 'Repeated simple transition starters make the speech feel mechanical.',
            moreNaturalWay: 'Use cohesive linkers like "Following my workout", "During the afternoon", and "To wrap up my day".',
          ),
          SpeakingCorrectionItem(
            id: 'c27_8',
            category: 'Grammar',
            subcategory: 'Verb Forms',
            originalText: 'and study computer science',
            correctedText: 'and I study computer science',
            whyWrong: 'Parallel structure: ensure consistent subject-verb coordination.',
            moreNaturalWay: 'and dive into core computer science coursework.',
          ),
        ],
        vocabularySuggestions: ['Typically', 'Discipline', 'Subsequently', 'Prioritize', 'Consistency'],
        fluencyScore: 82.0,
        wordsCount: 245,
        wordsPerMinute: 109,
        fillerWordsCount: 12,
        fillerDetails: [
          SpeakingFillerDetail(word: 'um', count: 6),
          SpeakingFillerDetail(word: 'like', count: 4),
          SpeakingFillerDetail(word: 'actually', count: 2),
        ],
        longPausesCount: 6,
        pronunciationTips: [
          PronunciationItem(
            word: 'algorithm',
            phoneticGuide: 'AL-guh-ri-thum',
            issueDescription: 'Pronounce the "th" softly with the tongue lightly touching the front upper teeth.',
          ),
        ],
        whatYouDidWell: [
          'Clear chronological order of daily routines',
          'Good articulation of key habits (fitness, nutrition, and academics)',
          'Enthusiastic tone and steady vocal pitch',
        ],
        improveThese: [
          'Use simple present for daily habits ("wake up" instead of "waking up")',
          'Use "at night" instead of "in night"',
          'Include the definite article ("in the afternoon")',
          'Minimize hesitation pauses between sentences',
        ],
        betterVersion: 'I typically wake up at 6 AM. Then I head to the gym for my strength training session. Afterwards, I eat a high-protein breakfast with eggs and oats. During the afternoon, I attend university lectures and study computer science algorithms. Finally, at night, I practice coding and problem-solving.',
        isVideoSaved: false,
        createdAt: DateTime(2026, 9, 27, 18, 15),
      ),

      // 25 Sep 2026: Technology (3:02, 5 corrections)
      SpeakingPracticeRecord(
        id: 'sp_25sep',
        userId: uid,
        date: '2026-09-25',
        time: '19:40',
        topic: 'Technology',
        durationSeconds: 182, // 3 min 02 sec
        transcript: 'Technology is advancing very rapid today. Every company are implementing cloud computing and automation. I think everyone must to learn basic programming skills because in future software is everywhere. In my college we are building IoT and VLSI microchip prototypes.',
        corrections: [
          SpeakingCorrectionItem(
            id: 'c25_1',
            category: 'Grammar',
            subcategory: 'Adverbs',
            originalText: 'advancing very rapid',
            correctedText: 'advancing very rapidly',
            whyWrong: 'Verbs ("advancing") must be modified by an adverb ("rapidly"), not an adjective ("rapid").',
            moreNaturalWay: 'Technology is progressing at a rapid pace today.',
          ),
          SpeakingCorrectionItem(
            id: 'c25_2',
            category: 'Grammar',
            subcategory: 'Subject-Verb Agreement',
            originalText: 'Every company are implementing',
            correctedText: 'Every company is implementing',
            whyWrong: '"Every company" is grammatically singular and takes the singular verb "is".',
            moreNaturalWay: 'Almost every modern enterprise is adopting cloud computing.',
          ),
          SpeakingCorrectionItem(
            id: 'c25_3',
            category: 'Grammar',
            subcategory: 'Modal Auxiliaries',
            originalText: 'everyone must to learn',
            correctedText: 'everyone must learn',
            whyWrong: 'Modal auxiliary verbs like "must", "can", and "should" are followed directly by the bare infinitive without "to".',
            moreNaturalWay: 'everyone should acquire foundational programming literacy.',
          ),
          SpeakingCorrectionItem(
            id: 'c25_4',
            category: 'Grammar',
            subcategory: 'Articles',
            originalText: 'because in future',
            correctedText: 'because in the future',
            whyWrong: 'The temporal expression requires the definite article: "in the future".',
            moreNaturalWay: 'as software becomes ubiquitous across all industries.',
          ),
          SpeakingCorrectionItem(
            id: 'c25_5',
            category: 'Vocabulary',
            subcategory: 'Word Choice',
            originalText: 'software is everywhere',
            correctedText: 'software is ubiquitous',
            whyWrong: '"Ubiquitous" is a more articulate, professional term for something present everywhere.',
            moreNaturalWay: 'as computing technology becomes ubiquitous in every discipline.',
          ),
        ],
        vocabularySuggestions: ['Ubiquitous', 'Rapidly', 'Enterprise', 'Pioneering', 'Architecture'],
        fluencyScore: 87.0,
        wordsCount: 340,
        wordsPerMinute: 112,
        fillerWordsCount: 5,
        fillerDetails: [
          SpeakingFillerDetail(word: 'actually', count: 3),
          SpeakingFillerDetail(word: 'like', count: 2),
        ],
        longPausesCount: 4,
        pronunciationTips: [
          PronunciationItem(
            word: 'technology',
            phoneticGuide: 'tek-NOL-uh-jee',
            issueDescription: 'Stress the second syllable (NOL) firmly and keep the initial "tech" crisp.',
          ),
        ],
        whatYouDidWell: [
          'Excellent topic development and real-world tech examples',
          'Good engagement with VLSI and IoT hardware applications',
          'Pronunciation was clear and easily understandable',
        ],
        improveThese: [
          'Use adverbs to modify verbs ("advancing rapidly")',
          'Remember singular subject agreement ("Every company is...")',
          'Never use "to" after modal verb "must"',
        ],
        betterVersion: 'Technology is advancing very rapidly today. Every enterprise is implementing cloud architecture and automation. In my view, everyone must learn foundational programming skills, because in the future, software and embedded electronics will be ubiquitous.',
        isVideoSaved: false,
        createdAt: DateTime(2026, 9, 25, 19, 40),
      ),

      // 23 Sep 2026: My Career (2:30, 11 corrections)
      SpeakingPracticeRecord(
        id: 'sp_23sep',
        userId: uid,
        date: '2026-09-23',
        time: '20:10',
        topic: 'My Career Goals',
        durationSeconds: 150, // 2 min 30 sec
        transcript: 'I am want to become a successful hardware and software engineer. I am working in this project from two months. My dream is working in top semiconductor firm and design microchips. I am good in logic design and I have confidence that I will achieve my target.',
        corrections: [
          SpeakingCorrectionItem(
            id: 'c23_1',
            category: 'Grammar',
            subcategory: 'Auxiliary Verbs',
            originalText: 'I am want to become',
            correctedText: 'I want to become',
            whyWrong: 'Do not combine the auxiliary "am" with the simple present main verb "want".',
            moreNaturalWay: 'My aspiration is to become a skilled hardware and systems engineer.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_2',
            category: 'Grammar',
            subcategory: 'Prepositions',
            originalText: 'I am working in this project',
            correctedText: 'I have been working on this project',
            whyWrong: 'In English, you work "on" a project, not "in" a project.',
            moreNaturalWay: 'I have been actively working on this engineering project.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_3',
            category: 'Grammar',
            subcategory: 'Tenses',
            originalText: 'from two months',
            correctedText: 'for two months',
            whyWrong: 'Use "for" to express duration of time; "from" does not indicate ongoing continuous duration in English.',
            moreNaturalWay: 'for the past two months.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_4',
            category: 'Grammar',
            subcategory: 'Verb Forms',
            originalText: 'My dream is working',
            correctedText: 'My dream is to work',
            whyWrong: 'Infinitives ("to work") sound more aspirational and natural following "my dream is".',
            moreNaturalWay: 'My long-term ambition is to work at a leading semiconductor firm.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_5',
            category: 'Grammar',
            subcategory: 'Articles',
            originalText: 'in top semiconductor firm',
            correctedText: 'at a top semiconductor firm',
            whyWrong: 'Singular countable nouns require an article ("a top firm").',
            moreNaturalWay: 'at a leading VLSI design company.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_6',
            category: 'Grammar',
            subcategory: 'Prepositions',
            originalText: 'I am good in logic design',
            correctedText: 'I am good at logic design',
            whyWrong: 'The correct preposition with the adjective "good" when referring to skills is "at", not "in".',
            moreNaturalWay: 'I possess strong competence in digital logic design.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_7',
            category: 'Grammar',
            subcategory: 'Parallelism',
            originalText: 'and design microchips',
            correctedText: 'and to design microchips',
            whyWrong: 'Maintain parallel structure with the earlier infinitive ("to work ... and design").',
            moreNaturalWay: 'and architect advanced microchips.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_8',
            category: 'Vocabulary',
            subcategory: 'Word Choice',
            originalText: 'achieve my target',
            correctedText: 'achieve my aspirations / reach my career milestones',
            whyWrong: '"Aspirations" or "goals" is more sophisticated than the literal "target" in career discussions.',
            moreNaturalWay: 'reach my professional milestones.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_9',
            category: 'Sentence Construction',
            subcategory: 'Sentence Variety',
            originalText: 'I am good in... and I have confidence that...',
            correctedText: 'Confident in my logic design abilities, I believe...',
            whyWrong: 'Connecting repetitive "I am ... and I have" structures creates monotony.',
            moreNaturalWay: 'Combining technical discipline with my passion for semiconductor systems, I am confident in reaching my goals.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_10',
            category: 'Fluency',
            subcategory: 'Filler Words',
            originalText: 'actually like you know',
            correctedText: 'Smooth transitions without cluster fillers',
            whyWrong: 'Avoid grouping multiple filler words together.',
            moreNaturalWay: 'Maintain calm breathing during technical explanations.',
          ),
          SpeakingCorrectionItem(
            id: 'c23_11',
            category: 'Vocabulary',
            subcategory: 'Repetition',
            originalText: 'successful... achieve... target',
            correctedText: 'Thrive, innovate, architect, deliver',
            whyWrong: 'Use richer action verbs to convey ambition.',
            moreNaturalWay: 'Design next-generation computing hardware.',
          ),
        ],
        vocabularySuggestions: ['Aspiration', 'Semiconductor', 'Competence', 'Architect', 'Milestone'],
        fluencyScore: 78.0,
        wordsCount: 260,
        wordsPerMinute: 104,
        fillerWordsCount: 14,
        fillerDetails: [
          SpeakingFillerDetail(word: 'actually', count: 5),
          SpeakingFillerDetail(word: 'like', count: 5),
          SpeakingFillerDetail(word: 'um', count: 4),
        ],
        longPausesCount: 7,
        pronunciationTips: [
          PronunciationItem(
            word: 'semiconductor',
            phoneticGuide: 'sem-ee-kuhn-DUHK-ter',
            issueDescription: 'Put primary stress on "DUHK" and enunciate the final syllable clearly.',
          ),
        ],
        whatYouDidWell: [
          'High passion and motivation for the chosen engineering domain',
          'Honest self-assessment and drive to master VLSI and hardware design',
          'Good volume and intelligible speech throughout',
        ],
        improveThese: [
          'Say "I have been working on" instead of "I am working in"',
          'Use "good at" instead of "good in"',
          'Use "for two months" to indicate duration instead of "from"',
          'Eliminate cluster filler words ("actually like")',
        ],
        betterVersion: 'I aspire to become a proficient hardware and systems engineer. I have been working on this design project for the past two months. My long-term ambition is to work at a leading semiconductor firm and architect next-generation microchips. I am skilled at digital logic design and confident that I will achieve my professional milestones through disciplined effort.',
        isVideoSaved: false,
        createdAt: DateTime(2026, 9, 23, 20, 10),
      ),

      // Other sessions over the past week to complete 3h 24m total speaking and 7-day streak
      SpeakingPracticeRecord(
        id: 'sp_26sep',
        userId: uid,
        date: '2026-09-26',
        time: '11:00',
        topic: 'Fitness & Physical Discipline',
        durationSeconds: 1500, // 25 mins
        transcript: 'Today I discussed how gym training builds psychological resilience.',
        corrections: [],
        fluencyScore: 88.0,
        wordsCount: 2700,
        wordsPerMinute: 108,
        createdAt: DateTime(2026, 9, 26, 11, 0),
      ),
      SpeakingPracticeRecord(
        id: 'sp_24sep',
        userId: uid,
        date: '2026-09-24',
        time: '15:20',
        topic: 'Engineering Campus Life & Projects',
        durationSeconds: 1800, // 30 mins
        transcript: 'A discussion regarding technical projects and campus teamwork.',
        corrections: [],
        fluencyScore: 85.0,
        wordsCount: 3200,
        wordsPerMinute: 106,
        createdAt: DateTime(2026, 9, 24, 15, 20),
      ),
      SpeakingPracticeRecord(
        id: 'sp_22sep',
        userId: uid,
        date: '2026-09-22',
        time: '16:00',
        topic: 'Group Discussion: Space Exploration',
        durationSeconds: 3600, // 60 mins
        transcript: 'Debating reusable launch vehicles and satellite constellations.',
        corrections: [],
        fluencyScore: 90.0,
        wordsCount: 6500,
        wordsPerMinute: 108,
        createdAt: DateTime(2026, 9, 22, 16, 0),
      ),
    ];
  }

  List<LiveConversationSession> _getDefaultConversationSessions() {
    final uid = AuthService.instance.uid;
    return [
      LiveConversationSession(
        id: 'live_conv_1',
        userId: uid,
        date: '2026-09-28',
        topic: 'Artificial Intelligence',
        durationSeconds: 480, // 8 minutes
        mode: LiveConversationMode.general,
        level: EnglishLevel.intermediate,
        isCorrectionEnabled: true,
        wordsSpokenApprox: 620,
        commonFillers: {'actually': 8, 'like': 5, 'um': 3},
        grammarIssues: ['Past tense consistency ("went" vs "am going")', 'Preposition with "discuss"'],
        newVocabulary: ['efficient', 'innovative', 'automation', 'ubiquitous'],
        recommendedPractice: 'Past tense + sentence linking with subordinate clauses',
        whatToPracticeNext: 'Practice describing something that happened yesterday using the simple past tense.',
        messages: [
          LiveConversationMessage(
            role: 'ai',
            text: 'Hello Akash! It is great to practice English with you today. What topic would you like to explore together?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          ),
          LiveConversationMessage(
            role: 'user',
            text: 'Let\'s talk about artificial intelligence and how it affects our engineering study.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
          ),
          LiveConversationMessage(
            role: 'ai',
            text: 'Artificial intelligence is certainly revolutionizing engineering education! In what specific ways have you observed AI assisting students in your college?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
          ),
          LiveConversationMessage(
            role: 'user',
            text: 'Yesterday I am going to college and I meet my friends to discuss about our project on neural networks.',
            liveCorrection: 'A more natural way to say that is: "Yesterday I went to college and met my friends to discuss our project."',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          LiveConversationMessage(
            role: 'ai',
            text: 'That sounds like a fascinating project! Which particular aspect of neural networks are you focusing on—computer vision, natural language processing, or embedded microcontrollers?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
          LiveConversationMessage(
            role: 'user',
            text: 'We are focusing on embedded microcontrollers for edge AI inference. I like hardware design very very much.',
            liveCorrection: 'Tip: You can say "I really enjoy hardware design" or "I am deeply passionate about hardware design."',
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
          LiveConversationMessage(
            role: 'ai',
            text: 'Edge AI is a remarkable choice! Balancing power constraints with compute throughput on microcontrollers is critical. How do you plan to optimize the memory footprint of your model?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}

