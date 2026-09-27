import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../services/theme_service.dart';

class StudyAndEnglishScreen extends StatefulWidget {
  const StudyAndEnglishScreen({super.key});

  @override
  State<StudyAndEnglishScreen> createState() => _StudyAndEnglishScreenState();
}

class _StudyAndEnglishScreenState extends State<StudyAndEnglishScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Study Tracker State
  int _studyElapsedSeconds = 0;
  bool _isStudyTimerRunning = false;
  Timer? _studyTimer;
  final TextEditingController _subjectCtrl = TextEditingController(text: 'General');
  final TextEditingController _studyTopicCtrl = TextEditingController();
  List<Map<String, dynamic>> _studyLogs = [];
  bool _isLoadingLogs = true;

  // STT & English Mastery State
  bool _isRecordingSTT = false;
  String _sttTranscribedText = '';
  final String _practiceSentence = 'Consistency and daily deliberate practice build undeniable mastery.';
  double _pronunciationScore = 0.0;

  // Vocabulary State
  final List<Map<String, String>> _vocabularyList = [
    {
      'word': 'Relentless',
      'meaning': 'Continuing without becoming weaker or less severe.',
      'example': 'His relentless work ethic inspired the entire team.'
    },
    {
      'word': 'Discipline',
      'meaning': 'The practice of training people to obey rules or a code of behavior.',
      'example': 'Discipline is choosing between what you want now and what you want most.'
    },
    {
      'word': 'Stoicism',
      'meaning': 'The endurance of pain or hardship without the display of feelings and without complaint.',
      'example': 'She maintained calm stoicism during the difficult period.'
    },
  ];
  final TextEditingController _wordCtrl = TextEditingController();
  final TextEditingController _meaningCtrl = TextEditingController();
  final TextEditingController _exampleCtrl = TextEditingController();

  // Reading Timer State
  int _selectedReadingMinutes = 15;
  int _readingRemainingSeconds = 15 * 60;
  bool _isReadingTimerActive = false;
  Timer? _readingTimer;

  // Daily Video status
  bool _isVideoUploaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudyLogs();
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    _readingTimer?.cancel();
    _tabController.dispose();
    _subjectCtrl.dispose();
    _studyTopicCtrl.dispose();
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _exampleCtrl.dispose();
    super.dispose();
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

  // --- Study Timer Methods ---
  void _toggleStudyTimer() {
    if (_isStudyTimerRunning) {
      _studyTimer?.cancel();
      setState(() => _isStudyTimerRunning = false);
    } else {
      setState(() => _isStudyTimerRunning = true);
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _studyElapsedSeconds++);
        }
      });
    }
  }

  void _resetStudyTimer() {
    _studyTimer?.cancel();
    setState(() {
      _studyElapsedSeconds = 0;
      _isStudyTimerRunning = false;
    });
  }

  String _formatDuration(int totalSecs) {
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _saveStudySession() async {
    final topic = _studyTopicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a study topic / subject name.')),
      );
      return;
    }
    if (_studyElapsedSeconds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study timer duration must be at least 10 seconds.')),
      );
      return;
    }

    final mins = (_studyElapsedSeconds / 60).ceil();
    final timeSpent = mins >= 60 ? '${(mins / 60).toStringAsFixed(1)} hrs' : '$mins mins';

    await DBHelper.instance.insertStudyLog({
      'subject': _subjectCtrl.text.trim().isEmpty ? 'General' : _subjectCtrl.text.trim(),
      'topic': topic,
      'desc': 'Logged via Live Focus Stopwatch',
      'timeSpent': timeSpent,
      'date': DateTime.now().toIso8601String(),
    });

    _studyTopicCtrl.clear();
    _resetStudyTimer();
    await _loadStudyLogs();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Study session "$topic" ($timeSpent) saved!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  Future<void> _deleteStudyLog(int id, String topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Log?'),
        content: Text('Are you sure you want to delete the study log for "$topic"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteStudyLog(id);
      await _loadStudyLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🗑️ Study session "$topic" removed.')),
        );
      }
    }
  }

  // --- STT Practice Simulation ---
  void _toggleSTTRecording() {
    if (_isRecordingSTT) {
      setState(() {
        _isRecordingSTT = false;
        _sttTranscribedText = 'Consistency and daily deliberate practice build undeniable mastery.';
        _pronunciationScore = 96.5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech analysis complete: 96.5% Fluency & Clarity Score! ⭐'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } else {
      setState(() {
        _isRecordingSTT = true;
        _sttTranscribedText = 'Listening to your speech in real-time...';
        _pronunciationScore = 0.0;
      });
    }
  }

  // --- Reading Timer Methods ---
  void _startReadingTimer() {
    _readingTimer?.cancel();
    setState(() => _isReadingTimerActive = true);
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_readingRemainingSeconds > 0) {
        if (mounted) setState(() => _readingRemainingSeconds--);
      } else {
        t.cancel();
        if (mounted) {
          setState(() => _isReadingTimerActive = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Reading session completed! Great job!'), backgroundColor: AppColors.accentGreen),
          );
        }
      }
    });
  }

  void _pauseReadingTimer() {
    _readingTimer?.cancel();
    setState(() => _isReadingTimerActive = false);
  }

  void _resetReadingTimer(int mins) {
    _readingTimer?.cancel();
    setState(() {
      _selectedReadingMinutes = mins;
      _readingRemainingSeconds = mins * 60;
      _isReadingTimerActive = false;
    });
  }

  void _addVocabularyWord() {
    final w = _wordCtrl.text.trim();
    final m = _meaningCtrl.text.trim();
    final ex = _exampleCtrl.text.trim();
    if (w.isEmpty || m.isEmpty) return;

    setState(() {
      _vocabularyList.insert(0, {'word': w, 'meaning': m, 'example': ex});
      _wordCtrl.clear();
      _meaningCtrl.clear();
      _exampleCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$w" to Vocabulary Bank!'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Tracker & STT English', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGlow,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.timer_outlined, size: 18), text: 'Study Tracker'),
            Tab(icon: Icon(Icons.record_voice_over_rounded, size: 18), text: 'STT & English'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyTrackerTab(),
          _buildSttEnglishTab(),
        ],
      ),
    );
  }

  // --- TAB 1: Focus Study Tracker ---
  Widget _buildStudyTrackerTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stopwatch Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: AppColors.primaryGlow, size: 18),
                    SizedBox(width: 8),
                    Text('LIVE FOCUS STOPWATCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatDuration(_studyElapsedSeconds),
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStudyTimerRunning ? AppColors.accentRose : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _toggleStudyTimer,
                      icon: Icon(_isStudyTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isStudyTimerRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _resetStudyTimer,
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
                const Text('Log Study Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject (e.g. CS, Math)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _studyTopicCtrl,
                        decoration: const InputDecoration(labelText: 'Topic Studied', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school_outlined, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No study sessions logged yet.', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Start the stopwatch to record your study hours!', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _studyLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = _studyLogs[index];
                final id = log['id'] as int? ?? index;
                final topic = log['topic'] ?? 'Study';
                final subject = log['subject'] ?? 'General';
                final timeSpent = log['timeSpent'] ?? '';

                return Container(
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
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                        tooltip: 'Delete Log',
                        onPressed: () => _deleteStudyLog(id, topic),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- TAB 2: STT & English Mastery ---
  Widget _buildSttEnglishTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speech-to-Text & Pronunciation Practice
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('STT & SPEECH PRONUNCIATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Read & Speak this prompt out loud:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('“$_practiceSentence”', style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
                if (_sttTranscribedText.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _pronunciationScore > 90 ? AppColors.accentGreen : AppColors.accentAmber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transcription: "$_sttTranscribedText"', style: const TextStyle(fontSize: 12.5)),
                        if (_pronunciationScore > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 16),
                              const SizedBox(width: 4),
                              Text('Pronunciation Score: $_pronunciationScore%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentGreen)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecordingSTT ? AppColors.accentRose : AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _toggleSTTRecording,
                    icon: Icon(_isRecordingSTT ? Icons.stop_rounded : Icons.mic_rounded),
                    label: Text(_isRecordingSTT ? 'Stop & Analyze Speech' : 'Hold / Tap to Speak (STT)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily English Video Log Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.video_library_rounded, size: 36, color: _isVideoUploaded ? AppColors.accentGreen : AppColors.accentAmber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isVideoUploaded ? 'Today\'s Speaking Video Attached ✅' : 'Daily Speaking Video Journal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Text('Upload 1-2 min video of yourself speaking English', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVideoUploaded ? AppColors.accentGreen : AppColors.accentAmber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _isVideoUploaded = !_isVideoUploaded);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isVideoUploaded ? 'Daily Speaking Video recorded & attached!' : 'Video removed.'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  },
                  child: Text(_isVideoUploaded ? 'Attached' : 'Attach', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vocabulary Bank
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
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: AppColors.primaryGlow, size: 18),
                    SizedBox(width: 6),
                    Text('New Words & Meaning Bank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _wordCtrl, decoration: const InputDecoration(labelText: 'Word', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: _meaningCtrl, decoration: const InputDecoration(labelText: 'Meaning', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _exampleCtrl, decoration: const InputDecoration(labelText: 'Example Sentence (Optional)', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _addVocabularyWord,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._vocabularyList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(v['word'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGlow, fontSize: 13.5)),
                      subtitle: Text('${v['meaning']}${v['example'] != null && v['example']!.isNotEmpty ? '\nEx: "${v['example']}"' : ''}', style: const TextStyle(fontSize: 11.5)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 18),
                        onPressed: () => setState(() => _vocabularyList.removeAt(index)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Distraction-Free Reading Timer
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_rounded, color: AppColors.accentGreen, size: 18),
                    SizedBox(width: 6),
                    Text('DISTRACTION-FREE READING TIMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [10, 15, 20, 30].map((mins) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text('$mins min'),
                          selected: _selectedReadingMinutes == mins,
                          selectedColor: AppColors.accentGreen.withValues(alpha: 0.25),
                          onSelected: (sel) {
                            if (sel) _resetReadingTimer(mins);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_formatDuration(_readingRemainingSeconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.accentGreen, fontFamily: 'monospace')),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                      onPressed: _isReadingTimerActive ? _pauseReadingTimer : _startReadingTimer,
                      icon: Icon(_isReadingTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isReadingTimerActive ? 'Pause' : 'Start Reading', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(onPressed: () => _resetReadingTimer(_selectedReadingMinutes), icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Reset')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
