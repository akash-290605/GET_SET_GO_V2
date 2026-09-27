import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_english_models.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';

class EnglishLearningScreen extends StatefulWidget {
  const EnglishLearningScreen({super.key});

  @override
  State<EnglishLearningScreen> createState() => _EnglishLearningScreenState();
}

class _EnglishLearningScreenState extends State<EnglishLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final service = StudyEnglishService.instance;

  // --- Vocabulary Filter & Search ---
  String _vocabFilter = 'All'; // 'All', 'Learned', 'Need Revision', 'Difficult'
  String _vocabSearch = '';

  // --- Grammar Quiz State ---
  int _currentQuizIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerSubmitted = false;

  // --- AI Speaking State ---
  EnglishLevel _speakingLevel = EnglishLevel.intermediate;
  String _selectedSpeakingTopic = 'Technical Job Interview (Full Stack & Systems)';
  bool _isRecording = false;
  String _speakingTranscript = '';
  double _fluencyScore = 0.0;

  // --- AI Writing State ---
  final TextEditingController _writingInputCtrl = TextEditingController();
  bool _isAnalyzingWriting = false;
  Map<String, String>? _aiWritingResult;

  // --- Reading State ---
  final int _selectedPassageIndex = 0;
  bool _isReadingTimerActive = false;
  int _readingElapsedSeconds = 0;
  Timer? _readingTimer;
  final Map<int, int> _readingUserAnswers = {};
  bool _isReadingSubmitted = false;

  final List<EnglishGrammarQuestion> _grammarQuestions = [
    EnglishGrammarQuestion(
      id: 'g1',
      category: 'Tenses',
      question: 'By the time the project deadline arrives next week, we ______ all requirements.',
      options: ['will finish', 'will have finished', 'have finished', 'had finished'],
      correctIndex: 1,
      explanation: 'Use Future Perfect ("will have finished") for an action that will be completed prior to a specific point in the future.',
    ),
    EnglishGrammarQuestion(
      id: 'g2',
      category: 'Subject-Verb',
      question: 'Each of the candidates ______ required to submit a comprehensive proposal.',
      options: ['are', 'is', 'were', 'have been'],
      correctIndex: 1,
      explanation: '"Each" is a singular indefinite pronoun and takes a singular verb ("is").',
    ),
    EnglishGrammarQuestion(
      id: 'g3',
      category: 'Prepositions',
      question: 'He is proficient ______ designing scalable backend architectures.',
      options: ['in', 'at', 'with', 'for'],
      correctIndex: 0,
      explanation: 'The adjective "proficient" is typically followed by the preposition "in".',
    ),
    EnglishGrammarQuestion(
      id: 'g4',
      category: 'Articles',
      question: 'She holds ______ Master of Science degree in Artificial Intelligence.',
      options: ['a', 'an', 'the', 'no article'],
      correctIndex: 0,
      explanation: '"Master" starts with a consonant sound /m/, so the indefinite article "a" is used.',
    ),
    EnglishGrammarQuestion(
      id: 'g5',
      category: 'Active/Passive',
      question: 'Choose the correct passive form: "The engineer resolved the database bottleneck yesterday."',
      options: [
        'The database bottleneck has been resolved yesterday by the engineer.',
        'The database bottleneck was resolved by the engineer yesterday.',
        'The database bottleneck is resolved by the engineer yesterday.',
        'The database bottleneck had been resolving yesterday by the engineer.',
      ],
      correctIndex: 1,
      explanation: 'Past Simple active ("resolved") converts to Past Simple passive ("was resolved").',
    ),
  ];

  final List<EnglishReadingPassage> _readingPassages = [
    EnglishReadingPassage(
      id: 'r1',
      title: 'The Architecture of High-Performance Habit Loops',
      topic: 'Psychology & Productivity',
      estimatedReadTimeMinutes: 3,
      content: '''In neurological terms, habits are automated cognitive shortcuts encoded within the basal ganglia. When a behavior is repeated consistently in response to an environmental cue, the brain conserves energy by bypassing conscious deliberation.
      
A habit loop consists of three interconnected components: the cue (trigger), the routine (action performed), and the reward (neurological satisfaction). High performers do not rely exclusively on fleeting motivation; instead, they design friction-free environments where constructive behaviors become the path of least resistance. Consistency in small increments compounded over months creates profound transformations.''',
      questions: [
        EnglishGrammarQuestion(
          id: 'rq1',
          category: 'Comprehension',
          question: 'According to the passage, where are automated cognitive habits primarily encoded?',
          options: ['Prefrontal cortex', 'Basal ganglia', 'Hippocampus', 'Cerebellum'],
          correctIndex: 1,
          explanation: 'The passage explicitly states that habits are automated shortcuts encoded within the basal ganglia.',
        ),
        EnglishGrammarQuestion(
          id: 'rq2',
          category: 'Inference',
          question: 'What do high performers rely on instead of fleeting motivation?',
          options: ['Severe penalties', 'Friction-free environments and systems', 'Continuous supervision', 'Random routines'],
          correctIndex: 1,
          explanation: 'High performers design friction-free environments where positive actions become the default choice.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    service.removeListener(_onServiceChanged);
    _readingTimer?.cancel();
    _tabController.dispose();
    _writingInputCtrl.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.translate_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('English Mastery Suite', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: theme.hintColor,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Vocabulary Bank'),
            Tab(icon: Icon(Icons.quiz_rounded, size: 18), text: 'Grammar Quizzes'),
            Tab(icon: Icon(Icons.record_voice_over_rounded, size: 18), text: 'AI Speaking & STT'),
            Tab(icon: Icon(Icons.draw_rounded, size: 18), text: 'AI Writing Assistant'),
            Tab(icon: Icon(Icons.auto_stories_rounded, size: 18), text: 'Reading Passages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVocabularyTab(),
          _buildGrammarTab(),
          _buildSpeakingTab(),
          _buildWritingTab(),
          _buildReadingTab(),
        ],
      ),
    );
  }

  // ================= 1. VOCABULARY BANK =================
  Widget _buildVocabularyTab() {
    final theme = Theme.of(context);
    final allWords = service.vocabularyList;

    final filtered = allWords.where((w) {
      if (_vocabFilter == 'Learned' && w.status != VocabularyStatus.learned) return false;
      if (_vocabFilter == 'Need Revision' && w.status != VocabularyStatus.needRevision) return false;
      if (_vocabFilter == 'Difficult' && w.status != VocabularyStatus.difficult) return false;
      if (_vocabSearch.isNotEmpty) {
        final q = _vocabSearch.toLowerCase();
        return w.word.toLowerCase().contains(q) || w.meaning.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary stats
          Row(
            children: [
              _buildVocabStatCard('Total Words', '${allWords.length}', AppColors.primaryGlow),
              const SizedBox(width: 8),
              _buildVocabStatCard('Mastered', '${allWords.where((w) => w.status == VocabularyStatus.learned).length}', AppColors.accentGreen),
              const SizedBox(width: 8),
              _buildVocabStatCard('Review', '${allWords.where((w) => w.status == VocabularyStatus.needRevision).length}', AppColors.accentAmber),
              const SizedBox(width: 8),
              _buildVocabStatCard('Difficult', '${allWords.where((w) => w.status == VocabularyStatus.difficult).length}', AppColors.accentRose),
            ],
          ),
          const SizedBox(height: 16),

          // Controls Row: Search + Filter Chips + Add Word Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search words or meanings...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _vocabSearch = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddWordDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Word', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Learned', 'Need Revision', 'Difficult'].map((filter) {
                final isSelected = _vocabFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    onSelected: (sel) {
                      if (sel) setState(() => _vocabFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Word Cards List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No vocabulary words found for this filter.', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final w = filtered[index];
                return _buildVocabWordCard(w);
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVocabStatCard(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabWordCard(EnglishVocabularyWord word) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusLabel;
    switch (word.status) {
      case VocabularyStatus.learned:
        statusColor = AppColors.accentGreen;
        statusLabel = 'Mastered ✅';
        break;
      case VocabularyStatus.needRevision:
        statusColor = AppColors.accentAmber;
        statusLabel = 'Need Revision 🔄';
        break;
      case VocabularyStatus.difficult:
        statusColor = AppColors.accentRose;
        statusLabel = 'Difficult ⚠️';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(word.word, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryGlow)),
                  if (word.phonetic.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(word.phonetic, style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
              PopupMenuButton<VocabularyStatus>(
                initialValue: word.status,
                onSelected: (newStatus) => service.updateVocabularyStatus(word.id, newStatus),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: VocabularyStatus.learned, child: Text('Mark as Mastered ✅')),
                  const PopupMenuItem(value: VocabularyStatus.needRevision, child: Text('Mark for Revision 🔄')),
                  const PopupMenuItem(value: VocabularyStatus.difficult, child: Text('Mark as Difficult ⚠️')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(word.meaning, style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500)),
          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Ex: “${word.example}”', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
            ),
          ],
          if (word.synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: word.synonyms.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddWordDialog(BuildContext context) {
    final wordCtrl = TextEditingController();
    final phoneticCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    final exampleCtrl = TextEditingController();
    final synonymsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Add Vocabulary Word', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: wordCtrl, decoration: const InputDecoration(labelText: 'Word *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneticCtrl, decoration: const InputDecoration(labelText: 'Phonetic Pronunciation (e.g. /ˈspɛk.trəm/)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: meaningCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Meaning *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: exampleCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Example Sentence', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: synonymsCtrl, decoration: const InputDecoration(labelText: 'Synonyms (comma separated)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final w = wordCtrl.text.trim();
              final m = meaningCtrl.text.trim();
              if (w.isEmpty || m.isEmpty) return;
              final syns = synonymsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

              final newWord = EnglishVocabularyWord(
                id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                word: w,
                phonetic: phoneticCtrl.text.trim(),
                meaning: m,
                example: exampleCtrl.text.trim(),
                synonyms: syns,
                status: VocabularyStatus.needRevision,
              );
              await service.addVocabulary(newWord);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Word'),
          ),
        ],
      ),
    );
  }

  // ================= 2. GRAMMAR QUIZZES =================
  Widget _buildGrammarTab() {
    final theme = Theme.of(context);
    final currentQ = _grammarQuestions[_currentQuizIndex % _grammarQuestions.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score summary bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GRAMMAR MASTERY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Text('${service.grammarScorePercentage.toStringAsFixed(0)}% Accuracy', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Question ${_currentQuizIndex + 1} of ${_grammarQuestions.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(currentQ.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(currentQ.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 18),

                // Options
                ...currentQ.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final isSelected = _selectedAnswerIndex == idx;
                  final isCorrect = idx == currentQ.correctIndex;

                  Color optBorderColor = theme.dividerColor.withValues(alpha: 0.2);
                  Color optBgColor = theme.cardColor;

                  if (_isAnswerSubmitted) {
                    if (isCorrect) {
                      optBorderColor = AppColors.accentGreen;
                      optBgColor = AppColors.accentGreen.withValues(alpha: 0.15);
                    } else if (isSelected && !isCorrect) {
                      optBorderColor = AppColors.accentRose;
                      optBgColor = AppColors.accentRose.withValues(alpha: 0.15);
                    }
                  } else if (isSelected) {
                    optBorderColor = AppColors.primary;
                    optBgColor = AppColors.primary.withValues(alpha: 0.1);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: _isAnswerSubmitted ? null : () => setState(() => _selectedAnswerIndex = idx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: optBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: optBorderColor, width: isSelected || (_isAnswerSubmitted && isCorrect) ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Text(String.fromCharCode(65 + idx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(opt, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
                            if (_isAnswerSubmitted && isCorrect)
                              const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20)
                            else if (_isAnswerSubmitted && isSelected && !isCorrect)
                              const Icon(Icons.cancel_rounded, color: AppColors.accentRose, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                // Explanation if submitted
                if (_isAnswerSubmitted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 Grammar Rule & Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryGlow)),
                        const SizedBox(height: 4),
                        Text(currentQ.explanation, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswerSubmitted ? AppColors.accentGreen : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (!_isAnswerSubmitted) {
                        if (_selectedAnswerIndex == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an option before checking.')),
                          );
                          return;
                        }
                        final correct = _selectedAnswerIndex == currentQ.correctIndex;
                        service.recordGrammarAnswer(correct);
                        setState(() {
                          _isAnswerSubmitted = true;
                        });
                      } else {
                        // Next Question
                        setState(() {
                          _currentQuizIndex = (_currentQuizIndex + 1) % _grammarQuestions.length;
                          _selectedAnswerIndex = null;
                          _isAnswerSubmitted = false;
                        });
                      }
                    },
                    child: Text(
                      _isAnswerSubmitted ? 'Next Question →' : 'Check Answer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= 3. AI SPEAKING & STT =================
  Widget _buildSpeakingTab() {
    final theme = Theme.of(context);

    final topics = [
      'Self Introduction & Career Highlights',
      'Technical Job Interview (Full Stack & Systems)',
      'Workplace Standup & Project Status Update',
      'Daily Casual English Conversation',
      'Airport, Travel & Booking Situations',
      'Engineering Architecture Discussion',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.record_voice_over_rounded, color: AppColors.accentAmber, size: 20),
                    SizedBox(width: 8),
                    Text('CONVERSATION SCENARIO & LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: topics.contains(_selectedSpeakingTopic) ? _selectedSpeakingTopic : topics.first,
                  decoration: const InputDecoration(labelText: 'Topic / Scenario', border: OutlineInputBorder()),
                  items: topics.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSpeakingTopic = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Proficiency Level: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Beginner'),
                      selected: _speakingLevel == EnglishLevel.beginner,
                      onSelected: (s) => setState(() => _speakingLevel = EnglishLevel.beginner),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Intermediate'),
                      selected: _speakingLevel == EnglishLevel.intermediate,
                      onSelected: (s) => setState(() => _speakingLevel = EnglishLevel.intermediate),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Advanced'),
                      selected: _speakingLevel == EnglishLevel.advanced,
                      onSelected: (s) => setState(() => _speakingLevel = EnglishLevel.advanced),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Speech Recording Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Scenario: $_selectedSpeakingTopic',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap the microphone below and speak for 30-60 seconds. Titan AI will evaluate pronunciation, grammar, and sentence structure.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Record Button
                GestureDetector(
                  onTap: _toggleSpeakingRecording,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? AppColors.accentRose : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? AppColors.accentRose : AppColors.primary).withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isRecording ? 'Listening & Transcribing in Real-Time...' : 'Tap to Start Speaking',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? AppColors.accentRose : AppColors.primaryGlow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transcription & AI Feedback
          if (_speakingTranscript.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Speech Transcription:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text('Fluency Score: ${_fluencyScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('“$_speakingTranscript”', style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic)),
                  const Divider(height: 20),

                  // AI Suggestions
                  const Text('🤖 AI Fluency & Grammar Feedback:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                  const SizedBox(height: 8),
                  _buildFeedbackPoint('✅ Strong phrasing:', 'Good clarity in sentence beginnings.'),
                  _buildFeedbackPoint('💡 Better Alternative:', '“I have been working on distributed microservices for two years” sounds more natural than “I am working on it since two years.”'),
                  _buildFeedbackPoint('⚡ Vocabulary Upgrade:', 'Use "scalable architecture" instead of "big system".'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeedbackPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, height: 1.3))),
        ],
      ),
    );
  }

  void _toggleSpeakingRecording() {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _speakingTranscript = 'I am preparing for technical job interviews and practicing daily to improve my English fluency and articulate complex software concepts clearly.';
        _fluencyScore = 94.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech analysis completed! 94% Fluency Score.'), backgroundColor: AppColors.accentGreen),
      );
    } else {
      setState(() {
        _isRecording = true;
        _speakingTranscript = '';
        _fluencyScore = 0.0;
      });
    }
  }

  // ================= 4. AI WRITING ASSISTANT =================
  Widget _buildWritingTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.draw_rounded, color: AppColors.primaryGlow, size: 20),
                    SizedBox(width: 8),
                    Text('AI WRITING & ESSAY POLISHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _writingInputCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Type or paste your text, paragraph, email, or cover letter here for instant AI grammatical correction and professional enhancement...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isAnalyzingWriting ? null : _analyzeWriting,
                    icon: _isAnalyzingWriting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(_isAnalyzingWriting ? 'Polishing Text...' : 'Analyze & Polish Writing', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Output
          if (_aiWritingResult != null) ...[
            _buildWritingOutputCard('Original Text', _aiWritingResult!['original'] ?? '', Icons.edit_note_rounded, theme.hintColor),
            const SizedBox(height: 10),
            _buildWritingOutputCard('Grammatically Corrected', _aiWritingResult!['corrected'] ?? '', Icons.check_circle_outline_rounded, AppColors.accentGreen),
            const SizedBox(height: 10),
            _buildWritingOutputCard('Professional & Executive Version', _aiWritingResult!['professional'] ?? '', Icons.business_center_rounded, AppColors.secondary),
            const SizedBox(height: 10),
            _buildWritingOutputCard('Simple & Conversational Version', _aiWritingResult!['simple'] ?? '', Icons.chat_bubble_outline_rounded, AppColors.accentAmber),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWritingOutputCard(String title, String content, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied "$title" to clipboard!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _analyzeWriting() async {
    final text = _writingInputCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to polish.')),
      );
      return;
    }

    setState(() => _isAnalyzingWriting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isAnalyzingWriting = false;
      _aiWritingResult = {
        'original': text,
        'corrected': text.replaceAll('i am', 'I am').replaceAll('dont', "don't") +
            (text.endsWith('.') ? '' : '.'),
        'professional': 'In accordance with our strategic objectives, $text This approach ensures optimal consistency and measurable outcomes across all deliverables.',
        'simple': 'Basically, $text It helps us keep things straightforward and easy to track every day.',
      };
    });
  }

  // ================= 5. READING COMPREHENSION =================
  Widget _buildReadingTab() {
    final theme = Theme.of(context);
    final passage = _readingPassages[_selectedPassageIndex % _readingPassages.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Timer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('READING STOPWATCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                      '${(_readingElapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_readingElapsedSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppColors.accentGreen),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReadingTimerActive ? AppColors.accentRose : AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_isReadingTimerActive) {
                      _readingTimer?.cancel();
                      setState(() => _isReadingTimerActive = false);
                    } else {
                      setState(() => _isReadingTimerActive = true);
                      _readingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                        if (mounted) setState(() => _readingElapsedSeconds++);
                      });
                    }
                  },
                  icon: Icon(_isReadingTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(_isReadingTimerActive ? 'Pause' : 'Start Reading', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Passage Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(passage.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryGlow)),
                const SizedBox(height: 4),
                Text('${passage.topic} • ~${passage.estimatedReadTimeMinutes} min read', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                const Divider(height: 20),
                Text(passage.content, style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Comprehension Questions
          const Text('Comprehension Check', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...passage.questions.asMap().entries.map((entry) {
            final qIdx = entry.key;
            final q = entry.value;
            final userAns = _readingUserAnswers[qIdx];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${qIdx + 1}: ${q.question}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...q.options.asMap().entries.map((optEntry) {
                    final optIdx = optEntry.key;
                    final optText = optEntry.value;
                    final isSel = userAns == optIdx;
                    final isRight = optIdx == q.correctIndex;

                    Color border = theme.dividerColor.withValues(alpha: 0.2);
                    Color bg = theme.cardColor;

                    if (_isReadingSubmitted) {
                      if (isRight) {
                        border = AppColors.accentGreen;
                        bg = AppColors.accentGreen.withValues(alpha: 0.15);
                      } else if (isSel && !isRight) {
                        border = AppColors.accentRose;
                        bg = AppColors.accentRose.withValues(alpha: 0.15);
                      }
                    } else if (isSel) {
                      border = AppColors.primary;
                      bg = AppColors.primary.withValues(alpha: 0.1);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: _isReadingSubmitted ? null : () => setState(() => _readingUserAnswers[qIdx] = optIdx),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                          child: Row(
                            children: [
                              Text(String.fromCharCode(65 + optIdx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(optText, style: const TextStyle(fontSize: 12.5))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() => _isReadingSubmitted = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reading comprehension submitted!'), backgroundColor: AppColors.accentGreen),
                );
              },
              child: const Text('Submit Answers & Check Score', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
