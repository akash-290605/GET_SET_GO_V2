import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemini_service.dart';
import '../db_helper.dart';

class AiCoachScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AiCoachScreen({super.key, this.onBack});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GeminiMessage> _messages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialGreeting();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialGreeting() {
    _messages.add(
      GeminiMessage(
        role: 'model',
        text: '''
👋 **Welcome to TITAN AI Intelligence Hub.**

I am your personal AI strategist engineered for:
• 💰 **Finance & Expense Reduction**: Finding leaks and maximizing your cashflow.
• 🏋️ **Gym & Hypertrophy Splits**: Tailoring volume tonnage and set progression.
• 🥗 **Macronutrient Optimization**: High-protein diet and calorie partitioning.
• ⚡ **Daily Discipline & Habit Architecture**: Crushing procrastination and hitting streaks.

*How can I optimize your performance today?*
''',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage([String? presetPrompt]) async {
    final query = presetPrompt ?? _inputController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(GeminiMessage(role: 'user', text: query, timestamp: DateTime.now()));
      _isLoading = true;
    });

    if (presetPrompt == null) {
      _inputController.clear();
    }

    _scrollToBottom();

    try {
      String responseText;
      if (query.toLowerCase().contains('expense') || query.toLowerCase().contains('financial') || query.toLowerCase().contains('leak')) {
        final expenses = await DBHelper.instance.getExpenses();
        double totalCredited = 0;
        double totalDebited = 0;
        for (final exp in expenses) {
          final isCredit = (exp['isCredit'] ?? 0) == 1;
          final amt = ((exp['amount'] as num?) ?? 0).toDouble();
          if (isCredit) {
            totalCredited += amt;
          } else {
            totalDebited += amt;
          }
        }
        responseText = await GeminiService.instance.analyzeExpenses(
          expenses: expenses,
          targetMonthlyCap: 15000,
          totalCredited: totalCredited,
          totalDebited: totalDebited,
        );
      } else {
        responseText = await GeminiService.instance.askAi(query, history: _messages);
      }

      if (mounted) {
        setState(() {
          _messages.add(GeminiMessage(role: 'model', text: responseText, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(GeminiMessage(
            role: 'model',
            text: '⚠️ An error occurred: $e\n\nTitan Offline Engine is active.',
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
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

  void _showApiKeyDialog() async {
    final currentKey = await GeminiService.instance.getApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18223C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 10),
            Text(
              'Gemini API Settings',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key for online 1.5 Flash cloud models. If left blank, Titan uses the built-in neural offline engine.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF11182B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: keyController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await GeminiService.instance.setApiKey(keyController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gemini API Key configuration updated!'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text('Save Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF090D18);
    const surface = Color(0xFF11182B);
    const surfaceElevated = Color(0xFF18223C);
    const primary = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'TITAN AI COACH',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                ),
                Text(
                  'Gemini 1.5 Flash + Neural Offline',
                  style: TextStyle(fontSize: 11, color: Color(0xFF06B6D4)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gemini API Key Config',
            icon: const Icon(Icons.key_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: () {
              setState(() {
                _messages.clear();
                _loadInitialGreeting();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: surface.withValues(alpha: 0.6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(
                    '💰 Reduce Expenses',
                    'Analyze my expenses and recommend 3 actionable cuts.',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    '🏋️ 7-Day Gym Split',
                    'Give me a complete 7-day hypertrophy gym split with set and rep ranges.',
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    '🥗 High-Protein Diet',
                    'Give me a clean high-protein meal plan for lean muscle growth.',
                    const Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    '🔥 Discipline Directive',
                    'Give me an intense mindset reset and daily discipline checklist.',
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Ask Titan about workouts, diets, expenses...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primary, Color(0xFF7C3AED)],
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt, Color color) {
    return InkWell(
      onTap: () => _sendMessage(prompt),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GeminiMessage msg) {
    final isUser = msg.role == 'user';
    const surfaceElevated = Color(0xFF18223C);
    const primary = Color(0xFF8B5CF6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.bolt_rounded, color: primary, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? primary : surfaceElevated,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                  bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: Border.all(
                  color: isUser ? primary.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFFF1F5F9),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white60 : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied response to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    const surfaceElevated = Color(0xFF18223C);
    const primary = Color(0xFF8B5CF6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: primary, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceElevated,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                ),
                SizedBox(width: 10),
                Text(
                  'Titan AI analyzing...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
