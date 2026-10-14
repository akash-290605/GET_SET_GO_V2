import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/study_english_models.dart';
import 'package:flutter_application_1/services/study_english_service.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:flutter_application_1/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Study & English Models and Service Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('StudySubject and StudyTopic model calculations', () {
      final subject = StudySubject(
        id: 'sub_math',
        name: 'Mathematics',
        topics: [
          StudyTopic(id: 'top_1', title: 'Calculus', isCompleted: true),
          StudyTopic(id: 'top_2', title: 'Linear Algebra', isCompleted: false),
        ],
      );

      expect(subject.topics.length, equals(2));
      expect(subject.completionProgress, equals(0.5));
    });

    test('EnglishVocabularyWord model toggle status', () {
      final word = EnglishVocabularyWord(
        id: 'word_1',
        word: 'Tenacious',
        phonetic: '/təˈneɪ.ʃəs/',
        meaning: 'Tending to keep a firm hold of something; persistent.',
        example: 'She was tenacious in pursuing her goals.',
        status: VocabularyStatus.needRevision,
      );

      expect(word.status, equals(VocabularyStatus.needRevision));
      final map = word.toMap();
      final reconstructed = EnglishVocabularyWord.fromMap(map);
      expect(reconstructed.word, equals('Tenacious'));
      expect(reconstructed.status, equals(VocabularyStatus.needRevision));
    });

    test('StudyEnglishService initialization and state management', () async {
      final service = StudyEnglishService.instance;
      await service.init();

      expect(service.subjects, isNotEmpty);
      expect(service.plannerSessions, isNotEmpty);
      expect(service.vocabularyList, isNotEmpty);

      service.recordGrammarAnswer(true);
      expect(service.grammarQuizzesTaken, greaterThanOrEqualTo(1));
      expect(service.grammarCorrectAnswers, greaterThanOrEqualTo(1));
    });
  });

  group('Strict Goals & Habits and Finance Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ProfileService strict goals telemetry and habits management', () async {
      final profile = ProfileService.instance;
      await profile.init();

      expect(profile.dailyStepTarget, equals(10000));
      expect(profile.dailyActiveTimeMinutesTarget, equals(60));
      expect(profile.dailyWaterIntakeMlTarget, equals(3000));

      final prevSteps = profile.todaySteps;
      await profile.logSteps(500);
      expect(profile.todaySteps, equals(prevSteps + 500));

      final prevWater = profile.todayWaterIntakeMl;
      await profile.logWater(250);
      expect(profile.todayWaterIntakeMl, equals(prevWater + 250));
    });

    test('DBHelper Goals and Expenses CRUD', () async {
      final db = DBHelper.instance;

      final goal = {
        'id': 'test_goal_1',
        'title': 'Daily 10k Steps Protocol',
        'targetDays': 30,
        'currentStreak': 5,
        'lastCompletedDate': '2026-10-14',
        'notifyUser': 1,
      };
      await db.insertGoal(goal);

      final goals = await db.getGoals();
      expect(goals.any((g) => g['id'] == 'test_goal_1'), isTrue);

      final expense = {
        'item': 'Tech Books',
        'category': 'Education',
        'amount': 1200.0,
        'date': '2026-10-14',
        'isCredit': 0,
      };
      await db.insertExpense(expense);

      final expenses = await db.getExpenses();
      expect(expenses.any((e) => e['item'] == 'Tech Books'), isTrue);

      await db.deleteGoal('test_goal_1');
      final afterDelete = await db.getGoals();
      expect(afterDelete.any((g) => g['id'] == 'test_goal_1'), isFalse);
    });
  });

  group('AI Speaking Practice & Live Conversation Models and DB Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SpeakingPracticeRecord and SpeakingCorrectionItem serialization', () {
      final record = SpeakingPracticeRecord(
        id: 'speak_101',
        userId: 'test_user',
        date: '2026-09-28',
        time: '14:30',
        topic: 'My Daily Routine',
        durationSeconds: 120,
        transcript: 'Yesterday I am going to college and I meet my friends.',
        corrections: [
          SpeakingCorrectionItem(
            id: 'corr_1',
            category: 'Grammar',
            originalText: 'Yesterday I am going to college',
            correctedText: 'Yesterday I went to college',
            whyWrong: 'Because yesterday refers to the past, use simple past tense.',
            moreNaturalWay: 'I went to college yesterday and caught up with my friends.',
          ),
        ],
        vocabularySuggestions: ['caught up with', 'met with'],
        fluencyScore: 82.5,
        wordsCount: 10,
        wordsPerMinute: 110,
        fillerWordsCount: 1,
        fillerDetails: [
          SpeakingFillerDetail(word: 'um', count: 1),
        ],
        longPausesCount: 0,
        pronunciationTips: [
          PronunciationItem(
            word: 'comfortable',
            phoneticGuide: 'COMF-ter-bul',
            issueDescription: 'Middle syllable pronounced too strongly.',
          ),
        ],
        whatYouDidWell: ['Good pacing', 'Clear voice'],
        improveThese: ['Past tense consistency'],
        betterVersion: 'Yesterday I went to college and met my friends.',
        isVideoSaved: false,
        createdAt: DateTime.now(),
      );

      final map = record.toMap();
      final fromMap = SpeakingPracticeRecord.fromMap(map);

      expect(fromMap.id, equals('speak_101'));
      expect(fromMap.topic, equals('My Daily Routine'));
      expect(fromMap.corrections.length, equals(1));
      expect(fromMap.corrections.first.correctedText, equals('Yesterday I went to college'));
      expect(fromMap.pronunciationTips.first.phoneticGuide, equals('COMF-ter-bul'));
      expect(fromMap.betterVersion, equals('Yesterday I went to college and met my friends.'));
    });

    test('LiveConversationSession serialization and conversation metrics', () {
      final session = LiveConversationSession(
        id: 'conv_101',
        userId: 'test_user',
        date: '2026-09-28',
        topic: 'Tech & Career Goals',
        durationSeconds: 300,
        mode: LiveConversationMode.interview,
        level: EnglishLevel.intermediate,
        isCorrectionEnabled: true,
        messages: [
          LiveConversationMessage(
            role: 'ai',
            text: 'Tell me about your tech background.',
            timestamp: DateTime.now(),
          ),
          LiveConversationMessage(
            role: 'user',
            text: 'I am learning Flutter and building cross platform applications.',
            timestamp: DateTime.now(),
            liveCorrection: 'I am learning Flutter and building cross-platform applications.',
          ),
        ],
        wordsSpokenApprox: 90,
        commonFillers: {'like': 2, 'you know': 1},
        grammarIssues: ['Hyphenation in cross-platform'],
        newVocabulary: ['Architectural scalability'],
        recommendedPractice: 'Practice answering system design questions with concise sentences.',
        whatToPracticeNext: 'Technical interview behavioral questions',
        createdAt: DateTime.now(),
      );

      final map = session.toMap();
      final reconstructed = LiveConversationSession.fromMap(map);

      expect(reconstructed.id, equals('conv_101'));
      expect(reconstructed.mode, equals(LiveConversationMode.interview));
      expect(reconstructed.messages.length, equals(2));
      expect(reconstructed.newVocabulary.first, equals('Architectural scalability'));
    });

    test('DBHelper CRUD for Speaking Practice and Live Conversation', () async {
      final db = DBHelper.instance;

      final speakingRecord = SpeakingPracticeRecord(
        id: 'speak_db_1',
        userId: 'test_user',
        date: '2026-09-28',
        time: '15:00',
        topic: 'Job Interview Practice',
        durationSeconds: 90,
        transcript: 'I have good experience in state management.',
        corrections: [],
        vocabularySuggestions: ['proficient', 'adept'],
        fluencyScore: 90.0,
        wordsCount: 7,
        wordsPerMinute: 115,
        fillerWordsCount: 0,
        fillerDetails: [],
        longPausesCount: 0,
        pronunciationTips: [],
        whatYouDidWell: ['Confident tone'],
        improveThese: [],
        betterVersion: 'I am proficient in state management.',
        isVideoSaved: false,
        createdAt: DateTime.now(),
      );

      await db.insertSpeakingRecord(speakingRecord);
      final fetchedRecords = await db.fetchSpeakingRecords();
      expect(fetchedRecords.any((r) => r.id == 'speak_db_1'), isTrue);

      final liveSession = LiveConversationSession(
        id: 'conv_db_1',
        userId: 'test_user',
        date: '2026-09-28',
        topic: 'Casual Chit-chat',
        durationSeconds: 150,
        mode: LiveConversationMode.general,
        level: EnglishLevel.beginner,
        isCorrectionEnabled: false,
        messages: [],
        wordsSpokenApprox: 45,
        commonFillers: {},
        grammarIssues: [],
        newVocabulary: ['marvelous'],
        recommendedPractice: 'Keep speaking daily for 10 minutes.',
        whatToPracticeNext: 'Daily routines',
        createdAt: DateTime.now(),
      );

      await db.insertLiveConversation(liveSession);
      final fetchedSessions = await db.fetchLiveConversations();
      expect(fetchedSessions.any((s) => s.id == 'conv_db_1'), isTrue);

      await db.deleteSpeakingRecord('speak_db_1');
      final afterDelete = await db.fetchSpeakingRecords();
      expect(afterDelete.any((r) => r.id == 'speak_db_1'), isFalse);
    });
  });
}
