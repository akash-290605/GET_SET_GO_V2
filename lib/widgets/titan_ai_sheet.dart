import 'package:flutter/material.dart';
import '../main.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';

/// Titan AI Discipline Coach Modal Sheet
class TitanAICoachSheet extends StatefulWidget {
  final String? initialPrompt;
  const TitanAICoachSheet({super.key, this.initialPrompt});

  static void show(BuildContext context, {String? initialPrompt}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => TitanAICoachSheet(initialPrompt: initialPrompt),
    );
  }

  @override
  State<TitanAICoachSheet> createState() => _TitanAICoachSheetState();
}

class _TitanAICoachSheetState extends State<TitanAICoachSheet> {
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'ai',
      'text': '⚡ **TITAN AI DISCIPLINE ORACLE ACTIVE**\n\nI am your elite performance, workout, nutrition, and financial discipline engine. What target are we conquering today?',
    });

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _sendQuery(widget.initialPrompt!);
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendQuery(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _promptCtrl.clear();

    _scrollToBottom();

    final user = AuthService.instance.currentUser;
    final appContext = {
      'userName': user.displayName,
      'weightKg': user.weightKg,
      'goal': user.fitnessGoal,
      'budget': user.monthlyExpenseBudget,
      'walkKm': WorkoutState.walkDistanceKm,
      'jogKm': WorkoutState.jogDistanceKm,
      'totalDistance': WorkoutState.totalDistanceKm,
    };

    final response = await GeminiService.instance.askAICoach(
      prompt: text,
      userContext: appContext,
    );

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: GeminiService.instance.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppColors.secondary, size: 22),
            SizedBox(width: 8),
            Text('Gemini API Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API Key for live AI model inference. If left empty, Titan AI will automatically use the built-in High-IQ Neural Offline Engine.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Google Gemini API Key',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              GeminiService.instance.setApiKey(keyCtrl.text.trim());
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚡ Gemini API Key updated!')),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('TITAN AI COACH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GeminiService.instance.hasCustomKey ? AppColors.accentGreen.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                GeminiService.instance.hasCustomKey ? 'GEMINI 1.5' : 'OFFLINE ENGINE',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: GeminiService.instance.hasCustomKey ? AppColors.accentGreen : AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                        const Text('Discipline, Workout, Nutrition & Wealth Intelligence', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.key_rounded, size: 20, color: AppColors.textMuted),
                    tooltip: 'Configure Gemini API Key',
                    onPressed: _showApiKeyDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick Prompt Suggestion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPromptChip('🏋️ Today\'s Gym Strategy', 'Recommend progressive overload & set protocol for today\'s gym session.'),
                  _buildPromptChip('🥗 Meal Fuel Audit', 'How to optimize my daily meal protein timing and eliminate cravings?'),
                  _buildPromptChip('💰 Expense Discipline', 'Audit my spending habits and give me 3 strict rules to save money this month.'),
                  _buildPromptChip('🔥 Habit Roast & Boost', 'Give me a ruthless Spartan discipline speech to crush all excuses today.'),
                ],
              ),
            ),
            const Divider(height: 18, color: AppColors.borderLight),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)),
                          SizedBox(width: 10),
                          Text('Titan AI is analyzing your performance metrics...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }

                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(18),
                          bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(18),
                        ),
                        border: Border.all(
                          color: isUser ? AppColors.primaryGlow : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: SelectableText(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white,
                          fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar with Safe Keyboard Padding
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendQuery,
                      decoration: const InputDecoration(
                        hintText: 'Ask Titan AI (Workout, Food, Wealth, Habits)...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () => _sendQuery(_promptCtrl.text),
                    icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String title, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.borderLight),
        label: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        onPressed: () => _sendQuery(query),
      ),
    );
  }
}
