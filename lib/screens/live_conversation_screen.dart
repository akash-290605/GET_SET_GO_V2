import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_english_models.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';
import 'speaking_history_progress_screen.dart';

class LiveConversationScreen extends StatefulWidget {
  final LiveConversationMode initialMode;
  final String? initialTopic;

  const LiveConversationScreen({
    super.key,
    this.initialMode = LiveConversationMode.general,
    this.initialTopic,
  });

  @override
  State<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends State<LiveConversationScreen>
    with TickerProviderStateMixin {
  final StudyEnglishService _englishService = StudyEnglishService.instance;
  final GeminiService _geminiService = GeminiService.instance;

  // Configuration
  late LiveConversationMode _mode;
  EnglishLevel _level = EnglishLevel.intermediate;
  bool _isCorrectionEnabled = true;

  // Topics
  final List<String> _topicSuggestions = [
    'Daily life',
    'College',
    'Job interview',
    'Electronics',
    'VLSI',
    'Technology',
    'AI',
    'Fitness',
    'Travel',
    'Movies',
    'Sports',
    'Hobbies',
    'Career',
    'Current events',
    'Science',
    'Random topic',
    'Debate',
    'Group discussion',
  ];

  late String _selectedTopic;
  final TextEditingController _customTopicCtrl = TextEditingController();
  bool _isCustomTopic = false;

  // Conversation Session State
  bool _isSessionActive = false;
  int _sessionDurationSeconds = 0;
  Timer? _sessionTimer;

  // Audio / Speech State
  bool _isMuted = false;
  bool _isUserSpeaking = false;
  bool _isAiResponding = false;
  final TextEditingController _textInputCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Waveform Animation Controller
  late AnimationController _waveformCtrl;

  // Messages in Current Conversation
  final List<LiveConversationMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedTopic = widget.initialTopic ??
        (_mode == LiveConversationMode.interview
            ? 'Job interview'
            : (_mode == LiveConversationMode.debate ? 'Is artificial intelligence good for society?' : 'Artificial Intelligence'));

    _waveformCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _waveformCtrl.dispose();
    _customTopicCtrl.dispose();
    _textInputCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _currentEffectiveTopic {
    if (_isCustomTopic && _customTopicCtrl.text.trim().isNotEmpty) {
      return _customTopicCtrl.text.trim();
    }
    return _selectedTopic;
  }

  // --- Session Control ---
  void _startConversation() {
    final topic = _currentEffectiveTopic;
    setState(() {
      _isSessionActive = true;
      _sessionDurationSeconds = 0;
      _messages.clear();
      _isAiResponding = true;
    });

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _sessionDurationSeconds++);
      }
    });

    // Initial greeting from AI tailored to mode and level
    String initialGreeting;
    if (_mode == LiveConversationMode.interview) {
      initialGreeting = 'Hi ${AuthService.instance.currentUser?.displayName ?? 'Akash'}! Welcome to your interview session on "$topic". To begin, could you tell me a little about yourself and your background?';
    } else if (_mode == LiveConversationMode.debate) {
      initialGreeting = 'Welcome to today\'s debate on "$topic". I will be challenging your arguments respectfully. In your perspective, what is the primary reason supporting your stance?';
    } else {
      initialGreeting = 'Hi ${AuthService.instance.currentUser?.displayName ?? 'Akash'}! It is great to chat today. Let\'s talk about "$topic". What got you interested in this topic?';
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(LiveConversationMessage(
          role: 'ai',
          text: initialGreeting,
          timestamp: DateTime.now(),
        ));
        _isAiResponding = false;
      });
    });
  }

  Future<void> _endConversation() async {
    _sessionTimer?.cancel();

    if (_messages.isEmpty) {
      setState(() => _isSessionActive = false);
      return;
    }

    setState(() => _isAiResponding = true);

    try {
      final summary = await _geminiService.generateConversationSummary(
        topic: _currentEffectiveTopic,
        durationSeconds: _sessionDurationSeconds > 0 ? _sessionDurationSeconds : 60,
        messages: _messages,
      );

      final session = LiveConversationSession(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        userId: AuthService.instance.uid,
        date: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
        topic: _currentEffectiveTopic,
        durationSeconds: _sessionDurationSeconds,
        mode: _mode,
        level: _level,
        isCorrectionEnabled: _isCorrectionEnabled,
        messages: List.from(_messages),
        wordsSpokenApprox: summary['wordsSpokenApprox'] ?? 0,
        commonFillers: Map<String, int>.from(summary['commonFillers'] ?? {}),
        grammarIssues: List<String>.from(summary['grammarIssues'] ?? []),
        newVocabulary: List<String>.from(summary['newVocabulary'] ?? []),
        recommendedPractice: summary['recommendedPractice'] ?? '',
        whatToPracticeNext: summary['whatToPracticeNext'] ?? '',
        createdAt: DateTime.now(),
      );

      await _englishService.saveConversationSession(session);

      if (mounted) {
        setState(() {
          _isSessionActive = false;
          _isAiResponding = false;
        });

        _showConversationSummaryModal(session);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSessionActive = false;
          _isAiResponding = false;
        });
      }
    }
  }

  // --- Send Message & AI Response ---
  Future<void> _sendMessage(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) return;

    _textInputCtrl.clear();
    final userMsg = LiveConversationMessage(
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isUserSpeaking = false;
      _isAiResponding = true;
    });

    _scrollToBottom();

    // Call Gemini Live Conversation Turn
    final turn = await _geminiService.generateLiveConversationTurn(
      topic: _currentEffectiveTopic,
      level: _level,
      mode: _mode,
      isCorrectionEnabled: _isCorrectionEnabled,
      history: _messages,
      userMessage: text,
    );

    if (!mounted) return;

    final reply = turn['reply'] ?? 'That is a compelling point! How do you envision this evolving?';
    final correction = turn['correction'];

    setState(() {
      _messages.add(LiveConversationMessage(
        role: 'ai',
        text: reply,
        liveCorrection: _isCorrectionEnabled ? correction : null,
        timestamp: DateTime.now(),
      ));
      _isAiResponding = false;
    });

    _scrollToBottom();
  }

  void _simulateSpeakingInput() {
    if (_isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone is muted. Unmute to speak.')),
      );
      return;
    }

    setState(() => _isUserSpeaking = !_isUserSpeaking);

    if (_isUserSpeaking) {
      // Simulate real-time speaking transcription for realistic testing
      Timer(const Duration(seconds: 4), () {
        if (!mounted || !_isUserSpeaking) return;
        final samplePhrases = [
          'In my college we are working on digital logic and VLSI design projects.',
          'Yesterday I am going to college and I meet my friends to discuss our project.',
          'I am working in this project from two months and we are getting great results.',
          'I believe artificial intelligence is very very good for future engineering automation.',
        ];
        final picked = samplePhrases[(_messages.length ~/ 2) % samplePhrases.length];
        _sendMessage(picked);
      });
    }
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

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Text(_mode.iconEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _mode == LiveConversationMode.interview
                  ? 'Job Interview Practice'
                  : (_mode == LiveConversationMode.debate ? 'Debate Practice' : 'Live English Chat'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          if (_isSessionActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record_rounded, color: AppColors.accentRose, size: 10),
                  const SizedBox(width: 4),
                  Text(_formatTimer(_sessionDurationSeconds),
                      style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Speaking History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpeakingHistoryProgressScreen()),
              );
            },
          ),
        ],
      ),
      body: _isSessionActive
          ? _buildActiveConversationBody(isDark)
          : _buildSetupBody(isDark),
    );
  }

  // ================= 1. SETUP / PRE-CONVERSATION VIEW =================
  Widget _buildSetupBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Switcher Banner
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRACTICE MODE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildModeButton(LiveConversationMode.general, '🗣️ General Chat'),
                    const SizedBox(width: 6),
                    _buildModeButton(LiveConversationMode.interview, '💼 Job Interview'),
                    const SizedBox(width: 6),
                    _buildModeButton(LiveConversationMode.debate, '⚔️ Debate'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Topic Selector Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.topic_rounded, color: AppColors.accentBlue, size: 18),
                        SizedBox(width: 6),
                        Text('CONVERSATION TOPIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentBlue, letterSpacing: 1.1)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Custom', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _isCustomTopic,
                          onChanged: (val) => setState(() => _isCustomTopic = val),
                          activeThumbColor: AppColors.accentBlue,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isCustomTopic)
                  TextField(
                    controller: _customTopicCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Let\'s talk about artificial intelligence.',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _topicSuggestions.contains(_selectedTopic) ? _selectedTopic : _topicSuggestions.first,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _topicSuggestions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13.5)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTopic = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _topicSuggestions.take(8).map((t) {
                      final isSel = _selectedTopic == t;
                      return ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        onSelected: (s) {
                          if (s) setState(() => _selectedTopic = t);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Difficulty Level & Live Correction Toggle
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.accentPurple, size: 18),
                    SizedBox(width: 6),
                    Text('CONVERSATION SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentPurple, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),

                // English Level (Requirement 18)
                const Text('English Proficiency Level:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EnglishLevel.values.map((lvl) {
                      final isSel = _level == lvl;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(lvl.label, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          onSelected: (s) => setState(() => _level = lvl),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _level.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),

                const Divider(height: 20),

                // Live Correction Mode (Requirement 17)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live Correction Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Offers gentle natural corrections without interrupting flow', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    Switch(
                      value: _isCorrectionEnabled,
                      onChanged: (val) => setState(() => _isCorrectionEnabled = val),
                      activeThumbColor: AppColors.accentGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _startConversation,
              icon: const Icon(Icons.record_voice_over_rounded, size: 22),
              label: Text(
                'Start ${_mode.label}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(LiveConversationMode mode, String label) {
    final isSelected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryGlow : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ================= 2. ACTIVE CONVERSATION UI =================
  Widget _buildActiveConversationBody(bool isDark) {
    return Column(
      children: [
        // Top Banner / Status Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record_rounded, color: AppColors.accentRose, size: 10),
                        SizedBox(width: 4),
                        Text('🔴 LIVE', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_mode.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Level: ${_level.label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Messages List View
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isAiResponding ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isAiResponding) {
                return _buildAiThinkingBubble(isDark);
              }
              final msg = _messages[index];
              return _buildMessageBubble(isDark, msg);
            },
          ),
        ),

        // Live Audio Waveform & Speaking Status (Requirement 15)
        if (_isUserSpeaking) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppColors.accentGreen.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_rounded, color: AppColors.accentGreen, size: 18),
                const SizedBox(width: 8),
                const Text('🎤 You are speaking...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentGreen)),
                const SizedBox(width: 14),
                _buildLiveWaveform(),
              ],
            ),
          ),
        ],

        // Bottom Controls: Mic, Mute, Text Input, End Conversation
        _buildBottomControlBar(isDark),
      ],
    );
  }

  Widget _buildAiThinkingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGlow),
            ),
            SizedBox(width: 8),
            Text('AI is formulating response...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(bool isDark, LiveConversationMessage msg) {
    final isAi = msg.role == 'ai';

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Sender label
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAi) const Text('🤖 AI Partner • ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow))
                  else const Text('You • ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Message Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isAi
                    ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                    : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isAi ? const Radius.circular(4) : const Radius.circular(16),
                  bottomRight: isAi ? const Radius.circular(16) : const Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isAi ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Live Correction Bubble (Requirement 17)
            if (msg.liveCorrection != null && msg.liveCorrection!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high_rounded, size: 14, color: AppColors.accentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        msg.liveCorrection!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.accentAmber, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWaveform() {
    return AnimatedBuilder(
      animation: _waveformCtrl,
      builder: (context, _) {
        return Row(
          children: List.generate(6, (i) {
            final h = 6 + (14 * ((_waveformCtrl.value + (i * 0.15)) % 1.0));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  // --- Bottom Control Bar ---
  Widget _buildBottomControlBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textInputCtrl,
                  decoration: InputDecoration(
                    hintText: 'Respond in English...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) _sendMessage(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () {
                  if (_textInputCtrl.text.trim().isNotEmpty) {
                    _sendMessage(_textInputCtrl.text);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Speaking & End Conversation Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mute Button
              IconButton.outlined(
                tooltip: _isMuted ? 'Unmute' : 'Mute Microphone',
                icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isMuted ? AppColors.accentRose : AppColors.accentGreen),
                onPressed: () => setState(() => _isMuted = !_isMuted),
              ),

              // Speak Push-To-Talk Simulator / Speech Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUserSpeaking ? AppColors.accentRose : AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _simulateSpeakingInput,
                icon: Icon(_isUserSpeaking ? Icons.stop_rounded : Icons.mic_rounded, size: 18),
                label: Text(_isUserSpeaking ? 'Stop Speaking' : 'Tap to Speak',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),

              // End Conversation Button (Requirement 21)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRose.withValues(alpha: 0.15),
                  foregroundColor: AppColors.accentRose,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _endConversation,
                icon: const Icon(Icons.call_end_rounded, size: 18),
                label: const Text('End Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. CONVERSATION END SUMMARY (Requirement 21) =================
  void _showConversationSummaryModal(LiveConversationSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: AppColors.primaryGlow, size: 24),
                  SizedBox(width: 8),
                  Text('Conversation Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),

              // Topic & Duration
              _buildSummaryRow('Topic', session.topic),
              _buildSummaryRow('Duration', '${session.durationSeconds ~/ 60} minutes'),
              _buildSummaryRow('Your speaking', 'Approximately ${session.wordsSpokenApprox} words'),

              const Divider(height: 24),

              // Common Fillers
              const Text('Common fillers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (session.commonFillers.isEmpty)
                const Text('None detected! Excellent conversational flow.', style: TextStyle(fontSize: 12, color: AppColors.accentGreen))
              else
                ...session.commonFillers.entries.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• "${f.key}" — ${f.value}', style: const TextStyle(fontSize: 12.5)),
                    )),

              const Divider(height: 24),

              // Common Grammar Issues
              const Text('Common grammar issue:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...session.grammarIssues.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                        Expanded(child: Text(g, style: const TextStyle(fontSize: 12.5, height: 1.3))),
                      ],
                    ),
                  )),

              const Divider(height: 24),

              // New Vocabulary
              const Text('New vocabulary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: session.newVocabulary.map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
                    )).toList(),
              ),

              const Divider(height: 24),

              // Recommended Practice
              const Text('Recommended practice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(session.recommendedPractice, style: const TextStyle(fontSize: 13, height: 1.3)),

              const SizedBox(height: 16),

              // What to Practice Next
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What to Practice Next:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.accentGreen)),
                    const SizedBox(height: 4),
                    Text(session.whatToPracticeNext, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Navigation Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SpeakingHistoryProgressScreen()),
                        );
                      },
                      child: const Text('View All History'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
