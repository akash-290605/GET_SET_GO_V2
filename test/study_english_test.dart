import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/study_english_models.dart';
import 'package:flutter_application_1/models/food_models.dart';
import 'package:flutter_application_1/models/body_photo_model.dart';
import 'package:flutter_application_1/models/physique_measurement_model.dart';
import 'package:flutter_application_1/models/weight_entry_model.dart';
import 'package:flutter_application_1/models/workout_history_model.dart';
import 'package:flutter_application_1/services/study_english_service.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:flutter_application_1/services/time_service.dart';
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

    test('StandardNutritionDatabase includes 100+ foods and South Indian items', () {
      final foods = StandardNutritionDatabase.getAllFoods();
      expect(foods.length, greaterThanOrEqualTo(50));

      final idli = foods.firstWhere((f) => f.name.contains('Idli'));
      expect(idli.caloriesPer100g, greaterThan(0));
      expect(idli.proteinPer100g, greaterThan(0));
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

  group('Fitness, Nutrition, and Body Tracking Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('BMI Calculator and Categories calculate correctly', () {
      final profile = ProfileService.instance;
      
      profile.heightCm = 175.0;
      profile.weightKg = 80.0;
      expect(profile.bmi, equals(26.1));
      expect(profile.bmiCategory, equals('Overweight'));

      profile.weightKg = 70.0;
      expect(profile.bmi, equals(22.9));
      expect(profile.bmiCategory, equals('Normal weight'));

      profile.heightCm = 180.0;
      profile.weightKg = 55.0;
      expect(profile.bmi, equals(17.0));
      expect(profile.bmiCategory, equals('Underweight'));

      profile.heightCm = 170.0;
      profile.weightKg = 95.0;
      expect(profile.bmi, equals(32.9));
      expect(profile.bmiCategory, equals('Obesity'));
    });

    test('Mifflin-St Jeor Calorie & Macro Target Estimation', () {
      final profile = ProfileService.instance;
      profile.gender = 'Male';
      profile.age = 24;
      profile.heightCm = 175.0;
      profile.weightKg = 72.5;
      profile.activityLevel = 'Moderately Active (3-5 days)';
      profile.fitnessGoal = 'Muscle Gain & Hypertrophy';

      final bmr = profile.estimatedBmr;
      expect(bmr, greaterThan(1500));
      expect(bmr, lessThan(1900));

      final tdee = profile.estimatedTdee;
      expect(tdee, greaterThan(bmr));

      final targetCals = profile.estimatedTargetCalories;
      expect(targetCals, greaterThan(tdee));

      final macros = profile.estimatedMacros;
      expect(macros['calories'], equals(targetCals));
      expect(macros['protein'], greaterThanOrEqualTo(100.0));
      expect(macros['fat'], greaterThan(30.0));
      expect(macros['carbs'], greaterThan(100.0));
    });

    test('TimeService IST ISO Week Calculation is accurate', () {
      final dateSep27 = DateTime(2026, 9, 27);
      final weekKey = TimeService.getWeekKey(dateSep27);
      expect(weekKey, equals('2026-W39'));

      final dateJan1 = DateTime(2026, 1, 1);
      final weekKeyJan = TimeService.getWeekKey(dateJan1);
      expect(weekKeyJan.startsWith('202'), isTrue);
    });

    test('Models toMap and fromMap serialization', () {
      const photo = BodyPhotoEntry(
        id: 1,
        date: '2026-09-27',
        time: '08:30',
        photoBase64: 'base64sample',
        weightKg: 72.5,
        note: 'Morning fasted check-in',
      );
      final photoMap = photo.toMap();
      final photoFromMap = BodyPhotoEntry.fromMap(photoMap);
      expect(photoFromMap.date, equals('2026-09-27'));
      expect(photoFromMap.weightKg, equals(72.5));
      expect(photoFromMap.note, equals('Morning fasted check-in'));

      const pm = PhysiqueMeasurement(
        id: 1,
        date: '2026-09-27',
        unit: 'cm',
        chest: 102.0,
        waist: 82.0,
        abdomen: 84.0,
        hip: 98.0,
        neck: 38.0,
        leftArm: 36.5,
        rightArm: 37.0,
        leftThigh: 56.0,
        rightThigh: 56.5,
        comment: 'Post-workout measurement',
      );
      final pmMap = pm.toMap();
      final pmFromMap = PhysiqueMeasurement.fromMap(pmMap);
      expect(pmFromMap.chest, equals(102.0));
      expect(pmFromMap.waist, equals(82.0));
      expect(pmFromMap.unit, equals('cm'));

      const we = WeeklyWeightEntry(
        id: 1,
        date: '2026-09-27',
        weekKey: '2026-W39',
        weightKg: 72.4,
        comment: 'Solid deficit adherence this week',
      );
      final weMap = we.toMap();
      final weFromMap = WeeklyWeightEntry.fromMap(weMap);
      expect(weFromMap.weekKey, equals('2026-W39'));
      expect(weFromMap.weightKg, equals(72.4));

      const log = WorkoutHistoryLog(
        id: 1,
        date: '2026-09-27',
        dayName: 'Sunday',
        workoutName: 'Active Recovery & Core',
        completedExercisesCount: 4,
        totalExercisesCount: 4,
        durationMinutes: 35,
        notes: 'Great core stability session',
        completedAt: '2026-09-27T10:00:00',
      );
      final logMap = log.toMap();
      final logFromMap = WorkoutHistoryLog.fromMap(logMap);
      expect(logFromMap.workoutName, equals('Active Recovery & Core'));
      expect(logFromMap.completedExercisesCount, equals(4));
    });

    test('DBHelper in-memory CRUD for new feature sets', () async {
      final db = DBHelper.instance;

      const w1 = WeeklyWeightEntry(
        date: '2026-09-27',
        weekKey: '2026-W39',
        weightKg: 72.5,
        comment: 'Week 39 checkin',
      );
      final wId = await db.insertWeeklyWeight(w1);
      expect(wId, greaterThan(0));

      final weights = await db.fetchWeeklyWeights();
      expect(weights.any((w) => w.weekKey == '2026-W39'), isTrue);

      const photo1 = BodyPhotoEntry(
        date: '2026-09-27',
        time: '09:00',
        weightKg: 72.5,
        note: 'Day 1 photo',
      );
      final photoId = await db.insertBodyPhoto(photo1);
      expect(photoId, greaterThan(0));

      final photos = await db.fetchBodyPhotos();
      expect(photos.any((p) => p.note == 'Day 1 photo'), isTrue);

      const pm1 = PhysiqueMeasurement(
        date: '2026-09-27',
        unit: 'cm',
        chest: 102.5,
        waist: 82.0,
      );
      final pmId = await db.insertPhysiqueMeasurement(pm1);
      expect(pmId, greaterThan(0));

      final measurements = await db.fetchPhysiqueMeasurements();
      expect(measurements.any((m) => m.chest == 102.5), isTrue);

      const workoutLog = WorkoutHistoryLog(
        date: '2026-09-27',
        dayName: 'Sunday',
        workoutName: 'Chest & Triceps',
        completedExercisesCount: 6,
        totalExercisesCount: 6,
        durationMinutes: 50,
        completedAt: '2026-09-27T18:00:00',
      );
      final wlId = await db.insertWorkoutHistoryLog(workoutLog);
      expect(wlId, greaterThan(0));

      final workoutLogs = await db.fetchWorkoutHistoryLogs();
      expect(workoutLogs.any((l) => l.workoutName == 'Chest & Triceps'), isTrue);
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
