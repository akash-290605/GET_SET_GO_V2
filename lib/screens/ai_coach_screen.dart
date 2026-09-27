import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../services/gemini_service.dart';
import '../services/profile_service.dart';
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
    'Where did most of my money go?',
    'What are my potentially reducible expenses?',
    'Review my recurring subscriptions & bills',
    'Compare my spending against my monthly budget cap',
  ];

  final List<String> _quickFitnessPrompts = [
    'Create a 30-minute high-intensity workout',
    'Adjust today\'s workout for home (no gym equipment)',
    'Make today\'s workout easier with higher reps',
    'Which muscle groups need more recovery this week?',
  ];

  final List<String> _quickCombinedPrompts = [
    'Suggest affordable high-protein grocery options for my fitness goal',
    'Estimate the monthly financial cost of my fitness routine',
    'How can I optimize my nutrition and gym budget together?',
  ];

  @override
  void initState() {
    super.initState();
    _domainTabController = TabController(length: 3, vsync: this);
    // Initial welcome message
    _messages.add(
      _ChatMessage(
        text: 'Hello ${ProfileService.instance.userName}! I am your GET SET GO AI Life & Performance Coach.\n\nI analyze your actual fitness, finance, and nutrition data to give you personalized, actionable advice.',
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
    final domain = domainOverride ?? (activeDomainIndex == 0 ? 'finance' : activeDomainIndex == 1 ? 'fitness' : 'combined');

    _queryController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: cleanQuery, isUser: true, domain: domain, timestamp: DateTime.now()));
      _isLoading = true;
      if (domain == 'finance') {
        _loadingMessage = 'Analyzing your recent transactions & spending patterns...';
      } else if (domain == 'fitness') {
        _loadingMessage = 'Reviewing your workout split, goals & muscle recovery...';
      } else {
        _loadingMessage = 'Synthesizing finance & fitness budget synergy...';
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
        title: const Text('AI Coach & Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _domainTabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Finance AI'),
            Tab(icon: Icon(Icons.fitness_center_outlined), text: 'Fitness AI'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Combined Synergy'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick prompts bar depending on active domain
          _buildQuickPromptsBar(),
          const Divider(height: 1),

          // Chat history messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading typing indicator
          if (_isLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_loadingMessage, style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],

          // Input text bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Ask AI Coach anything...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (val) => _handleSendMessage(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_upward_rounded),
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

  Widget _buildQuickPromptsBar() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _domainTabController,
      builder: (context, _) {
        final idx = _domainTabController.index;
        final prompts = idx == 0
            ? _quickFinancePrompts
            : idx == 1
                ? _quickFitnessPrompts
                : _quickCombinedPrompts;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: theme.cardColor.withValues(alpha: 0.6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: prompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentAmber),
                    label: Text(p, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => _handleSendMessage(p),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : msg.isError
                  ? AppColors.accentRose.withValues(alpha: 0.15)
                  : theme.cardColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: !isUser ? Border.all(color: theme.dividerColor.withValues(alpha: 0.15)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentAmber),
                  const SizedBox(width: 6),
                  Text(
                    msg.domain == 'finance'
                        ? 'FINANCE AI'
                        : msg.domain == 'fitness'
                            ? 'FITNESS COACH'
                            : msg.domain == 'combined'
                                ? 'SYNERGY AI'
                                : 'AI COACH',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
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
