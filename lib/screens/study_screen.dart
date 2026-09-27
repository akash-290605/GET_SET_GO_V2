import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/study_english_models.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import 'english_learning_screen.dart';

class StudyAndEnglishScreen extends StatefulWidget {
  const StudyAndEnglishScreen({super.key});

  @override
  State<StudyAndEnglishScreen> createState() => _StudyAndEnglishScreenState();
}

class _StudyAndEnglishScreenState extends State<StudyAndEnglishScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final service = StudyEnglishService.instance;

  // Focus Timer / Pomodoro State
  bool _isPomodoroMode = false;
  final int _pomodoroWorkMinutes = 25;
  final int _pomodoroBreakMinutes = 5;
  bool _isPomodoroBreak = false;
  int _timerRemainingSeconds = 25 * 60;
  int _stopwatchElapsedSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _activeTimer;

  final TextEditingController _sessionSubjectCtrl = TextEditingController(text: 'Computer Science');
  final TextEditingController _sessionTopicCtrl = TextEditingController();

  List<Map<String, dynamic>> _studyLogs = [];
  bool _isLoadingLogs = true;

  // Selected day for 7-day planner
  String _selectedPlannerDay = 'Monday';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudyLogs();
    service.addListener(_onServiceChanged);

    // Set default day to today's weekday
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekday = DateTime.now().weekday - 1;
    _selectedPlannerDay = days[weekday.clamp(0, 6)];
  }

  @override
  void dispose() {
    service.removeListener(_onServiceChanged);
    _activeTimer?.cancel();
    _tabController.dispose();
    _sessionSubjectCtrl.dispose();
    _sessionTopicCtrl.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStudyLogs() async {
    setState(() => _isLoadingLogs = true);
    final data = await DBHelper.instance.getStudyLogs();
    if (mounted) {
      setState(() {
        _studyLogs = data;
        _isLoadingLogs = false;
      });
    }
  }

  // --- Timer Controls ---
  void _toggleTimer() {
    if (_isTimerRunning) {
      _activeTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_isPomodoroMode) {
          if (_timerRemainingSeconds > 0) {
            setState(() => _timerRemainingSeconds--);
          } else {
            // Pomodoro interval flip
            _activeTimer?.cancel();
            setState(() {
              _isTimerRunning = false;
              _isPomodoroBreak = !_isPomodoroBreak;
              _timerRemainingSeconds = (_isPomodoroBreak ? _pomodoroBreakMinutes : _pomodoroWorkMinutes) * 60;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isPomodoroBreak ? '🔔 Focus session complete! Take a 5 min break.' : '⚡ Break over! Ready to focus?'),
                backgroundColor: AppColors.accentGreen,
              ),
            );
          }
        } else {
          setState(() => _stopwatchElapsedSeconds++);
        }
      });
    }
  }

  void _resetTimer() {
    _activeTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _stopwatchElapsedSeconds = 0;
      _timerRemainingSeconds = _pomodoroWorkMinutes * 60;
      _isPomodoroBreak = false;
    });
  }

  String _formatTimer(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    final h = (totalSecs ~/ 3600);
    if (h > 0) {
      return '$h:${(m).padLeft(2, '0')}:$s';
    }
    return '$m:$s';
  }

  Future<void> _saveStudySession() async {
    final topic = _sessionTopicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a study topic / concept name.')),
      );
      return;
    }

    final durationSec = _isPomodoroMode ? (_pomodoroWorkMinutes * 60 - _timerRemainingSeconds) : _stopwatchElapsedSeconds;
    if (durationSec < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study duration must be at least 10 seconds.')),
      );
      return;
    }

    final mins = (durationSec / 60).ceil();
    final timeSpent = mins >= 60 ? '${(mins / 60).toStringAsFixed(1)} hrs' : '$mins mins';

    await DBHelper.instance.insertStudyLog({
      'subject': _sessionSubjectCtrl.text.trim().isEmpty ? 'General' : _sessionSubjectCtrl.text.trim(),
      'topic': topic,
      'desc': _isPomodoroMode ? 'Pomodoro Deep Focus' : 'Live Focus Stopwatch',
      'timeSpent': timeSpent,
      'date': DateTime.now().toIso8601String(),
    });

    _sessionTopicCtrl.clear();
    _resetTimer();
    await _loadStudyLogs();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved study session "$topic" ($timeSpent)! 🎓'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('Study & Academics Hub', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnglishLearningScreen())),
            icon: const Icon(Icons.translate_rounded, size: 16),
            label: const Text('English Suite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Subjects & Topics'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: '7-Day Planner'),
            Tab(icon: Icon(Icons.timer_outlined, size: 18), text: 'Focus & Pomodoro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsTab(),
          _buildPlannerTab(),
          _buildFocusTimerTab(),
        ],
      ),
    );
  }

  // ================= 1. SUBJECTS & TOPICS =================
  Widget _buildSubjectsTab() {
    final theme = Theme.of(context);
    final subjects = service.subjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Stats
          Row(
            children: [
              _buildStudyStatCard('Active Subjects', '${subjects.length}', AppColors.primaryGlow),
              const SizedBox(width: 8),
              _buildStudyStatCard('Mastered Topics', '${service.totalCompletedTopics}', AppColors.accentGreen),
              const SizedBox(width: 8),
              _buildStudyStatCard('Pending Topics', '${service.totalPendingTopics}', AppColors.accentAmber),
              const SizedBox(width: 8),
              _buildStudyStatCard('Study Streak', '${service.studyStreakDays} Days', AppColors.accentRose),
            ],
          ),
          const SizedBox(height: 16),

          // Add Subject Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Coursework & Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddSubjectDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subject Cards
          if (subjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('No subjects added yet. Tap "New Subject" to begin.')),
            )
          else
            ...subjects.map((s) => _buildSubjectCard(s)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStudyStatCard(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: theme.hintColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(StudySubject subject) {
    final theme = Theme.of(context);
    final color = Color(subject.colorValue);
    final progress = subject.completionProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(subject.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_task_rounded, size: 20, color: AppColors.primaryGlow),
                    tooltip: 'Add Topic',
                    onPressed: () => _showAddTopicDialog(context, subject),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
                    tooltip: 'Delete Subject',
                    onPressed: () => service.deleteSubject(subject.id),
                  ),
                ],
              ),
            ],
          ),
          if (subject.notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subject.notes, style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ],
          const SizedBox(height: 10),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${subject.topics.where((t) => t.isCompleted).length} of ${subject.topics.length} topics done', style: TextStyle(fontSize: 11, color: theme.hintColor)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),

          // Topics Checklist
          if (subject.topics.isNotEmpty) ...[
            ...subject.topics.map((topic) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: topic.isCompleted,
                      activeColor: color,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => service.toggleTopicCompletion(subject.id, topic.id),
                    ),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                          color: topic.isCompleted ? theme.hintColor : null,
                        ),
                      ),
                    ),
                    Text('${topic.estimatedMinutes}m', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Add Subject / Course', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Subject Name (e.g. Operating Systems)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Target Goals', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;
              final newSub = StudySubject(
                id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                name: n,
                notes: notesCtrl.text.trim(),
                colorValue: 0xFF8B5CF6,
              );
              await service.addSubject(newSub);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create Subject'),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog(BuildContext context, StudySubject subject) {
    final titleCtrl = TextEditingController();
    final minsCtrl = TextEditingController(text: '45');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Add Topic to ${subject.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Topic Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: minsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated Minutes', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final t = titleCtrl.text.trim();
              if (t.isEmpty) return;
              final mins = int.tryParse(minsCtrl.text.trim()) ?? 45;
              subject.topics.add(StudyTopic(id: 't_${DateTime.now().millisecondsSinceEpoch}', title: t, estimatedMinutes: mins));
              await service.saveSubjects();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  // ================= 2. 7-DAY STUDY PLANNER =================
  Widget _buildPlannerTab() {
    final theme = Theme.of(context);
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daySessions = service.plannerSessions.where((s) => s.dayName == _selectedPlannerDay).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: days.map((d) {
                final isSelected = _selectedPlannerDay == d;
                final count = service.plannerSessions.where((s) => s.dayName == d).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$d ($count)'),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedPlannerDay = d);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Planner Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedPlannerDay Study Plan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddPlannerSessionDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (daySessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No study sessions scheduled for this day.', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Tap "Add Session" to schedule focused topic slots.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ...daySessions.map((session) => _buildPlannerSessionCard(session)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlannerSessionCard(StudyPlannerSession session) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText;
    switch (session.status) {
      case StudySessionStatus.completed:
        statusColor = AppColors.accentGreen;
        statusText = 'Completed ✅';
        break;
      case StudySessionStatus.inProgress:
        statusColor = AppColors.accentAmber;
        statusText = 'In Progress ⏳';
        break;
      case StudySessionStatus.skipped:
        statusColor = AppColors.accentRose;
        statusText = 'Skipped ⏭️';
        break;
      case StudySessionStatus.planned:
        statusColor = AppColors.secondary;
        statusText = 'Planned 📌';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.school_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.topicTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text('${session.subjectName} • ${session.durationMinutes} mins', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
              ],
            ),
          ),
          PopupMenuButton<StudySessionStatus>(
            initialValue: session.status,
            onSelected: (st) => service.updateSessionStatus(session.id, st),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: StudySessionStatus.planned, child: Text('Planned 📌')),
              const PopupMenuItem(value: StudySessionStatus.inProgress, child: Text('In Progress ⏳')),
              const PopupMenuItem(value: StudySessionStatus.completed, child: Text('Completed ✅')),
              const PopupMenuItem(value: StudySessionStatus.skipped, child: Text('Skipped ⏭️')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
            onPressed: () => service.deletePlannerSession(session.id),
          ),
        ],
      ),
    );
  }

  void _showAddPlannerSessionDialog(BuildContext context) {
    final subCtrl = TextEditingController(text: 'Computer Science');
    final topicCtrl = TextEditingController();
    final minsCtrl = TextEditingController(text: '60');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Add Session for $_selectedPlannerDay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topic Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: minsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Minutes)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final top = topicCtrl.text.trim();
              if (top.isEmpty) return;
              final mins = int.tryParse(minsCtrl.text.trim()) ?? 60;
              final newSession = StudyPlannerSession(
                id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                dayName: _selectedPlannerDay,
                subjectName: subCtrl.text.trim(),
                topicTitle: top,
                durationMinutes: mins,
              );
              await service.addPlannerSession(newSession);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  // ================= 3. FOCUS TIMER & POMODORO =================
  Widget _buildFocusTimerTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Switcher (Stopwatch vs Pomodoro)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Live Focus Stopwatch', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: !_isPomodoroMode,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  onSelected: (sel) {
                    if (sel) {
                      _resetTimer();
                      setState(() => _isPomodoroMode = false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Pomodoro 25/5 Min', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _isPomodoroMode,
                  selectedColor: AppColors.accentAmber.withValues(alpha: 0.25),
                  onSelected: (sel) {
                    if (sel) {
                      _resetTimer();
                      setState(() => _isPomodoroMode = true);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Clock Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPomodoroMode
                    ? (_isPomodoroBreak ? AppColors.accentGreen : AppColors.accentAmber).withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _isPomodoroMode
                      ? (_isPomodoroBreak ? '☕ POMODORO BREAK TIME' : '⚡ POMODORO DEEP FOCUS')
                      : '⏱️ LIVE FOCUS STOPWATCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _isPomodoroMode
                        ? (_isPomodoroBreak ? AppColors.accentGreen : AppColors.accentAmber)
                        : AppColors.primaryGlow,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formatTimer(_isPomodoroMode ? _timerRemainingSeconds : _stopwatchElapsedSeconds),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTimerRunning ? AppColors.accentRose : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _toggleTimer,
                      icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isTimerRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log Session Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Save Completed Study Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _sessionSubjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _sessionTopicCtrl,
                        decoration: const InputDecoration(labelText: 'Topic / Chapter', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveStudySession,
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: const Text('Save Study Session & Time Log', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Session History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logged Study Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_studyLogs.length} Sessions', style: TextStyle(fontSize: 12, color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoadingLogs)
            const Center(child: CircularProgressIndicator())
          else if (_studyLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('No study sessions logged yet. Record your focus time above!')),
            )
          else
            ..._studyLogs.map((log) {
              final id = log['id'] as int? ?? 0;
              final topic = log['topic'] ?? 'Study';
              final subject = log['subject'] ?? 'General';
              final timeSpent = log['timeSpent'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.school_rounded, color: AppColors.primaryGlow, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Text('$subject • $timeSpent', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 18),
                      onPressed: () async {
                        await DBHelper.instance.deleteStudyLog(id);
                        await _loadStudyLogs();
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
