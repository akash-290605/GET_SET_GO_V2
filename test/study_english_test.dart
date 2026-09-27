import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/study_english_models.dart';
import 'package:flutter_application_1/services/study_english_service.dart';
import 'package:flutter_application_1/models/food_models.dart';
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

      // Record a grammar quiz answer
      service.recordGrammarAnswer(true);
      expect(service.grammarQuizzesTaken, greaterThanOrEqualTo(1));
      expect(service.grammarCorrectAnswers, greaterThanOrEqualTo(1));
    });
  });
}
