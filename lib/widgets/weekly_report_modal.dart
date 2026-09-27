import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/workout_models.dart';
import '../services/profile_service.dart';
import '../services/workout_service.dart';
import '../services/theme_service.dart';
import 'body_photo_modal.dart';

class WeeklyReportModal extends StatelessWidget {
  const WeeklyReportModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WeeklyReportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileService = ProfileService.instance;
    final workoutService = WorkoutService.instance;

    final completedWorkouts = workoutService.plans.values
        .where((p) => p.status == WorkoutStatus.completed)
        .length;
    final totalPlanned = workoutService.plans.values
        .where((p) => !p.isRestDay)
        .length;

    final report = profileService.generateWeeklyHealthReport(
      workoutsCompleted: completedWorkouts,
      totalWorkoutsPlanned: totalPlanned > 0 ? totalPlanned : 7,
    );

    final startStr = DateFormat('MMM dd').format(report.startDate);
    final endStr = DateFormat('MMM dd, yyyy').format(report.endDate);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF6366F1)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assessment_rounded, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Health & BMI Report',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$startStr – $endStr • 7-Day Performance',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // AI Coach Performance Grade Banner
                _buildGradeBanner(report, isDark),
                const SizedBox(height: 16),

                // BMI & Body Composition Section
                _buildBmiSection(report, isDark),
                const SizedBox(height: 16),

                // Step & Movement Telemetry
                _buildStepAndMovementSection(report, isDark),
                const SizedBox(height: 16),

                // Workout Split & Adherence
                _buildWorkoutAdherenceSection(report, isDark),
                const SizedBox(height: 16),

                // Weekly Body Photo Check-in
                _buildBodyPhotoCheckinSection(context, report, isDark),
                const SizedBox(height: 16),

                // Key Wins & Actionable Recommendations
                _buildWinsAndRecommendations(report, isDark),
                const SizedBox(height: 24),

                // Export / Copy to Clipboard
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copy Complete Report Summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeService.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _copyReportToClipboard(context, report),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBanner(WeeklyHealthReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE0F2FE), const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ThemeService.primaryCyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ThemeService.primaryCyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.military_tech_rounded, color: ThemeService.primaryCyan, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.aiCoachGrade,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ThemeService.primaryCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.aiEvaluation,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiSection(WeeklyHealthReport report, bool isDark) {
    final bmi = report.currentBmi;
    Color bmiColor;
    if (bmi < 18.5) {
      bmiColor = Colors.orangeAccent;
    } else if (bmi < 25.0) {
      bmiColor = ThemeService.primaryEmerald;
    } else if (bmi < 30.0) {
      bmiColor = Colors.amber;
    } else {
      bmiColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_weight_rounded, color: ThemeService.primaryCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'BODY MASS INDEX (BMI) & WEIGHT METRICS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: bmiColor),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: bmiColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          report.bmiCategory,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: bmiColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.endWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      report.weightChange >= 0
                          ? '+${report.weightChange.toStringAsFixed(1)} kg this week'
                          : '${report.weightChange.toStringAsFixed(1)} kg this week',
                      style: TextStyle(
                        fontSize: 12,
                        color: report.weightChange <= 0 ? ThemeService.primaryEmerald : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual BMI Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(flex: 185, child: Container(height: 8, color: Colors.blue.withValues(alpha: 0.6))),
                Expanded(flex: 65, child: Container(height: 8, color: Colors.green.withValues(alpha: 0.8))),
                Expanded(flex: 50, child: Container(height: 8, color: Colors.amber.withValues(alpha: 0.8))),
                Expanded(flex: 100, child: Container(height: 8, color: Colors.redAccent.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('<18.5 Under', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('18.5–24.9 Optimal', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('25–29.9 Over', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('30+ Obese', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepAndMovementSection(WeeklyHealthReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk_rounded, color: ThemeService.primaryEmerald, size: 20),
              SizedBox(width: 8),
              Text(
                'STEP VOLUME & ACTIVE DURATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniMetric(
                  label: 'Daily Avg Steps',
                  value: '${report.dailyAverageSteps}',
                  sub: '${(report.stepComplianceRate * 100).toStringAsFixed(0)}% Goal Hit',
                  color: ThemeService.primaryEmerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMetric(
                  label: 'Total Active Time',
                  value: '${(report.totalActiveMinutes / 60).toStringAsFixed(1)} hrs',
                  sub: '${report.totalActiveMinutes} mins total',
                  color: ThemeService.accentIndigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutAdherenceSection(WeeklyHealthReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: ThemeService.primaryCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'WORKOUT ROUTINE ADHERENCE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${report.workoutsCompleted} of ${report.totalWorkoutsPlanned} Sessions Completed',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${(report.workoutAdherenceRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w900, color: ThemeService.primaryCyan, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.workoutAdherenceRate,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
              color: ThemeService.primaryCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPhotoCheckinSection(BuildContext context, WeeklyHealthReport report, bool isDark) {
    final photo = report.latestPhoto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'LATEST WEEKLY BODY PHOTO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  BodyPhotoModal.show(context);
                },
                child: const Text(
                  'Manage Photos →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (photo != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: _renderBase64(photo.imageBase64),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logged on ${DateFormat('MMM dd, yyyy').format(photo.date)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weight: ${photo.weightKg} kg  •  BMI: ${photo.bmi.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (photo.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          photo.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'No photo logged this week. Capture a Sunday check-in to track physique.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      BodyPhotoModal.show(context);
                    },
                    child: const Text('Take Photo', style: TextStyle(fontSize: 12, color: ThemeService.primaryCyan)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWinsAndRecommendations(WeeklyHealthReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY WINS & FOCUS AREAS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          for (final win in report.keyWins)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: ThemeService.primaryEmerald, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(win, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          for (final rec in report.recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right_alt_rounded, color: ThemeService.primaryCyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _renderBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.broken_image));
    }
  }

  void _copyReportToClipboard(BuildContext context, WeeklyHealthReport report) {
    final startStr = DateFormat('MMM dd').format(report.startDate);
    final endStr = DateFormat('MMM dd, yyyy').format(report.endDate);

    final summary = StringBuffer();
    summary.writeln('📊 GET SET GO — WEEKLY HEALTH & BMI REPORT ($startStr - $endStr)');
    summary.writeln('--------------------------------------------------');
    summary.writeln('🏆 Discipline Grade: ${report.aiCoachGrade}');
    summary.writeln('⚖️ Weight: ${report.endWeight.toStringAsFixed(1)} kg (${report.weightChange >= 0 ? "+" : ""}${report.weightChange.toStringAsFixed(1)} kg)');
    summary.writeln('📐 BMI: ${report.currentBmi.toStringAsFixed(1)} (${report.bmiCategory})');
    summary.writeln('👟 Weekly Steps: ${report.totalSteps} (Avg ${report.dailyAverageSteps} steps/day - ${(report.stepComplianceRate * 100).toStringAsFixed(0)}% goal)');
    summary.writeln('⏱️ Active Duration: ${(report.totalActiveMinutes / 60).toStringAsFixed(1)} hours');
    summary.writeln('🏋️ Workouts Completed: ${report.workoutsCompleted}/${report.totalWorkoutsPlanned} (${(report.workoutAdherenceRate * 100).toStringAsFixed(0)}%)');
    summary.writeln('🤖 AI Coach Notes: ${report.aiEvaluation}');

    Clipboard.setData(ClipboardData(text: summary.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly Health Report copied to clipboard!')),
    );
  }
}
