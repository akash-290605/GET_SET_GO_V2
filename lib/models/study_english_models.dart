enum StudyPriority { high, medium, low }
enum StudySessionStatus { planned, inProgress, completed, skipped }
enum VocabularyStatus { learned, needRevision, difficult }
enum EnglishLevel { beginner, intermediate, advanced }

class StudyTopic {
  final String id;
  String title;
  int estimatedMinutes;
  bool isCompleted;
  DateTime? completedAt;
  String notes;

  StudyTopic({
    required this.id,
    required this.title,
    this.estimatedMinutes = 45,
    this.isCompleted = false,
    this.completedAt,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'estimatedMinutes': estimatedMinutes,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
      };

  factory StudyTopic.fromMap(Map<String, dynamic> map) => StudyTopic(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        estimatedMinutes: map['estimatedMinutes'] ?? 45,
        isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
        completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
        notes: map['notes'] ?? '',
      );
}

class StudySubject {
  final String id;
  String name;
  int colorValue;
  StudyPriority priority;
  DateTime? targetExamDate;
  String notes;
  List<StudyTopic> topics;

  StudySubject({
    required this.id,
    required this.name,
    this.colorValue = 0xFF8B5CF6,
    this.priority = StudyPriority.high,
    this.targetExamDate,
    this.notes = '',
    List<StudyTopic>? topics,
  }) : topics = topics ?? [];

  double get completionProgress {
    if (topics.isEmpty) return 0.0;
    final done = topics.where((t) => t.isCompleted).length;
    return done / topics.length;
  }

  int get totalMinutes => topics.fold(0, (sum, t) => sum + t.estimatedMinutes);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'priority': priority.name,
        'targetExamDate': targetExamDate?.toIso8601String(),
        'notes': notes,
        'topics': topics.map((t) => t.toMap()).toList(),
      };

  factory StudySubject.fromMap(Map<String, dynamic> map) => StudySubject(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        colorValue: map['colorValue'] ?? 0xFF8B5CF6,
        priority: StudyPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => StudyPriority.medium,
        ),
        targetExamDate: map['targetExamDate'] != null ? DateTime.tryParse(map['targetExamDate']) : null,
        notes: map['notes'] ?? '',
        topics: (map['topics'] as List<dynamic>?)
                ?.map((t) => StudyTopic.fromMap(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class StudyPlannerSession {
  final String id;
  String dayName; // Monday..Sunday
  String subjectName;
  String topicTitle;
  int durationMinutes;
  StudyPriority priority;
  StudySessionStatus status;

  StudyPlannerSession({
    required this.id,
    required this.dayName,
    required this.subjectName,
    required this.topicTitle,
    this.durationMinutes = 60,
    this.priority = StudyPriority.medium,
    this.status = StudySessionStatus.planned,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayName': dayName,
        'subjectName': subjectName,
        'topicTitle': topicTitle,
        'durationMinutes': durationMinutes,
        'priority': priority.name,
        'status': status.name,
      };

  factory StudyPlannerSession.fromMap(Map<String, dynamic> map) => StudyPlannerSession(
        id: map['id'] ?? '',
        dayName: map['dayName'] ?? 'Monday',
        subjectName: map['subjectName'] ?? '',
        topicTitle: map['topicTitle'] ?? '',
        durationMinutes: map['durationMinutes'] ?? 60,
        priority: StudyPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => StudyPriority.medium,
        ),
        status: StudySessionStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => StudySessionStatus.planned,
        ),
      );
}

class EnglishVocabularyWord {
  final String id;
  String word;
  String phonetic;
  String partOfSpeech;
  String meaning;
  String example;
  List<String> synonyms;
  List<String> antonyms;
  VocabularyStatus status;
  DateTime dateAdded;

  EnglishVocabularyWord({
    required this.id,
    required this.word,
    this.phonetic = '',
    this.partOfSpeech = 'noun',
    required this.meaning,
    this.example = '',
    List<String>? synonyms,
    List<String>? antonyms,
    this.status = VocabularyStatus.needRevision,
    DateTime? dateAdded,
  })  : synonyms = synonyms ?? [],
        antonyms = antonyms ?? [],
        dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'partOfSpeech': partOfSpeech,
        'meaning': meaning,
        'example': example,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'status': status.name,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory EnglishVocabularyWord.fromMap(Map<String, dynamic> map) => EnglishVocabularyWord(
        id: map['id'] ?? '',
        word: map['word'] ?? '',
        phonetic: map['phonetic'] ?? '',
        partOfSpeech: map['partOfSpeech'] ?? 'noun',
        meaning: map['meaning'] ?? '',
        example: map['example'] ?? '',
        synonyms: (map['synonyms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        antonyms: (map['antonyms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        status: VocabularyStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => VocabularyStatus.needRevision,
        ),
        dateAdded: map['dateAdded'] != null ? DateTime.tryParse(map['dateAdded']) ?? DateTime.now() : DateTime.now(),
      );
}

class EnglishGrammarQuestion {
  final String id;
  final String category; // 'Tenses', 'Articles', 'Prepositions', 'Subject-Verb', 'Active/Passive'
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  EnglishGrammarQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class EnglishReadingPassage {
  final String id;
  final String title;
  final String topic;
  final String content;
  final int estimatedReadTimeMinutes;
  final List<EnglishGrammarQuestion> questions;

  EnglishReadingPassage({
    required this.id,
    required this.title,
    required this.topic,
    required this.content,
    this.estimatedReadTimeMinutes = 3,
    required this.questions,
  });
}
