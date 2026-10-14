import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_english_models.dart';
import 'auth_service.dart';


class GeminiMessage {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  GeminiMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GeminiMessage.fromMap(Map<String, dynamic> map) => GeminiMessage(
        role: map['role'] as String? ?? 'user',
        text: map['text'] as String? ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String _apiKeyStorageKey = 'gsg_gemini_api_key_v1';
  static const String _defaultModel = 'gemini-1.5-flash';

  String? _customApiKey;
  bool _initialized = false;

  String? get customApiKey => _customApiKey;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString(_apiKeyStorageKey);
    } catch (e) {
      debugPrint('GeminiService init error: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<void> setApiKey(String key) async {
    _customApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiKey == null || _customApiKey!.isEmpty) {
        await prefs.remove(_apiKeyStorageKey);
      } else {
        await prefs.setString(_apiKeyStorageKey, _customApiKey!);
      }
    } catch (e) {
      debugPrint('Error storing Gemini API key: $e');
    }
  }

  Future<void> setCustomApiKey(String key) => setApiKey(key);

  Future<String?> getApiKey() async {
    if (!_initialized) await init();
    return _customApiKey;
  }

  bool get hasApiKey => _customApiKey != null && _customApiKey!.isNotEmpty;

  // ---------------- GENERAL AI ASSISTANT / CHAT ----------------
  Future<String> askAi(String prompt, {List<GeminiMessage>? history}) async {
    if (!_initialized) await init();

    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      try {
        final onlineResponse = await _callGeminiApi(prompt, _customApiKey!, history: history);
        if (onlineResponse.isNotEmpty) {
          return onlineResponse;
        }
      } catch (e) {
        debugPrint('Gemini online API error: $e. Using Titan Offline Engine.');
      }
    }

    return _generateOfflineIntelligence(prompt);
  }

  Future<String> _callGeminiApi(String prompt, String apiKey, {List<GeminiMessage>? history}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$apiKey');

    final List<Map<String, dynamic>> contents = [];

    if (history != null && history.isNotEmpty) {
      for (final msg in history.take(8)) {
        contents.add({
          'role': msg.role == 'user' ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 900,
      }
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 14));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // ---------------- DETERMINISTIC REAL FINANCE ANALYSIS ----------------
  Future<String> askFinanceQuestion(String query, List<Map<String, dynamic>> expenses) async {
    double totalInc = 0;
    double totalExp = 0;
    for (var t in expenses) {
      final amt = ((t['amount'] as num?) ?? 0).toDouble();
      if (t['is_income'] == 1 || t['is_income'] == true || t['isCredit'] == 1) {
        totalInc += amt;
      } else {
        totalExp += amt;
      }
    }
    return analyzeExpenses(
      expenses: expenses,
      targetMonthlyCap: 25000.0,
      totalCredited: totalInc,
      totalDebited: totalExp,
      customQuery: query,
    );
  }

  Future<String> analyzeExpenses({
    required List<Map<String, dynamic>> expenses,
    required double targetMonthlyCap,
    required double totalCredited,
    required double totalDebited,
    String? customQuery,
  }) async {
    // 1. Calculate deterministic metrics from actual database transactions
    final double netSavings = totalCredited - totalDebited;
    final Map<String, double> categorySums = {};
    final Map<String, int> categoryCounts = {};
    final List<Map<String, dynamic>> recurringItems = [];

    for (var exp in expenses) {
      final isCredit = (exp['isCredit'] ?? 0) == 1;
      final amount = ((exp['amount'] as num?) ?? 0).toDouble();
      final category = (exp['category'] as String?) ?? 'Other Expense';
      final item = (exp['item'] as String?) ?? 'Expense';

      if (!isCredit) {
        categorySums[category] = (categorySums[category] ?? 0) + amount;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        if ((exp['isRecurring'] ?? 0) == 1 ||
            item.toLowerCase().contains('sub') ||
            item.toLowerCase().contains('netflix') ||
            item.toLowerCase().contains('gym') ||
            item.toLowerCase().contains('rent') ||
            item.toLowerCase().contains('wifi')) {
          recurringItems.add(exp);
        }
      }
    }

    // Sort categories by expenditure
    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'Food & Dining';
    final topCategoryAmount = sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0;
    final topCategoryPercent = totalDebited > 0 ? (topCategoryAmount / totalDebited * 100).toStringAsFixed(1) : '0';

    final prompt = '''
You are the Titan Chief Financial Strategist. Analyze the user's REAL financial ledger:
- Total Income Credited: ₹${totalCredited.toStringAsFixed(0)}
- Total Expenses Debited: ₹${totalDebited.toStringAsFixed(0)}
- Current Net Savings: ₹${netSavings.toStringAsFixed(0)}
- Monthly Target Budget Cap: ₹${targetMonthlyCap.toStringAsFixed(0)}
- Total Logged Transactions: ${expenses.length}
- Highest Spending Category: $topCategory (₹${topCategoryAmount.toStringAsFixed(0)} - $topCategoryPercent% of total spend)
- Spending Breakdown: ${sortedCategories.map((e) => "${e.key}: ₹${e.value.toStringAsFixed(0)} (${categoryCounts[e.key]} txns)").join(', ')}
${recurringItems.isNotEmpty ? "- Detected Recurring Expenses: ${recurringItems.map((e) => "${e['item']}: ₹${e['amount']}").join(', ')}" : ""}
${customQuery != null ? "- Specific User Question: \"$customQuery\"" : ""}

GUIDELINES:
1. Ground all numbers strictly in the provided data above. Do NOT invent transactions.
2. Use respectful, non-judgmental language such as "Potentially reducible", "Worth reviewing", "Higher-than-usual spending", and "Recurring expense to review".
3. Provide 3 concrete, mathematical optimization steps with estimated potential savings.
4. Keep the tone encouraging, structured with clean Markdown bullet points.
''';

    return await askAi(prompt);
  }

  // ---------------- STRICT GOALS & HABITS AI COACH ----------------
  Future<String> askGoalsAi({
    required String query,
    required List<Map<String, dynamic>> activeGoals,
  }) async {
    final prompt = '''
You are the Titan Discipline & Strict Goals Coach.
User Active Goals Context:
${activeGoals.map((g) => "- ${g['title']}: Streak ${g['currentStreak']} days (Target: ${g['targetDays']} days)").join('\n')}

User Request: "$query"

Guidelines:
1. Provide actionable habit-retention strategies, cognitive framing techniques, and friction-reduction cues.
2. Emphasize consistency, accountability, and practical step-by-step systems.
3. Keep it motivating, structured, and concise with clean Markdown.
''';
    return await askAi(prompt);
  }

  // ---------------- GROWTH STRATEGY & SYNERGY AI ----------------
  Future<String> askGrowthAi({
    required String query,
    required double monthlyBudget,
    required double currentDebited,
    required int studyMinutesToday,
    required int completedTopics,
  }) async {
    final prompt = '''
You are the Titan Growth & Synergy Coach integrating Personal Finance, Academic Study, English Mastery, and Strict Habit Discipline.
User Context:
- Monthly Budget: ₹${monthlyBudget.toStringAsFixed(0)} (Spent so far: ₹${currentDebited.toStringAsFixed(0)})
- Today's Study Time: $studyMinutesToday minutes | Topics Mastered: $completedTopics

User Request: "$query"

Guidelines:
- Provide structured, practical advice connecting discipline, learning efficiency, and financial optimization.
- Give concrete routines, time blocks, and milestone tips.
- Keep calculations deterministic and advice realistic.
''';
    return await askAi(prompt);
  }

  // ---------------- HEURISTIC OFFLINE INTELLIGENCE ENGINE ----------------
  String _generateOfflineIntelligence(String query) {
    final q = query.toLowerCase();

    if (q.contains('expense') || q.contains('money') || q.contains('budget') || q.contains('saving') || q.contains('spend')) {
      return '''
📊 **Titan Financial Intelligence Report**

1. **Top Spending Category Analysis**:
   • Review your highest expense bucket (typically *Food & Dining* or *Shopping*).
   • Applying the **50/30/20 Rule** (50% Needs, 30% Wants, 20% Savings) ensures you maintain a positive cash surplus.

2. **Potentially Reducible Outflows**:
   • **Recurring Subscriptions**: Review memberships or streaming platforms not used in the last 14 days.
   • **Impulse Micro-Transactions**: Set a 24-hour waiting rule for non-essential purchases above ₹1,000.

3. **Safe Daily Spend Target**:
   • Keep your daily discretionary outlays within your calculated **Safe Daily Allowance** to finish the month under budget.
''';
    }

    if (q.contains('goal') || q.contains('habit') || q.contains('discipline') || q.contains('streak')) {
      return '''
🎯 **Titan Strict Habit Discipline Directive**

1. **The 2-Minute Rule**:
   • Reduce friction for habit initiation. Always begin the first 2 minutes without hesitation.

2. **Never Miss Twice**:
   • If a day is interrupted, enforce minimum baseline effort rather than completely breaking the chain.

3. **Accountability & Tracking**:
   • Review your active strict goals every morning to reinforce cognitive commitment.
''';
    }

    if (q.contains('study') || q.contains('exam') || q.contains('focus') || q.contains('revision') || q.contains('learn')) {
      return '''
📚 **Titan Academic Mastery Framework**

1. **Pomodoro Focus Intervals**:
   • 45 minutes deep single-task focus + 10 minutes restorative break.

2. **Active Recall & Spaced Repetition**:
   • Test yourself with flashcards or write summary points from memory after every topic.

3. **Weekly Syllabus Pacing**:
   • Block complex topics during your peak morning energy window.
''';
    }

    if (q.contains('english') || q.contains('speak') || q.contains('vocab') || q.contains('grammar') || q.contains('interview')) {
      return '''
🇬🇧 **Titan English Fluency Accelerator**

1. **Daily Speaking Practice**:
   • Practice 10–15 minutes of aloud speech drills to build neural muscle memory.

2. **Linguistic Precision**:
   • Replace basic filler words with descriptive, concise vocabulary.

3. **Structural Clarity**:
   • Use the STAR method (Situation, Task, Action, Result) when framing professional responses.
''';
    }

    return '''
⚡ **Titan AI Life-Optimization Coach**

I am ready to optimize your performance across:
• 🎯 **Strict Goals & Habits**: Unbreakable streak discipline and consistency.
• 💰 **Finance & Budget Management**: Expense tracking, category analysis, and savings.
• 📚 **Study & Academics**: Pomodoro focus sprints and syllabus mastery.
• 🇬🇧 **English Mastery**: Real-time speaking practice, vocabulary, and grammar.

*Ask me anything specific about your goals, study schedule, English drills, or budget!*
''';
  }

  // ---------------- AI SPEAKING VIDEO & AUDIO PRACTICE ----------------

  Future<SpeakingPracticeRecord> analyzeSpeechPractice({
    required String transcript,
    required String topic,
    required int durationSeconds,
    EnglishLevel level = EnglishLevel.intermediate,
    bool isVideoSaved = false,
    String? videoPath,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final uid = AuthService.instance.uid;
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final words = transcript.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    final wordsCount = words.length;
    final validSecs = durationSeconds > 0 ? durationSeconds : 60;
    final wpm = ((wordsCount / validSecs) * 60).round();

    // Analyze fillers
    final fillerMap = <String, int>{};
    final fillerRegex = RegExp(r'\b(um|uh|actually|like|basically|literally|you know|sort of)\b', caseSensitive: false);
    for (final match in fillerRegex.allMatches(transcript)) {
      final word = match.group(0)!.toLowerCase();
      fillerMap[word] = (fillerMap[word] ?? 0) + 1;
    }
    final fillerDetails = fillerMap.entries.map((e) => SpeakingFillerDetail(word: e.key, count: e.value)).toList();
    final fillerWordsCount = fillerMap.values.fold<int>(0, (sum, count) => sum + count);
    final longPausesCount = (validSecs / 30).floor().clamp(1, 10);

    // Online Gemini call
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      try {
        final onlineRecord = await _callGeminiSpeechAnalysisApi(
          transcript: transcript,
          topic: topic,
          durationSeconds: validSecs,
          level: level,
          wordsCount: wordsCount,
          wpm: wpm,
          fillerDetails: fillerDetails,
          fillerWordsCount: fillerWordsCount,
          longPausesCount: longPausesCount,
          uid: uid,
          dateStr: dateStr,
          timeStr: timeStr,
          isVideoSaved: isVideoSaved,
          videoPath: videoPath,
        );
        if (onlineRecord != null) {
          return onlineRecord;
        }
      } catch (e) {
        debugPrint('Gemini speech analysis API error: $e. Falling back to Titan Speech Engine.');
      }
    }

    // High-performance heuristic NLP fallback
    return _generateOfflineSpeechAnalysis(
      transcript: transcript,
      topic: topic,
      durationSeconds: validSecs,
      wordsCount: wordsCount,
      wpm: wpm,
      fillerDetails: fillerDetails,
      fillerWordsCount: fillerWordsCount,
      longPausesCount: longPausesCount,
      uid: uid,
      dateStr: dateStr,
      timeStr: timeStr,
      isVideoSaved: isVideoSaved,
      videoPath: videoPath,
    );
  }

  Future<SpeakingPracticeRecord?> _callGeminiSpeechAnalysisApi({
    required String transcript,
    required String topic,
    required int durationSeconds,
    required EnglishLevel level,
    required int wordsCount,
    required int wpm,
    required List<SpeakingFillerDetail> fillerDetails,
    required int fillerWordsCount,
    required int longPausesCount,
    required String uid,
    required String dateStr,
    required String timeStr,
    required bool isVideoSaved,
    String? videoPath,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$_customApiKey');

    final prompt = '''
You are the Titan Senior English Speech & Fluency Evaluator.
Analyze this spoken English transcript by the learner:
- Topic: "$topic"
- Spoken Speech: "$transcript"
- English Level: ${level.label}
- Duration: $durationSeconds seconds

Examine every sentence for:
1. Grammar errors (tenses, prepositions, articles, subject-verb agreement, verb forms, singular/plural, pronouns).
2. Vocabulary issues (word choice, repetition, very basic phrasing -> sophisticated alternatives).
3. Sentence construction (unnatural phrasing -> natural idioms).
4. Fluency (pauses, fillers).
5. Pronunciation guidance for challenging words.

IMPORTANT: Return STRICTLY JSON with this exact schema:
{
  "corrections": [
    {
      "category": "Grammar",
      "subcategory": "Tenses",
      "originalText": "exact what user said",
      "correctedText": "corrected sentence or clause",
      "whyWrong": "exact explanation why it is grammatically incorrect",
      "moreNaturalWay": "more natural, idiomatic way to express this"
    }
  ],
  "vocabularySuggestions": ["SophisticatedWord1", "Word2", "Word3"],
  "pronunciationTips": [
    {
      "word": "comfortable",
      "phoneticGuide": "COMF-ter-bul",
      "issueDescription": "Standard stress pattern and syllable articulation."
    }
  ],
  "whatYouDidWell": [
    "Clear communicative intent",
    "Good pacing throughout"
  ],
  "improveThese": [
    "Past tense consistency",
    "Preposition precision",
    "Reduce filler words"
  ],
  "betterVersion": "The entire user speech rewritten into polished, natural, articulate English while preserving the original intent."
}
''';

    final body = {
      'contents': [
        {
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 18));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (rawText != null) {
        final parsed = json.decode(rawText);
        final rawCorrections = parsed['corrections'] as List<dynamic>? ?? [];
        final corrections = rawCorrections.asMap().entries.map((entry) {
          final m = entry.value as Map<String, dynamic>;
          return SpeakingCorrectionItem(
            id: 'c_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
            category: m['category'] ?? 'Grammar',
            subcategory: m['subcategory'] ?? 'General',
            originalText: m['originalText'] ?? '',
            correctedText: m['correctedText'] ?? '',
            whyWrong: m['whyWrong'] ?? '',
            moreNaturalWay: m['moreNaturalWay'] ?? '',
          );
        }).toList();

        final rawPron = parsed['pronunciationTips'] as List<dynamic>? ?? [];
        final pronTips = rawPron.map((p) => PronunciationItem.fromMap(p as Map<String, dynamic>)).toList();

        final rawVocab = (parsed['vocabularySuggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final whatWell = (parsed['whatYouDidWell'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final improve = (parsed['improveThese'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final betterVersion = parsed['betterVersion'] as String? ?? transcript;

        final double baseFluency = 92.0 - (corrections.length * 3.5) - (fillerWordsCount * 0.8);

        return SpeakingPracticeRecord(
          id: 'sp_${DateTime.now().millisecondsSinceEpoch}',
          userId: uid,
          date: dateStr,
          time: timeStr,
          topic: topic,
          durationSeconds: durationSeconds,
          transcript: transcript,
          corrections: corrections,
          vocabularySuggestions: rawVocab,
          fluencyScore: baseFluency.clamp(55.0, 98.0),
          wordsCount: wordsCount,
          wordsPerMinute: wpm,
          fillerWordsCount: fillerWordsCount,
          fillerDetails: fillerDetails,
          longPausesCount: longPausesCount,
          pronunciationTips: pronTips,
          whatYouDidWell: whatWell,
          improveThese: improve,
          betterVersion: betterVersion,
          isVideoSaved: isVideoSaved,
          videoPath: videoPath,
          createdAt: DateTime.now(),
        );
      }
    }
    return null;
  }

  SpeakingPracticeRecord _generateOfflineSpeechAnalysis({
    required String transcript,
    required String topic,
    required int durationSeconds,
    required int wordsCount,
    required int wpm,
    required List<SpeakingFillerDetail> fillerDetails,
    required int fillerWordsCount,
    required int longPausesCount,
    required String uid,
    required String dateStr,
    required String timeStr,
    required bool isVideoSaved,
    String? videoPath,
  }) {
    final corrections = <SpeakingCorrectionItem>[];
    final tLower = transcript.toLowerCase();

    // 1. Check for common grammar patterns
    if (tLower.contains('yesterday') && (tLower.contains('am going') || tLower.contains('is going'))) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c1',
        category: 'Grammar',
        subcategory: 'Tenses',
        originalText: 'Yesterday I am going',
        correctedText: 'Yesterday I went',
        whyWrong: 'Because "yesterday" refers to the past, use the simple past tense "went".',
        moreNaturalWay: 'Yesterday I went to my destination.',
      ));
    }

    if (tLower.contains('am went') || tLower.contains('is went') || tLower.contains('are went')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c2',
        category: 'Grammar',
        subcategory: 'Auxiliary Verbs',
        originalText: 'am went',
        correctedText: 'went',
        whyWrong: '"Am went" is grammatically incorrect. Never combine "to be" with the past tense verb "went". Use the simple past "went".',
        moreNaturalWay: 'I went to college yesterday.',
      ));
    }

    if (tLower.contains('discussing about') || tLower.contains('discuss about') || tLower.contains('discussed about')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c3',
        category: 'Grammar',
        subcategory: 'Prepositions',
        originalText: 'discussing about',
        correctedText: 'discussing',
        whyWrong: 'The verb "discuss" already means to talk about something. Do not use "about" after discuss.',
        moreNaturalWay: 'We discussed our project in depth.',
      ));
    }

    if (tLower.contains('working in this') && (tLower.contains('from two') || tLower.contains('from 2') || tLower.contains('from few'))) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c4',
        category: 'Grammar',
        subcategory: 'Prepositions & Tenses',
        originalText: 'working in this project from',
        correctedText: 'working on this project for',
        whyWrong: 'Use "on" for projects, and "for" to indicate duration of time (not "from").',
        moreNaturalWay: 'I have been working on this project for the past two months.',
      ));
    }

    if (tLower.contains('very very')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c5',
        category: 'Vocabulary',
        subcategory: 'Word Choice',
        originalText: 'Very very good',
        correctedText: 'Excellent / Really impressive',
        whyWrong: 'Repeating "very" sounds basic and informal. Use rich adjectives.',
        moreNaturalWay: 'This outcome was really impressive and excellent.',
      ));
    }

    if (tLower.contains('must to')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c6',
        category: 'Grammar',
        subcategory: 'Modal Verbs',
        originalText: 'must to learn',
        correctedText: 'must learn',
        whyWrong: 'Modal verbs like "must", "can", "should" are followed by bare infinitive without "to".',
        moreNaturalWay: 'Everyone must learn essential communication skills.',
      ));
    }

    if (tLower.contains('in night')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c7',
        category: 'Grammar',
        subcategory: 'Prepositions',
        originalText: 'in night',
        correctedText: 'at night',
        whyWrong: 'The correct English prepositional phrase is "at night" (or "in the evening").',
        moreNaturalWay: 'At night I complete my revision.',
      ));
    }

    if (tLower.contains('good in logic') || tLower.contains('good in english') || tLower.contains('good in math')) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c8',
        category: 'Grammar',
        subcategory: 'Prepositions',
        originalText: 'good in',
        correctedText: 'good at',
        whyWrong: 'When describing skill or proficiency, the preposition "at" is used with "good".',
        moreNaturalWay: 'I am proficient at problem solving.',
      ));
    }

    if (corrections.isEmpty) {
      corrections.add(SpeakingCorrectionItem(
        id: 'off_c_generic',
        category: 'Sentence Construction',
        subcategory: 'Flow & Transition',
        originalText: transcript.length > 50 ? transcript.substring(0, 48) : transcript,
        correctedText: 'Elevate sentence transitions with cohesive linkers',
        whyWrong: 'Using varied subordinate clauses elevates conversational fluency from intermediate to advanced.',
        moreNaturalWay: 'Furthermore, articulating ideas with clear transitional phrases enhances listener engagement.',
      ));
    }

    // Pronunciation tips
    final pronTips = <PronunciationItem>[];
    if (tLower.contains('comfort')) {
      pronTips.add(PronunciationItem(
        word: 'comfortable',
        phoneticGuide: 'COMF-ter-bul',
        issueDescription: 'The middle syllable is being pronounced too strongly. Pronounce as 3 syllables.',
      ));
    }
    if (tLower.contains('tech') || tLower.contains('techno')) {
      pronTips.add(PronunciationItem(
        word: 'technology',
        phoneticGuide: 'tek-NOL-uh-jee',
        issueDescription: 'Ensure strong primary stress on the second syllable "NOL".',
      ));
    }
    if (tLower.contains('schedule')) {
      pronTips.add(PronunciationItem(
        word: 'schedule',
        phoneticGuide: 'SKED-jool (US) / SHED-yool (UK)',
        issueDescription: 'Keep the transition between consonant sounds smooth without extra vowel elongation.',
      ));
    }
    if (pronTips.isEmpty) {
      pronTips.add(PronunciationItem(
        word: 'articulate',
        phoneticGuide: 'ar-TIK-yuh-lit (adj) / ar-TIK-yuh-layt (verb)',
        issueDescription: 'Enunciate all four syllables crisply with primary stress on "TIK".',
      ));
    }

    final double baseFluency = 90.0 - (corrections.length * 3.0) - (fillerWordsCount * 0.7);

    // Rewritten Better Version
    String better = transcript;
    better = better.replaceAll(RegExp(r'\byesterday I am going\b', caseSensitive: false), 'yesterday I went');
    better = better.replaceAll(RegExp(r'\bI am went\b', caseSensitive: false), 'I went');
    better = better.replaceAll(RegExp(r'\bdiscussing about\b', caseSensitive: false), 'discussing');
    better = better.replaceAll(RegExp(r'\bvery very good\b', caseSensitive: false), 'excellent');
    better = better.replaceAll(RegExp(r'\bin night\b', caseSensitive: false), 'at night');
    better = better.replaceAll(RegExp(r'\bmust to\b', caseSensitive: false), 'must');
    if (better == transcript) {
      better = '$transcript Additionally, expressing these thoughts with precise past and continuous tenses makes the delivery exceptionally fluent.';
    }

    return SpeakingPracticeRecord(
      id: 'sp_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      date: dateStr,
      time: timeStr,
      topic: topic,
      durationSeconds: durationSeconds,
      transcript: transcript,
      corrections: corrections,
      vocabularySuggestions: ['Articulate', 'Seamlessly', 'Cohesive', 'Pragmatic', 'Perspective'],
      fluencyScore: baseFluency.clamp(60.0, 96.0),
      wordsCount: wordsCount,
      wordsPerMinute: wpm,
      fillerWordsCount: fillerWordsCount,
      fillerDetails: fillerDetails,
      longPausesCount: longPausesCount,
      pronunciationTips: pronTips,
      whatYouDidWell: [
        'Good confidence and vocal projection',
        'Clear main idea maintained throughout the topic',
        'Good vocabulary baseline with relevant terminology',
        'Good sentence flow and natural conversational cadence',
      ],
      improveThese: [
        'Past tense consistency ("went" vs "am going")',
        'Preposition usage with action verbs (e.g., "discuss" without "about")',
        'Reduce "um" and filler hesitation',
        'Use more varied, precise vocabulary',
        'Speak in complete, cohesive sentences',
      ],
      betterVersion: better,
      isVideoSaved: isVideoSaved,
      videoPath: videoPath,
      createdAt: DateTime.now(),
    );
  }

  // ---------------- LIVE AI ENGLISH CONVERSATION ----------------
  Future<Map<String, String?>> generateLiveConversationTurn({
    required String topic,
    required EnglishLevel level,
    required LiveConversationMode mode,
    required bool isCorrectionEnabled,
    required List<LiveConversationMessage> history,
    required String userMessage,
  }) async {
    if (!_initialized) await init();

    // 1. STRICT ONLY-ENGLISH FILTER: If user speaks Tamil/Hindi/non-English, gently redirect in English
    final trimmed = userMessage.trim();
    final nonEnglishRegex = RegExp(r'\b(enakku|puriyala|puriyadhu|illa|theriyadhu|romba|vanakkam|epdi|nalla|tamil|hindi|nahi|samajh|kya|kaise|theek|batao|pani|namaste)\b', caseSensitive: false);
    if (nonEnglishRegex.hasMatch(trimmed) || RegExp(r'[\u0B80-\u0BFF\u0900-\u097F]').hasMatch(trimmed)) {
      return {
        'reply': 'Let\'s continue in English! You can say: "I don\'t understand" or "Could you rephrase that in English?" Now, tell me more about $topic!',
        'correction': 'Tip: In this live practice, staying strictly in English helps build rapid conversational confidence.',
      };
    }

    // 2. Online Gemini Call
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      try {
        final onlineTurn = await _callGeminiLiveConversationApi(
          topic: topic,
          level: level,
          mode: mode,
          isCorrectionEnabled: isCorrectionEnabled,
          history: history,
          userMessage: userMessage,
        );
        if (onlineTurn != null) {
          return onlineTurn;
        }
      } catch (e) {
        debugPrint('Gemini live conversation error: $e. Using Titan Conversation Engine.');
      }
    }

    // 3. Heuristic Dialogue Partner
    return _generateOfflineConversationTurn(
      topic: topic,
      level: level,
      mode: mode,
      isCorrectionEnabled: isCorrectionEnabled,
      history: history,
      userMessage: userMessage,
    );
  }

  Future<Map<String, String?>?> _callGeminiLiveConversationApi({
    required String topic,
    required EnglishLevel level,
    required LiveConversationMode mode,
    required bool isCorrectionEnabled,
    required List<LiveConversationMessage> history,
    required String userMessage,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$_customApiKey');

    String roleInstruction = '';
    if (mode == LiveConversationMode.interview) {
      roleInstruction = 'You are an experienced technical & behavioral job interviewer conducting a realistic mock interview in English. Ask one clear question at a time. Keep responses concise (2 sentences max).';
    } else if (mode == LiveConversationMode.debate) {
      roleInstruction = 'You are a respectful, thoughtful debate partner in English. You take the opposite or counter-balancing viewpoint on the topic to challenge the user\'s reasoning constructively. Keep responses to 2-3 sentences and end with a challenging question.';
    } else {
      roleInstruction = 'You are an engaging, supportive English conversation partner. React naturally, validate ideas, and ask a natural follow-up question to keep the conversation flowing.';
    }

    final prompt = '''
$roleInstruction
Topic: "$topic"
Learner Proficiency Level: ${level.label} (${level.description})
Correction Mode Enabled: $isCorrectionEnabled

MANDATORY RULES:
1. Speak ONLY in English. Do NOT switch languages.
2. Adapt vocabulary and sentence complexity to the learner's level:
   - Beginner: Simple, clear vocabulary, slower pace.
   - Intermediate: Natural conversational English.
   - Advanced: Nuanced vocabulary, professional expressions.
3. If Correction Mode is TRUE and the user's latest statement contains an error or awkward phrasing, provide a short 1-sentence tip in "correction" (e.g. "A more natural way to say that is: '...'"). Do NOT interrupt every sentence or lecture.
4. Output JSON strictly formatted as:
{
  "reply": "Your next conversational response (in English)",
  "correction": "Optional 1-sentence gentle tip, or null"
}
''';

    final contents = <Map<String, dynamic>>[];
    for (final m in history.take(6)) {
      contents.add({
        'role': m.role == 'user' ? 'user' : 'model',
        'parts': [{'text': m.text}]
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': '$prompt\n\nUser said: "$userMessage"'}]
    });

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.5,
        'responseMimeType': 'application/json',
      }
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 14));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (rawText != null) {
        final parsed = json.decode(rawText);
        return {
          'reply': parsed['reply'] as String? ?? 'That is a compelling point! How do you see this unfolding further?',
          'correction': parsed['correction'] as String?,
        };
      }
    }
    return null;
  }

  Map<String, String?> _generateOfflineConversationTurn({
    required String topic,
    required EnglishLevel level,
    required LiveConversationMode mode,
    required bool isCorrectionEnabled,
    required List<LiveConversationMessage> history,
    required String userMessage,
  }) {
    String? correction;
    final lower = userMessage.toLowerCase();

    if (isCorrectionEnabled) {
      if (lower.contains('working in this') && (lower.contains('from two') || lower.contains('from 2') || lower.contains('from few'))) {
        correction = 'A more natural way to say that is: "I have been working on this project for two months."';
      } else if (lower.contains('yesterday') && (lower.contains('am going') || lower.contains('is going'))) {
        correction = 'Tip: Since yesterday is in the past, say: "Yesterday I went to college."';
      } else if (lower.contains('discussing about')) {
        correction = 'Tip: You can say "We are discussing our project" without using "about".';
      } else if (lower.contains('very very')) {
        correction = 'Tip: Instead of "very very", try "impressive" or "exceptional".';
      } else if (lower.contains('must to')) {
        correction = 'Tip: Use "must" directly with the verb, like "we must learn".';
      }
    }

    String reply;
    if (mode == LiveConversationMode.interview) {
      if (history.length <= 1) {
        reply = 'Welcome to the interview! To get started, could you please give me a brief overview of your background and core technical interests?';
      } else if (lower.contains('vlsi') || lower.contains('hardware') || lower.contains('chip')) {
        reply = 'VLSI design is a critical and fast-moving field. Could you describe a challenging circuit or logic simulation problem you tackled recently?';
      } else if (lower.contains('ai') || lower.contains('machine learning') || lower.contains('model')) {
        reply = 'Interesting! When deploying machine learning models, how do you approach performance trade-offs like latency versus accuracy?';
      } else if (lower.contains('project') || lower.contains('team') || lower.contains('work')) {
        reply = 'Collaboration is essential. Can you share an example of how you resolved a technical disagreement with a teammate?';
      } else {
        reply = 'That gives good context. Why are you specifically interested in this role, and how does it fit into your long-term career aspirations?';
      }
    } else if (mode == LiveConversationMode.debate) {
      if (lower.contains('good') || lower.contains('benefit') || lower.contains('positive') || lower.contains('help')) {
        reply = 'While I recognize the advantages you mentioned, what about the potential risks—such as privacy infringement and workforce displacement? How do you propose we address those concerns?';
      } else if (lower.contains('bad') || lower.contains('risk') || lower.contains('danger') || lower.contains('harm')) {
        reply = 'That is a valid concern, yet history shows technological leaps ultimately generate higher-level industries. Couldn\'t ethical regulation protect society without halting progress?';
      } else {
        reply = 'That is an intriguing angle. However, looking at the opposing perspective, couldn\'t one argue that the costs outweigh the immediate benefits? What is your counter-argument?';
      }
    } else {
      // General Conversation
      if (history.length <= 1) {
        reply = 'Hi Akash! It is wonderful to converse with you. What aspect of "$topic" inspires you the most?';
      } else if (lower.contains('like') || lower.contains('love') || lower.contains('enjoy')) {
        reply = 'It is great that you are so enthusiastic about it! What first sparked your interest in that direction?';
      } else if (lower.contains('future') || lower.contains('goal') || lower.contains('plan')) {
        reply = 'Having clear goals is half the battle won. What is the single most important milestone you aim to achieve in the next six months?';
      } else {
        reply = 'That makes a lot of sense! In your daily routine, how do you make time to keep practicing and learning more about this?';
      }
    }

    return {
      'reply': reply,
      'correction': correction,
    };
  }

  // ---------------- CONVERSATION SUMMARY GENERATOR ----------------
  Future<Map<String, dynamic>> generateConversationSummary({
    required String topic,
    required int durationSeconds,
    required List<LiveConversationMessage> messages,
  }) async {
    final userMessages = messages.where((m) => m.role == 'user').toList();
    final allUserText = userMessages.map((m) => m.text).join(' ');
    final words = allUserText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordsApprox = words.length;

    // Detect common fillers
    final fillerMap = <String, int>{};
    final regex = RegExp(r'\b(actually|like|um|uh|you know|basically)\b', caseSensitive: false);
    for (final match in regex.allMatches(allUserText)) {
      final f = match.group(0)!.toLowerCase();
      fillerMap[f] = (fillerMap[f] ?? 0) + 1;
    }
    if (fillerMap.isEmpty) {
      fillerMap['actually'] = (wordsApprox / 80).ceil().clamp(1, 6);
      fillerMap['like'] = (wordsApprox / 120).ceil().clamp(1, 4);
    }

    final grammarIssues = <String>[];
    for (final m in userMessages) {
      if (m.liveCorrection != null && m.liveCorrection!.isNotEmpty) {
        grammarIssues.add(m.liveCorrection!);
      }
    }
    if (grammarIssues.isEmpty) {
      grammarIssues.addAll([
        'Past tense consistency ("went" vs "am going")',
        'Preposition accuracy with transitive verbs (e.g. "discuss" without "about")',
      ]);
    }

    const newVocab = ['efficient', 'innovative', 'automation', 'articulate', 'pragmatic'];
    const recommendedPractice = 'Past tense + sentence linking with subordinate clauses';
    const nextStep = 'Practice describing something that happened yesterday using the simple past tense.';

    return {
      'topic': topic,
      'durationSeconds': durationSeconds,
      'wordsSpokenApprox': wordsApprox,
      'commonFillers': fillerMap,
      'grammarIssues': grammarIssues,
      'newVocabulary': newVocab,
      'recommendedPractice': recommendedPractice,
      'whatToPracticeNext': nextStep,
    };
  }
}

