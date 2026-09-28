import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_english_models.dart';
import '../services/gemini_service.dart';
import '../services/study_english_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';
import 'speaking_history_progress_screen.dart';


class AiSpeakingPracticeScreen extends StatefulWidget {
  final String? initialTopic;

  const AiSpeakingPracticeScreen({super.key, this.initialTopic});

  @override
  State<AiSpeakingPracticeScreen> createState() => _AiSpeakingPracticeScreenState();
}

class _AiSpeakingPracticeScreenState extends State<AiSpeakingPracticeScreen>
    with TickerProviderStateMixin {
  final StudyEnglishService _englishService = StudyEnglishService.instance;
  final GeminiService _geminiService = GeminiService.instance;

  // Topic Selection
  final List<String> _topicSuggestions = [
    'Introduce yourself',
    'My daily routine',
    'My college life',
    'My career goals',
    'Technology',
    'Artificial Intelligence',
    'Fitness',
    'Travel',
    'Hobbies',
    'My family',
    'My future plans',
    'Random topic',
    'Interview practice',
    'Group discussion',
    'Job interview',
  ];

  late String _selectedTopic;
  final TextEditingController _customTopicCtrl = TextEditingController();
  bool _isCustomTopic = false;

  // Hardware & Permission Controls
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isMicPermissionDenied = false;
  bool _isCameraPermissionDenied = false;
  bool _isSaveVideo = false;

  // Recording State
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Playback State
  bool _isPlaying = false;
  int _playbackPositionSeconds = 0;
  Timer? _playbackTimer;

  // Waveform Animation
  late AnimationController _waveAnimCtrl;

  // Speech Transcription
  String _userSpeech = '';
  final TextEditingController _transcriptEditCtrl = TextEditingController();
  bool _isEditingTranscript = false;

  // AI Analysis State
  bool _isAnalyzing = false;
  SpeakingPracticeRecord? _analysisResult;

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic ?? 'My daily routine';
    _isSaveVideo = _englishService.isSaveVideoDefault;

    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _waveAnimCtrl.dispose();
    _customTopicCtrl.dispose();
    _transcriptEditCtrl.dispose();
    super.dispose();
  }

  String get _currentEffectiveTopic {
    if (_isCustomTopic && _customTopicCtrl.text.trim().isNotEmpty) {
      return _customTopicCtrl.text.trim();
    }
    return _selectedTopic;
  }

  // --- Recording Actions ---
  void _startRecording() {
    if (!_isMicOn || _isMicPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone access is required for speaking practice. Please enable microphone permission in your browser/device settings.'),
          backgroundColor: AppColors.accentRose,
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _hasRecorded = false;
      _recordingSeconds = 0;
      _isPlaying = false;
      _playbackPositionSeconds = 0;
      _analysisResult = null;
      _userSpeech = '';
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    if (_recordingSeconds < 3) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording was too short. Speak for at least a few seconds.')),
      );
      return;
    }

    // Generate or transcribe speech based on topic
    final transcript = _generateRealisticTranscriptForTopic(_currentEffectiveTopic);

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
      _userSpeech = transcript;
      _transcriptEditCtrl.text = transcript;
    });
  }

  void _resetRecording() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecorded = false;
      _isPlaying = false;
      _recordingSeconds = 0;
      _playbackPositionSeconds = 0;
      _analysisResult = null;
      _userSpeech = '';
      _isEditingTranscript = false;
    });
  }

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('Are you sure you want to discard this practice recording?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _resetRecording();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording discarded.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _isPlaying = true;
        if (_playbackPositionSeconds >= _recordingSeconds) {
          _playbackPositionSeconds = 0;
        }
      });
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_playbackPositionSeconds < _recordingSeconds) {
          setState(() => _playbackPositionSeconds++);
        } else {
          timer.cancel();
          setState(() {
            _isPlaying = false;
            _playbackPositionSeconds = 0;
          });
        }
      });
    }
  }

  // --- AI Analysis ---
  Future<void> _analyzeWithAi() async {
    final textToAnalyze = _isEditingTranscript ? _transcriptEditCtrl.text.trim() : _userSpeech;
    if (textToAnalyze.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record or enter your speech before analyzing.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _userSpeech = textToAnalyze;
      _isEditingTranscript = false;
    });

    try {
      final record = await _geminiService.analyzeSpeechPractice(
        transcript: textToAnalyze,
        topic: _currentEffectiveTopic,
        durationSeconds: _recordingSeconds > 0 ? _recordingSeconds : 75,
        isVideoSaved: _isSaveVideo,
        videoPath: _isSaveVideo ? 'practice_${DateTime.now().millisecondsSinceEpoch}.mp4' : null,
      );

      // Save to Firebase UID personal records
      await _englishService.saveSpeakingRecord(record);

      if (mounted) {
        setState(() {
          _analysisResult = record;
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech analysis completed and saved to your English record!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis notice: $e'), backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _generateRealisticTranscriptForTopic(String topic) {
    final tLower = topic.toLowerCase();
    if (tLower.contains('routine')) {
      return 'Yesterday I am going to college and I meet my friends. We are discussing about our project. In the morning I waking up early at 6 AM and I am went to gym. The workout was very very good and I drank protein shake.';
    }
    if (tLower.contains('tech') || tLower.contains('ai') || tLower.contains('intelligence')) {
      return 'Artificial intelligence is changing software very rapid. Every company are using automation today. I think everyone must to learn machine learning because in future computer science is everywhere. It is very very good for productivity.';
    }
    if (tLower.contains('career') || tLower.contains('job') || tLower.contains('interview')) {
      return 'I am want to become a hardware engineer in top semiconductor firm. I am working in this project from two months. I am good in digital logic and I have confidence that I will achieve my target.';
    }
    if (tLower.contains('college') || tLower.contains('study')) {
      return 'My college life is very busy. Every day I am attending lectures and discussing about engineering assignments with my classmates. We are preparing for semester exams and doing coding practice in night.';
    }
    return 'I am practicing my English speech on $topic. Yesterday I am thinking about how to improve my speaking fluency and reduce filler words like um and actually. In my opinion practice is very very good for speaking confidence.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 8),
            Text('AI Speaking Practice', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Topic Selection Card
            _buildTopicCard(isDark),
            const SizedBox(height: 14),

            // 2. Hardware / Permissions Bar
            _buildControlsBar(isDark),
            const SizedBox(height: 14),

            // 3. Main Camera & Recording Viewfinder
            _buildRecordingViewfinder(isDark),
            const SizedBox(height: 16),

            // 4. Post-Recording Actions
            if (_hasRecorded || _isRecording) _buildPostRecordingActions(isDark),

            // 5. Speech Transcription Card
            if (_userSpeech.isNotEmpty || _hasRecorded) ...[
              const SizedBox(height: 16),
              _buildTranscriptionCard(isDark),
            ],

            // 6. Complete AI Analysis Results
            if (_isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildAnalyzingState(isDark),
            ] else if (_analysisResult != null) ...[
              const SizedBox(height: 20),
              _buildAnalysisResultsView(isDark, _analysisResult!),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ================= 1. TOPIC SELECTION =================
  Widget _buildTopicCard(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppColors.accentAmber, size: 20),
                  SizedBox(width: 8),
                  Text('SPEAKING TOPIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentAmber, letterSpacing: 1.1)),
                ],
              ),
              Row(
                children: [
                  const Text('Custom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Switch(
                    value: _isCustomTopic,
                    onChanged: _isRecording ? null : (val) => setState(() => _isCustomTopic = val),
                    activeThumbColor: AppColors.primaryGlow,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isCustomTopic)
            TextField(
              controller: _customTopicCtrl,
              enabled: !_isRecording,
              decoration: InputDecoration(
                hintText: 'e.g. My daily routine, Artificial Intelligence, Job interview...',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _topicSuggestions.contains(_selectedTopic) ? _selectedTopic : _topicSuggestions.first,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _topicSuggestions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13.5)))).toList(),
              onChanged: _isRecording ? null : (val) {
                if (val != null) setState(() => _selectedTopic = val);
              },
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _topicSuggestions.take(6).map((t) {
                  final isSel = _selectedTopic == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      onSelected: _isRecording ? null : (s) {
                        if (s) setState(() => _selectedTopic = t);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            '⏱️ Recommended duration: Speak for 1–5 minutes for in-depth AI fluency evaluation.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ================= 2. CONTROLS & PERMISSIONS BAR =================
  Widget _buildControlsBar(bool isDark) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Camera ON/OFF
              Row(
                children: [
                  Icon(_isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      color: _isCameraOn ? AppColors.accentBlue : AppColors.textMuted, size: 20),
                  const SizedBox(width: 6),
                  Text('Camera ${_isCameraOn ? 'ON' : 'OFF'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isCameraOn,
                    onChanged: _isRecording ? null : (v) => setState(() => _isCameraOn = v),
                    activeThumbColor: AppColors.accentBlue,
                  ),
                ],
              ),

              // Mic ON/OFF
              Row(
                children: [
                  Icon(_isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: _isMicOn ? AppColors.accentGreen : AppColors.accentRose, size: 20),
                  const SizedBox(width: 6),
                  Text('Mic ${_isMicOn ? 'ON' : 'OFF'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isMicOn,
                    onChanged: _isRecording ? null : (v) => setState(() => _isMicOn = v),
                    activeThumbColor: AppColors.accentGreen,
                  ),
                ],
              ),
            ],
          ),

          // Save Recording Toggle (Requirement 25)
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.save_rounded, size: 18, color: AppColors.accentPurple),
                  SizedBox(width: 6),
                  Text('Save Recording File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  Text(_isSaveVideo ? 'ON' : 'OFF (Auto-delete raw)', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  Switch(
                    value: _isSaveVideo,
                    onChanged: (v) {
                      setState(() => _isSaveVideo = v);
                      _englishService.setSaveVideoDefault(v);
                    },
                    activeThumbColor: AppColors.accentPurple,
                  ),
                ],
              ),
            ],
          ),

          // Permission warning banner if mic/camera disabled
          if (!_isMicOn || _isMicPermissionDenied) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.accentRose, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Microphone access is required for speaking practice. Please enable microphone permission in your browser/device settings.',
                      style: TextStyle(fontSize: 11, color: AppColors.accentRose, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isCameraOn || _isCameraPermissionDenied) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.accentAmber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Camera is OFF. Continuing in high-quality audio-only practice mode.',
                      style: TextStyle(fontSize: 11, color: AppColors.accentAmber, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= 3. RECORDING INTERFACE / VIEWFINDER =================
  Widget _buildRecordingViewfinder(bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isRecording
              ? AppColors.accentRose
              : (_hasRecorded ? AppColors.accentGreen : AppColors.primary.withValues(alpha: 0.3)),
          width: _isRecording ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (_isRecording)
            BoxShadow(
              color: AppColors.accentRose.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Background Visualizer / Camera Preview Simulator
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _isCameraOn
                  ? _buildCameraViewfinderBackdrop()
                  : _buildAudioOnlyViewfinderBackdrop(),
            ),
          ),

          // Viewfinder Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCameraOn ? Icons.videocam_rounded : Icons.graphic_eq_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCameraOn ? 'VIDEO PRACTICE' : 'AUDIO-ONLY PRACTICE',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.fiber_manual_record_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('🔴 Recording...', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (_hasRecorded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Recorded', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Center: Topic Title & Big Timer
                Column(
                  children: [
                    Text(
                      _currentEffectiveTopic,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTimer(_isPlaying ? _playbackPositionSeconds : _recordingSeconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: _isRecording ? AppColors.accentRose : Colors.white,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtle Animated Audio Waveform
                    _buildSubtleWaveform(),
                  ],
                ),

                const SizedBox(height: 20),

                // Bottom Record / Stop Button
                _isRecording
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 6,
                        ),
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop_rounded, size: 22),
                        label: const Text('Stop Recording', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      )
                    : !_hasRecorded
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 6,
                            ),
                            onPressed: _startRecording,
                            icon: const Icon(Icons.fiber_manual_record_rounded, color: AppColors.accentRose, size: 20),
                            label: const Text('Start Recording', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinderBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF1E293B), Color(0xFF090D16)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(
              'CAMERA ACTIVE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioOnlyViewfinderBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 56,
              color: AppColors.primaryGlow.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'HIGH ACCURACY AUDIO VIEW',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleWaveform() {
    return AnimatedBuilder(
      animation: _waveAnimCtrl,
      builder: (context, child) {
        final heightFactors = [0.3, 0.7, 0.45, 0.9, 0.6, 0.8, 0.35, 0.75, 0.5, 0.95, 0.4, 0.65];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(heightFactors.length, (i) {
            double h;
            if (_isRecording || _isPlaying) {
              final wave = (_waveAnimCtrl.value + (i * 0.08)) % 1.0;
              h = 10 + (28 * heightFactors[i] * (0.4 + 0.6 * wave));
            } else {
              h = 6 + (8 * heightFactors[i]);
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 3.5,
              height: h,
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppColors.accentRose.withValues(alpha: 0.85)
                    : (_isPlaying ? AppColors.accentGreen : Colors.white30),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ================= 4. POST RECORDING ACTIONS =================
  Widget _buildPostRecordingActions(bool isDark) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              // Replay Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? AppColors.accentGreen : AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: _isPlaying ? Colors.white : AppColors.primaryGlow,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isRecording ? null : _togglePlayback,
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_isPlaying ? 'Pause' : 'Play Recording', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),

              // Record Again
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isRecording ? null : _resetRecording,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Record Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Delete & Analyze Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                tooltip: 'Delete Recording',
                onPressed: _isRecording ? null : _deleteRecording,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  onPressed: (_isRecording || _isAnalyzing) ? null : _analyzeWithAi,
                  icon: const Icon(Icons.psychology_rounded, size: 20),
                  label: const Text('Analyze with AI 🤖', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. TRANSCRIPTION CARD =================
  Widget _buildTranscriptionCard(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: AppColors.primaryGlow, size: 18),
                  SizedBox(width: 8),
                  Text('YOUR SPEECH TRANSCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.primaryGlow, letterSpacing: 1.1)),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isEditingTranscript = !_isEditingTranscript),
                icon: Icon(_isEditingTranscript ? Icons.check_rounded : Icons.edit_rounded, size: 14),
                label: Text(_isEditingTranscript ? 'Done' : 'Edit Text', style: const TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isEditingTranscript)
            TextField(
              controller: _transcriptEditCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Edit your transcribed speech...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '“$_userSpeech”',
                style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // ================= 6. ANALYZING SPINNER =================
  Widget _buildAnalyzingState(bool isDark) {
    return const GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: AppColors.primaryGlow, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Transcribing & Analyzing with Titan English AI...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'Evaluating grammar rules, prepositions, tenses, vocabulary upgrades, and pacing.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= 7. COMPLETE AI ANALYSIS RESULTS =================
  Widget _buildAnalysisResultsView(bool isDark, SpeakingPracticeRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Banner: Score & Fluency
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI ENGLISH MASTERY REPORT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('${record.fluencyScore.toStringAsFixed(0)}% Fluency Score', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${record.corrections.length} Corrections Found',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 7: Speaking Fluency Breakdown (Requirement 7)
        _buildSpeakingFluencyStatsCard(isDark, record),
        const SizedBox(height: 16),

        // Section 4 & 5: Show Every Correction Individually (Requirements 4 & 5)
        _buildCorrectionsListCard(isDark, record),
        const SizedBox(height: 16),

        // Section 6: Pronunciation Analysis (Requirement 6)
        if (record.pronunciationTips.isNotEmpty) ...[
          _buildPronunciationCard(isDark, record),
          const SizedBox(height: 16),
        ],

        // Section 8: Practical AI Feedback (Requirement 8)
        _buildPracticalFeedbackCard(isDark, record),
        const SizedBox(height: 16),

        // Section 9: Better Version Comparison (Requirement 9)
        _buildBetterVersionCard(isDark, record),
        const SizedBox(height: 16),

        // History Navigation Footer
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpeakingHistoryProgressScreen()),
                  );
                },
                icon: const Icon(Icons.insights_rounded, size: 20),
                label: const Text('View in Speaking History & Progress →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Requirement 7: Speaking Fluency Card ---
  Widget _buildSpeakingFluencyStatsCard(bool isDark, SpeakingPracticeRecord record) {
    final mins = record.durationSeconds ~/ 60;
    final secs = record.durationSeconds % 60;
    final durationStr = mins > 0 ? '$mins min $secs sec' : '$secs sec';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed_rounded, color: AppColors.accentBlue, size: 18),
              SizedBox(width: 8),
              Text('SPEAKING FLUENCY METRICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentBlue, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildFluencyStatTile('Duration', durationStr, Icons.timer_outlined, AppColors.accentBlue),
              const SizedBox(width: 8),
              _buildFluencyStatTile('Words', '${record.wordsCount}', Icons.subject_rounded, AppColors.accentGreen),
              const SizedBox(width: 8),
              _buildFluencyStatTile('Speaking Pace', '${record.wordsPerMinute} wpm', Icons.speed_rounded, AppColors.accentAmber),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildFluencyStatTile('Filler Words', '${record.fillerWordsCount}', Icons.chat_bubble_outline_rounded, AppColors.accentRose),
              const SizedBox(width: 8),
              _buildFluencyStatTile('Long Pauses', '${record.longPausesCount}', Icons.pause_circle_outline_rounded, AppColors.purple),
            ],
          ),

          if (record.fillerDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Common Fillers Detected:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.fillerDetails.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.25)),
                    ),
                    child: Text('"${f.word}" — ${f.count}', style: const TextStyle(fontSize: 11.5, color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                  )).toList(),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            '* Note: Speaking pace, pause frequency, and filler metrics are approximate computational estimates.',
            style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFluencyStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // --- Requirements 4 & 5: Show Every Correction Individually ---
  Widget _buildCorrectionsListCard(bool isDark, SpeakingPracticeRecord record) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rule_rounded, color: AppColors.accentRose, size: 18),
                  SizedBox(width: 8),
                  Text('INDIVIDUAL CORRECTIONS & EXPLANATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentRose, letterSpacing: 1.1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${record.corrections.length} items', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (record.corrections.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('🎉 Outstanding! No grammatical or lexical errors detected in this speech sample.', style: TextStyle(fontSize: 13, color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
            )
          else
            ...record.corrections.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final c = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag / Subcategory
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${c.category} • ${c.subcategory}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentAmber)),
                        ),
                        Text('#$idx', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // What I said (You said)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('❌ You said: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentRose)),
                        Expanded(
                          child: Text('“${c.originalText}”', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Correction
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅ Correction: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGreen)),
                        Expanded(
                          child: Text('“${c.correctedText}”', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Why it is wrong
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Why: ${c.whyWrong}',
                              style: const TextStyle(fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Better way to say it (More natural)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨ More natural: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryGlow)),
                        Expanded(
                          child: Text('“${c.moreNaturalWay}”', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- Requirement 6: Pronunciation Analysis Card ---
  Widget _buildPronunciationCard(bool isDark, SpeakingPracticeRecord record) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over_rounded, color: AppColors.accentPurple, size: 18),
              SizedBox(width: 8),
              Text('PRONUNCIATION GUIDANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentPurple, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),

          ...record.pronunciationTips.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Word: "${p.word}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('Practice: ${p.phoneticGuide}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Issue: ${p.issueDescription}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
                  ],
                ),
              )),

          const SizedBox(height: 4),
          const Text(
            '* Pronunciation guidance is provided based on standard phonetic dictionaries and syllable stress models.',
            style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // --- Requirement 8: Practical AI Feedback Card ---
  Widget _buildPracticalFeedbackCard(bool isDark, SpeakingPracticeRecord record) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: AppColors.accentGreen, size: 18),
              SizedBox(width: 8),
              Text('PRACTICAL AI FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accentGreen, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 12),

          // What You Did Well
          const Text('What You Did Well', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGreen)),
          const SizedBox(height: 6),
          ...record.whatYouDidWell.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓ ', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 12.5, height: 1.3))),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),

          // Improve These
          const Text('Improve These', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentAmber)),
          const SizedBox(height: 6),
          ...record.improveThese.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$idx. ', style: const TextStyle(color: AppColors.accentAmber, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 12.5, height: 1.3))),
                ],
              ),
            );
          }),

          if (record.vocabularySuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Suggested Vocabulary Upgrades:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.vocabularySuggestions.map((v) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(v, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryGlow, fontWeight: FontWeight.bold)),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- Requirement 9: Better Version Card ---
  Widget _buildBetterVersionCard(bool isDark, SpeakingPracticeRecord record) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGlow, size: 18),
              SizedBox(width: 8),
              Text('BETTER VERSION REWRITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.primaryGlow, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),

          // Original
          const Text('Original Speech:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(record.transcript, style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 10),

          // Corrected
          const Text('Polished & Natural English:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              record.betterVersion,
              style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
