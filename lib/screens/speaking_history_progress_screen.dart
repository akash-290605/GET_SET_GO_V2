import 'package:flutter/material.dart';
import '../models/study_english_models.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class SpeakingHistoryProgressScreen extends StatefulWidget {
  const SpeakingHistoryProgressScreen({super.key});

  @override
  State<SpeakingHistoryProgressScreen> createState() => _SpeakingHistoryProgressScreenState();
}

class _SpeakingHistoryProgressScreenState extends State<SpeakingHistoryProgressScreen>
    with SingleTickerProviderStateMixin {
  final StudyEnglishService _service = StudyEnglishService.instance;
  late TabController _tabController;
  String _historyFilter = 'All'; // 'All', 'Video Practice', 'Live Conversations'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _showEditGoalDialog() {
    int tempGoal = _service.dailySpeakingGoalMinutes;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.track_changes_rounded, color: AppColors.primaryGlow, size: 22),
              SizedBox(width: 8),
              Text('Daily English Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set your daily target for active English speaking practice:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: tempGoal > 5 ? () => setDlgState(() => tempGoal -= 5) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('$tempGoal min/day', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: tempGoal < 60 ? () => setDlgState(() => tempGoal += 5) : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                await _service.setDailySpeakingGoal(tempGoal);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '$m min $s sec';
    if (m > 0) return '$m min';
    return '$s sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.insights_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('Speaking History & Progress', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: Theme.of(context).hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'My Speaking History'),
            Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: 'Progress Tracking'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpeakingHistoryTab(isDark),
          _buildProgressTrackingTab(isDark),
        ],
      ),
    );
  }

  // ================= 1. SPEAKING HISTORY TAB =================
  Widget _buildSpeakingHistoryTab(bool isDark) {
    final records = _service.speakingRecords;
    final sessions = _service.conversationSessions;

    // Filter list
    final List<dynamic> combinedList = [];
    if (_historyFilter == 'All' || _historyFilter == 'Video Practice') {
      combinedList.addAll(records);
    }
    if (_historyFilter == 'All' || _historyFilter == 'Live Conversations') {
      combinedList.addAll(sessions);
    }

    // Sort by date descending
    combinedList.sort((a, b) {
      final dtA = a is SpeakingPracticeRecord ? a.createdAt : (a as LiveConversationSession).createdAt;
      final dtB = b is SpeakingPracticeRecord ? b.createdAt : (b as LiveConversationSession).createdAt;
      return dtB.compareTo(dtA);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Top Streak & Total Speaking Card
          _buildExecutiveStatsCard(isDark),
          const SizedBox(height: 14),

          // Daily English Goal Card (Requirement 22)
          _buildDailyGoalCard(isDark),
          const SizedBox(height: 16),

          // Section Header & Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: AppColors.primaryGlow, size: 18),
                  SizedBox(width: 6),
                  Text('ALL RECORDED SESSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 1.1)),
                ],
              ),
              DropdownButton<String>(
                value: _historyFilter,
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Types', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Video Practice', child: Text('Video/Audio Practice', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Live Conversations', child: Text('Live Conversations', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _historyFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (combinedList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.mic_none_rounded, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text('No speaking practices found.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Complete an AI Speaking Practice or Live Chat to see it here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            ...combinedList.map((item) {
              if (item is SpeakingPracticeRecord) {
                return _buildSpeakingPracticeRecordTile(isDark, item);
              } else {
                return _buildLiveConversationSessionTile(isDark, item as LiveConversationSession);
              }
            }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExecutiveStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: AppColors.accentRose, size: 24),
                  SizedBox(width: 8),
                  Text('ENGLISH MASTERY STREAK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔥 ${_service.currentSpeakingStreakDays} DAYS STREAK',
                  style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildExecutiveMetric('Speaking Streak', '${_service.currentSpeakingStreakDays} days', AppColors.accentRose),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildExecutiveMetric('Total Speaking', _service.totalSpeakingFormatted, AppColors.accentBlue),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildExecutiveMetric('Practices', '${_service.totalPracticesAndConversationsCount}', AppColors.accentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildDailyGoalCard(bool isDark) {
    final todayMins = _service.todaySpeakingMinutes;
    final targetMins = _service.dailySpeakingGoalMinutes;
    final progress = targetMins > 0 ? (todayMins / targetMins).clamp(0.0, 1.0) : 0.0;
    final status = _service.todayGoalStatus;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_rounded, color: AppColors.accentGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('DAILY ENGLISH GOAL: $targetMins MIN/DAY',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentGreen, letterSpacing: 1.1)),
                ],
              ),
              TextButton.icon(
                onPressed: _showEditGoalDialog,
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit Goal', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Speaking: $todayMins / $targetMins minutes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (status == 'Completed' ? AppColors.accentGreen : AppColors.accentAmber).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Status: $status',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'Completed' ? AppColors.accentGreen : AppColors.accentAmber,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(status == 'Completed' ? AppColors.accentGreen : AppColors.primaryGlow),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This actual data is included in your 9 PM daily notification check-in.',
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  // --- Speaking Practice Record Tile (Requirement 11) ---
  Widget _buildSpeakingPracticeRecordTile(bool isDark, SpeakingPracticeRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.videocam_rounded, color: AppColors.primaryGlow, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Topic: ${r.topic}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(r.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text('⏱️ Duration: ${_formatDuration(r.durationSeconds)}', style: const TextStyle(fontSize: 11.5)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Corrections: ${r.corrections.length}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
              ),
              const Spacer(),
              Text('${r.fluencyScore.toStringAsFixed(0)}% Fluency', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showSpeakingPracticeDetailModal(r),
      ),
    );
  }

  // --- Live Conversation Session Tile ---
  Widget _buildLiveConversationSessionTile(bool isDark, LiveConversationSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(s.mode.iconEmoji, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${s.mode.label}: ${s.topic}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(s.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text('⏱️ Duration: ${_formatDuration(s.durationSeconds)}', style: const TextStyle(fontSize: 11.5)),
              const SizedBox(width: 12),
              Text('~${s.wordsSpokenApprox} words', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s.level.label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showLiveConversationDetailModal(s),
      ),
    );
  }

  // --- Complete Speaking Analysis Detail Modal (Requirement 11) ---
  void _showSpeakingPracticeDetailModal(SpeakingPracticeRecord r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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

              // Title Bar with Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('${r.date} at ${r.time} • ${_formatDuration(r.durationSeconds)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                    tooltip: 'Delete Record',
                    onPressed: () {
                      _service.deleteSpeakingRecord(r.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted.')));
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Your Speech Transcript
              const Text('### Your Speech', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('“${r.transcript}”', style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),

              // 2. Fluency Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildModalMetric('Words', '${r.wordsCount}'),
                  _buildModalMetric('Speaking Pace', '${r.wordsPerMinute} wpm'),
                  _buildModalMetric('Filler Words', '${r.fillerWordsCount}'),
                  _buildModalMetric('Score', '${r.fluencyScore.toStringAsFixed(0)}%'),
                ],
              ),
              const Divider(height: 24),

              // 3. Show Every Correction Individually (Requirement 4)
              Text('Corrections (${r.corrections.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              if (r.corrections.isEmpty)
                const Text('No grammatical corrections needed. Perfect delivery!', style: TextStyle(fontSize: 13, color: AppColors.accentGreen))
              else
                ...r.corrections.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                child: Text('${c.category} • ${c.subcategory}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('You said: "${c.originalText}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.accentRose)),
                          const SizedBox(height: 2),
                          Text('Correction: "${c.correctedText}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.accentGreen)),
                          const SizedBox(height: 4),
                          Text('Why: ${c.whyWrong}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text('More natural: "${c.moreNaturalWay}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.primaryGlow)),
                        ],
                      ),
                    )),

              const Divider(height: 24),

              // 4. Practical Feedback
              if (r.whatYouDidWell.isNotEmpty) ...[
                const Text('What You Did Well:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGreen)),
                const SizedBox(height: 4),
                ...r.whatYouDidWell.map((w) => Text('✓ $w', style: const TextStyle(fontSize: 12.5))),
                const SizedBox(height: 10),
              ],

              if (r.improveThese.isNotEmpty) ...[
                const Text('Improve These:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentAmber)),
                const SizedBox(height: 4),
                ...r.improveThese.map((i) => Text('• $i', style: const TextStyle(fontSize: 12.5))),
                const SizedBox(height: 12),
              ],

              // 5. Better Version Rewrite
              const Text('Better Version:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2)),
                ),
                child: Text(r.betterVersion, style: const TextStyle(fontSize: 12.5, height: 1.4)),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveConversationDetailModal(LiveConversationSession s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.mode.label}: ${s.topic}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('${s.date} • ${_formatDuration(s.durationSeconds)} • ${s.level.label}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                    tooltip: 'Delete Session',
                    onPressed: () {
                      _service.deleteConversationSession(s.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted.')));
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // Dialogue messages
              const Text('Transcript / Conversation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              ...s.messages.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: m.role == 'ai' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Text(m.role == 'ai' ? '🤖 AI' : 'You', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: m.role == 'ai' ? AppColors.primary.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(m.text, style: const TextStyle(fontSize: 12.5)),
                        ),
                        if (m.liveCorrection != null)
                          Text('💡 ${m.liveCorrection!}', style: const TextStyle(fontSize: 11, color: AppColors.accentAmber, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  )),

              const Divider(height: 24),
              Text('Recommended Practice: ${s.recommendedPractice}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('What to Practice Next: ${s.whatToPracticeNext}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  // ================= 2. PROGRESS TRACKING TAB (Requirement 12) =================
  Widget _buildProgressTrackingTab(bool isDark) {
    final records = _service.speakingRecords;

    // Check if enough data exists
    if (records.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.query_stats_rounded, size: 56, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Complete more speaking practices to see your progress.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'As you record speaking sessions, your fluency curve, words spoken, grammar corrections, and filler word reductions will automatically be charted here.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Compute progress metrics
    final totalWords = records.fold<int>(0, (sum, r) => sum + r.wordsCount);
    final totalCorrections = records.fold<int>(0, (sum, r) => sum + r.corrections.length);
    final avgCorrectionsPerSession = (totalCorrections / records.length).toStringAsFixed(1);
    final totalFillers = records.fold<int>(0, (sum, r) => sum + r.fillerWordsCount);
    final avgFluency = (records.fold<double>(0, (sum, r) => sum + r.fluencyScore) / records.length).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Metrics Grid
          Row(
            children: [
              _buildProgressMetricCard('Total Words Spoken', '$totalWords', Icons.record_voice_over_rounded, AppColors.accentBlue),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Avg Fluency Score', '$avgFluency%', Icons.auto_awesome_rounded, AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildProgressMetricCard('Avg Corrections', '$avgCorrectionsPerSession / session', Icons.rule_rounded, AppColors.accentAmber),
              const SizedBox(width: 10),
              _buildProgressMetricCard('Total Fillers Counted', '$totalFillers', Icons.chat_bubble_outline_rounded, AppColors.accentRose),
            ],
          ),
          const SizedBox(height: 16),

          // Speaking Duration Over Time (Requirement 12)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 8),
                    Text('SPEAKING DURATION OVER TIME (MINUTES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentBlue, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSpeakingDurationBarChart(records),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fluency Trend Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.accentGreen, size: 18),
                    SizedBox(width: 8),
                    Text('FLUENCY & ACCURACY TREND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentGreen, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),
                ...records.take(5).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(r.topic, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (r.fluencyScore / 100).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(r.fluencyScore >= 85 ? AppColors.accentGreen : AppColors.accentAmber),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${r.fluencyScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vocabulary Improvements Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: AppColors.accentPurple, size: 18),
                    SizedBox(width: 8),
                    Text('VOCABULARY UPGRADES MASTERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentPurple, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    'Transformative',
                    'Beneficial',
                    'Relentless',
                    'Meticulous',
                    'Articulate',
                    'Pragmatic',
                    'Ubiquitous',
                    'Pioneering',
                    'Architecture',
                    'Milestone',
                    'Cohesive',
                  ].map((v) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(v, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
                      )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingDurationBarChart(List<SpeakingPracticeRecord> records) {
    final recent = records.take(7).toList().reversed.toList();
    final maxSec = recent.map((r) => r.durationSeconds).fold<int>(60, (max, v) => v > max ? v : max);

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recent.map((r) {
          final frac = (r.durationSeconds / maxSec).clamp(0.15, 1.0);
          final mins = (r.durationSeconds / 60).toStringAsFixed(1);
          final datePart = r.date.length >= 10 ? r.date.substring(5) : r.date;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${mins}m', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 70 * frac,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.primaryGlow],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(datePart, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
