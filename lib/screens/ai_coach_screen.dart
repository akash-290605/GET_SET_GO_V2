import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../services/gemini_service.dart';
import '../services/profile_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> with SingleTickerProviderStateMixin {
  late TabController _domainTabController;
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String _loadingMessage = 'AI Coach is analyzing...';
  final List<_ChatMessage> _messages = [];

  final List<String> _quickFinancePrompts = [
    'Where did most of my money go this month?',
    'What are my potentially reducible expenses?',
    'Review my recurring subscriptions & bills',
    'Compare my spending against my monthly budget cap',
  ];

  final List<String> _quickFitnessPrompts = [
    'Create a 30-minute high-intensity workout',
    'Adjust today\'s workout for home (no equipment)',
    'Make today\'s workout easier with higher reps',
    'Which muscle groups need more recovery this week?',
  ];

  final List<String> _quickStudyPrompts = [
    'Create a 2-hour Pomodoro study schedule for today',
    'How can I break down complex algorithms into 45-min sessions?',
    'Suggest an active recall revision plan for this weekend',
    'Help me overcome afternoon study procrastination',
  ];

  final List<String> _quickEnglishPrompts = [
    'Practice a mock software engineer job interview with me',
    'Give me 3 advanced vocabulary alternatives for common workplace words',
    'How do I articulate complex system architecture without hesitation?',
    'Explain the difference between Present Perfect and Past Simple',
  ];

  final List<String> _quickCombinedPrompts = [
    'Suggest affordable high-protein grocery options for my fitness goal',
    'Estimate the monthly financial cost of my fitness routine',
    'How can I balance 2 hours of study, 1 hour workout, and stay under budget?',
  ];

  @override
  void initState() {
    super.initState();
    _domainTabController = TabController(length: 5, vsync: this);
    _messages.add(
      _ChatMessage(
        text: 'Hello ${ProfileService.instance.userName}! I am your GET SET GO AI Life & Performance Coach.\n\nI analyze your actual fitness, finance, nutrition, study, and English learning telemetry to give you personalized, actionable advice.',
        isUser: false,
        domain: 'general',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _domainTabController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String query, {String? domainOverride}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _isLoading) return;

    final activeDomainIndex = _domainTabController.index;
    String domain = domainOverride ?? 'finance';
    if (domainOverride == null) {
      if (activeDomainIndex == 0) {
        domain = 'finance';
      } else if (activeDomainIndex == 1) {
        domain = 'fitness';
      } else if (activeDomainIndex == 2) {
        domain = 'study';
      } else if (activeDomainIndex == 3) {
        domain = 'english';
      } else {
        domain = 'combined';
      }
    }

    _queryController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: cleanQuery, isUser: true, domain: domain, timestamp: DateTime.now()));
      _isLoading = true;
      if (domain == 'finance') {
        _loadingMessage = 'Analyzing your actual transactions & spending patterns...';
      } else if (domain == 'fitness') {
        _loadingMessage = 'Reviewing your workout split, goals & muscle recovery...';
      } else if (domain == 'study') {
        _loadingMessage = 'Synthesizing study curriculum & focus intervals...';
      } else if (domain == 'english') {
        _loadingMessage = 'Preparing linguistic feedback & phrasing suggestions...';
      } else {
        _loadingMessage = 'Synthesizing finance, fitness & productivity synergy...';
      }
    });
    _scrollToBottom();

    try {
      String aiResponse = '';
      final profile = ProfileService.instance;

      if (domain == 'finance') {
        final expenses = await DBHelper.instance.getExpenses();
        aiResponse = await GeminiService.instance.askFinanceQuestion(cleanQuery, expenses);
      } else if (domain == 'fitness') {
        final workouts = await DBHelper.instance.getWorkoutPlans();
        aiResponse = await GeminiService.instance.askFitnessAi(
          query: cleanQuery,
          currentWeight: profile.weightKg,
          targetWeight: profile.targetWeightKg,
          goal: profile.fitnessGoal,
          equipment: profile.availableEquipment,
          weeklyPlan: workouts,
        );
      } else if (domain == 'study') {
        final studyService = StudyEnglishService.instance;
        aiResponse = '''🎓 **Study & Academic Optimization Plan**

* **Recommended Strategy for "$cleanQuery"**:
  1. **Focus Sprints**: Allocate two 45-minute Pomodoro sessions with zero digital distraction.
  2. **Active Recall**: Immediately after reading, write down 3 key principles without looking at notes.
  3. **Current Curriculum Status**: You have **${studyService.totalCompletedTopics} completed topics** and **${studyService.totalPendingTopics} pending topics**.

💡 **Pro-Tip**: Schedule this session in your **7-Day Study Planner** tab to maintain your **${studyService.studyStreakDays}-day streak**!''';
      } else if (domain == 'english') {
        aiResponse = '''🇬🇧 **English Fluency & Communication Coaching**

* **Core Guidance on "$cleanQuery"**:
  1. **Professional Phrasing**: Use concise, confident verbs (e.g., "engineered", "orchestrated", "articulated").
  2. **Clarity**: Structure responses using the **STAR Method** (Situation, Task, Action, Result) for behavioral questions.
  3. **Daily Practice**: Spend 5 minutes reading aloud with the **Reading Stopwatch** to build smooth cadence and rhythm.

⚡ **Next Action**: Head over to the **AI Speaking & STT** module to record a real-time pronunciation drill!''';
      } else {
        final expenses = await DBHelper.instance.getExpenses();
        final currentDebited = expenses.where((t) => t['is_income'] != 1 && t['is_income'] != true).fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0.0));
        aiResponse = await GeminiService.instance.askCombinedAi(
          query: cleanQuery,
          monthlyBudget: profile.monthlyBudgetCap,
          currentDebited: currentDebited,
          currentWeight: profile.weightKg,
          goal: profile.fitnessGoal,
        );
      }

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: aiResponse, isUser: false, domain: domain, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: 'Could not process query: $e. Please check your network or API key in Settings.',
              isUser: false,
              domain: domain,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('AI Life & Performance Coach', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _domainTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 16), text: 'Finance AI'),
            Tab(icon: Icon(Icons.fitness_center_rounded, size: 16), text: 'Fitness AI'),
            Tab(icon: Icon(Icons.school_rounded, size: 16), text: 'Study AI'),
            Tab(icon: Icon(Icons.translate_rounded, size: 16), text: 'English AI'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 16), text: 'Combined Synergy'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Prompts Carousel based on active tab
          AnimatedBuilder(
            animation: _domainTabController,
            builder: (context, _) {
              final idx = _domainTabController.index;
              List<String> prompts = _quickFinancePrompts;
              Color chipColor = AppColors.secondary;
              if (idx == 1) {
                prompts = _quickFitnessPrompts;
                chipColor = AppColors.primaryGlow;
              } else if (idx == 2) {
                prompts = _quickStudyPrompts;
                chipColor = AppColors.accentAmber;
              } else if (idx == 3) {
                prompts = _quickEnglishPrompts;
                chipColor = AppColors.accentRose;
              } else if (idx == 4) {
                prompts = _quickCombinedPrompts;
                chipColor = AppColors.accentGreen;
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: prompts.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(p, style: TextStyle(fontSize: 11.5, color: chipColor, fontWeight: FontWeight.bold)),
                          backgroundColor: chipColor.withValues(alpha: 0.1),
                          side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
                          onPressed: () => _handleSendMessage(p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          // Message Thread
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(_loadingMessage, style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        hintText: 'Ask AI Coach anything across Fitness, Food, Finance, Study...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onSubmitted: (v) => _handleSendMessage(v),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: () => _handleSendMessage(_queryController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (msg.isError ? AppColors.accentRose.withValues(alpha: 0.15) : theme.cardColor),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
          ),
          border: !isUser ? Border.all(color: theme.dividerColor.withValues(alpha: 0.15)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentAmber),
                  SizedBox(width: 4),
                  Text(
                    'GET SET GO AI',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: isUser ? Colors.white : (msg.isError ? AppColors.accentRose : null),
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String domain;
  final DateTime timestamp;
  final bool isError;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.domain,
    required this.timestamp,
    this.isError = false,
  });
}
