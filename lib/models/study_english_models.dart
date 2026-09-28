enum StudyPriority { high, medium, low }
enum StudySessionStatus { planned, inProgress, completed, skipped }
enum VocabularyStatus { learned, needRevision, difficult }

enum EnglishLevel {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
}

extension EnglishLevelExt on EnglishLevel {
  String get label {
    switch (this) {
      case EnglishLevel.beginner:
        return 'Beginner';
      case EnglishLevel.elementary:
        return 'Elementary';
      case EnglishLevel.intermediate:
        return 'Intermediate';
      case EnglishLevel.upperIntermediate:
        return 'Upper Intermediate';
      case EnglishLevel.advanced:
        return 'Advanced';
    }
  }

  String get description {
    switch (this) {
      case EnglishLevel.beginner:
        return 'Simple sentences and slower, clear conversation.';
      case EnglishLevel.elementary:
        return 'Everyday conversational basics and practical vocabulary.';
      case EnglishLevel.intermediate:
        return 'Normal conversational English with standard flow.';
      case EnglishLevel.upperIntermediate:
        return 'Fluent speech, active idioms, and structured reasoning.';
      case EnglishLevel.advanced:
        return 'Complex vocabulary, debates, professional nuances, and in-depth discussions.';
    }
  }
}


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

// ================= AI SPEAKING & VIDEO PRACTICE MODELS =================

class SpeakingCorrectionItem {
  final String id;
  final String category; // 'Grammar', 'Vocabulary', 'Sentence Construction', 'Pronunciation'
  final String subcategory; // e.g. 'Tenses', 'Articles', 'Prepositions', 'Subject-Verb Agreement', 'Word Choice'
  final String originalText;
  final String correctedText;
  final String whyWrong;
  final String moreNaturalWay;

  SpeakingCorrectionItem({
    required this.id,
    required this.category,
    this.subcategory = 'Grammar',
    required this.originalText,
    required this.correctedText,
    required this.whyWrong,
    required this.moreNaturalWay,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'subcategory': subcategory,
        'originalText': originalText,
        'correctedText': correctedText,
        'whyWrong': whyWrong,
        'moreNaturalWay': moreNaturalWay,
      };

  factory SpeakingCorrectionItem.fromMap(Map<String, dynamic> map) => SpeakingCorrectionItem(
        id: map['id'] ?? '',
        category: map['category'] ?? 'Grammar',
        subcategory: map['subcategory'] ?? 'General',
        originalText: map['originalText'] ?? '',
        correctedText: map['correctedText'] ?? '',
        whyWrong: map['whyWrong'] ?? '',
        moreNaturalWay: map['moreNaturalWay'] ?? '',
      );
}

class SpeakingFillerDetail {
  final String word;
  final int count;

  SpeakingFillerDetail({required this.word, required this.count});

  Map<String, dynamic> toMap() => {'word': word, 'count': count};

  factory SpeakingFillerDetail.fromMap(Map<String, dynamic> map) => SpeakingFillerDetail(
        word: map['word'] ?? '',
        count: (map['count'] as num?)?.toInt() ?? 0,
      );
}

class PronunciationItem {
  final String word;
  final String phoneticGuide; // e.g. "COMF-ter-bul"
  final String issueDescription;

  PronunciationItem({
    required this.word,
    required this.phoneticGuide,
    required this.issueDescription,
  });

  Map<String, dynamic> toMap() => {
        'word': word,
        'phoneticGuide': phoneticGuide,
        'issueDescription': issueDescription,
      };

  factory PronunciationItem.fromMap(Map<String, dynamic> map) => PronunciationItem(
        word: map['word'] ?? '',
        phoneticGuide: map['phoneticGuide'] ?? '',
        issueDescription: map['issueDescription'] ?? '',
      );
}

class SpeakingPracticeRecord {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm
  final String topic;
  final int durationSeconds;
  final String transcript;
  final List<SpeakingCorrectionItem> corrections;
  final List<String> vocabularySuggestions;
  final double fluencyScore; // 0..100
  final int wordsCount;
  final int wordsPerMinute;
  final int fillerWordsCount;
  final List<SpeakingFillerDetail> fillerDetails;
  final int longPausesCount;
  final List<PronunciationItem> pronunciationTips;
  final List<String> whatYouDidWell;
  final List<String> improveThese;
  final String betterVersion;
  final bool isVideoSaved;
  final String? videoPath;
  final DateTime createdAt;

  SpeakingPracticeRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.time,
    required this.topic,
    required this.durationSeconds,
    required this.transcript,
    List<SpeakingCorrectionItem>? corrections,
    List<String>? vocabularySuggestions,
    this.fluencyScore = 85.0,
    this.wordsCount = 0,
    this.wordsPerMinute = 110,
    this.fillerWordsCount = 0,
    List<SpeakingFillerDetail>? fillerDetails,
    this.longPausesCount = 0,
    List<PronunciationItem>? pronunciationTips,
    List<String>? whatYouDidWell,
    List<String>? improveThese,
    this.betterVersion = '',
    this.isVideoSaved = false,
    this.videoPath,
    DateTime? createdAt,
  })  : corrections = corrections ?? [],
        vocabularySuggestions = vocabularySuggestions ?? [],
        fillerDetails = fillerDetails ?? [],
        pronunciationTips = pronunciationTips ?? [],
        whatYouDidWell = whatYouDidWell ?? [],
        improveThese = improveThese ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date,
        'time': time,
        'topic': topic,
        'durationSeconds': durationSeconds,
        'transcript': transcript,
        'corrections': corrections.map((c) => c.toMap()).toList(),
        'vocabularySuggestions': vocabularySuggestions,
        'fluencyScore': fluencyScore,
        'wordsCount': wordsCount,
        'wordsPerMinute': wordsPerMinute,
        'fillerWordsCount': fillerWordsCount,
        'fillerDetails': fillerDetails.map((f) => f.toMap()).toList(),
        'longPausesCount': longPausesCount,
        'pronunciationTips': pronunciationTips.map((p) => p.toMap()).toList(),
        'whatYouDidWell': whatYouDidWell,
        'improveThese': improveThese,
        'betterVersion': betterVersion,
        'isVideoSaved': isVideoSaved ? 1 : 0,
        'videoPath': videoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SpeakingPracticeRecord.fromMap(Map<String, dynamic> map) => SpeakingPracticeRecord(
        id: map['id'] ?? '',
        userId: map['userId'] ?? 'default_user',
        date: map['date'] ?? '',
        time: map['time'] ?? '',
        topic: map['topic'] ?? 'General Speaking',
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 60,
        transcript: map['transcript'] ?? '',
        corrections: (map['corrections'] as List<dynamic>?)
                ?.map((c) => SpeakingCorrectionItem.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
        vocabularySuggestions: (map['vocabularySuggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        fluencyScore: ((map['fluencyScore'] as num?) ?? 85.0).toDouble(),
        wordsCount: (map['wordsCount'] as num?)?.toInt() ?? 0,
        wordsPerMinute: (map['wordsPerMinute'] as num?)?.toInt() ?? 100,
        fillerWordsCount: (map['fillerWordsCount'] as num?)?.toInt() ?? 0,
        fillerDetails: (map['fillerDetails'] as List<dynamic>?)
                ?.map((f) => SpeakingFillerDetail.fromMap(f as Map<String, dynamic>))
                .toList() ??
            [],
        longPausesCount: (map['longPausesCount'] as num?)?.toInt() ?? 0,
        pronunciationTips: (map['pronunciationTips'] as List<dynamic>?)
                ?.map((p) => PronunciationItem.fromMap(p as Map<String, dynamic>))
                .toList() ??
            [],
        whatYouDidWell: (map['whatYouDidWell'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        improveThese: (map['improveThese'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        betterVersion: map['betterVersion'] ?? '',
        isVideoSaved: map['isVideoSaved'] == 1 || map['isVideoSaved'] == true,
        videoPath: map['videoPath'],
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
      );
}

// ================= LIVE AI ENGLISH CONVERSATION MODELS =================

enum LiveConversationMode {
  general,
  interview,
  debate,
}

extension LiveConversationModeExt on LiveConversationMode {
  String get label {
    switch (this) {
      case LiveConversationMode.general:
        return 'General Conversation';
      case LiveConversationMode.interview:
        return 'Job Interview Practice';
      case LiveConversationMode.debate:
        return 'Debate Practice';
    }
  }

  String get iconEmoji {
    switch (this) {
      case LiveConversationMode.general:
        return '🗣️';
      case LiveConversationMode.interview:
        return '💼';
      case LiveConversationMode.debate:
        return '⚔️';
    }
  }
}

class LiveConversationMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final String? liveCorrection;
  final DateTime timestamp;

  LiveConversationMessage({
    required this.role,
    required this.text,
    this.liveCorrection,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'role': role,
        'text': text,
        'liveCorrection': liveCorrection,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LiveConversationMessage.fromMap(Map<String, dynamic> map) => LiveConversationMessage(
        role: map['role'] ?? 'user',
        text: map['text'] ?? '',
        liveCorrection: map['liveCorrection'],
        timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
      );
}

class LiveConversationSession {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final String topic;
  final int durationSeconds;
  final LiveConversationMode mode;
  final EnglishLevel level;
  final bool isCorrectionEnabled;
  final List<LiveConversationMessage> messages;
  final int wordsSpokenApprox;
  final Map<String, int> commonFillers;
  final List<String> grammarIssues;
  final List<String> newVocabulary;
  final String recommendedPractice;
  final String whatToPracticeNext;
  final DateTime createdAt;

  LiveConversationSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.topic,
    required this.durationSeconds,
    this.mode = LiveConversationMode.general,
    this.level = EnglishLevel.intermediate,
    this.isCorrectionEnabled = true,
    List<LiveConversationMessage>? messages,
    this.wordsSpokenApprox = 0,
    Map<String, int>? commonFillers,
    List<String>? grammarIssues,
    List<String>? newVocabulary,
    this.recommendedPractice = '',
    this.whatToPracticeNext = '',
    DateTime? createdAt,
  })  : messages = messages ?? [],
        commonFillers = commonFillers ?? {},
        grammarIssues = grammarIssues ?? [],
        newVocabulary = newVocabulary ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date,
        'topic': topic,
        'durationSeconds': durationSeconds,
        'mode': mode.name,
        'level': level.name,
        'isCorrectionEnabled': isCorrectionEnabled ? 1 : 0,
        'messages': messages.map((m) => m.toMap()).toList(),
        'wordsSpokenApprox': wordsSpokenApprox,
        'commonFillers': commonFillers,
        'grammarIssues': grammarIssues,
        'newVocabulary': newVocabulary,
        'recommendedPractice': recommendedPractice,
        'whatToPracticeNext': whatToPracticeNext,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LiveConversationSession.fromMap(Map<String, dynamic> map) => LiveConversationSession(
        id: map['id'] ?? '',
        userId: map['userId'] ?? 'default_user',
        date: map['date'] ?? '',
        topic: map['topic'] ?? 'General English Chat',
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 60,
        mode: LiveConversationMode.values.firstWhere(
          (m) => m.name == map['mode'],
          orElse: () => LiveConversationMode.general,
        ),
        level: EnglishLevel.values.firstWhere(
          (l) => l.name == map['level'],
          orElse: () => EnglishLevel.intermediate,
        ),
        isCorrectionEnabled: map['isCorrectionEnabled'] == 1 || map['isCorrectionEnabled'] == true,
        messages: (map['messages'] as List<dynamic>?)
                ?.map((m) => LiveConversationMessage.fromMap(m as Map<String, dynamic>))
                .toList() ??
            [],
        wordsSpokenApprox: (map['wordsSpokenApprox'] as num?)?.toInt() ?? 0,
        commonFillers: (map['commonFillers'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
        grammarIssues: (map['grammarIssues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        newVocabulary: (map['newVocabulary'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        recommendedPractice: map['recommendedPractice'] ?? '',
        whatToPracticeNext: map['whatToPracticeNext'] ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
      );
}
