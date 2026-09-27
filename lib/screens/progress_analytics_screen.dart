import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../services/workout_service.dart';
import '../services/finance_service.dart';
import '../services/food_service.dart';
import '../services/theme_service.dart';
import '../widgets/titan_ai_sheet.dart';
import '../widgets/body_photo_modal.dart';
import '../widgets/weekly_report_modal.dart';

class ProgressAnalyticsScreen extends StatelessWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileService = ProfileService.instance;
    final workoutService = WorkoutService.instance;
    final financeService = FinanceService.instance;
    final foodService = FoodService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([profileService, workoutService, financeService, foodService]),
      builder: (context, _) {
        final profile = profileService.profile;
        final curr = profile.currencySymbol;

        // Composite Discipline Score (0 to 100)
        final workoutScore = (workoutService.weeklyCompletionRate * 40).clamp(0, 40);
        final financeScore = ((1.0 - (financeService.budgetUsageRatio > 1.0 ? 1.0 : financeService.budgetUsageRatio)) * 30).clamp(0, 30);
        final nutritionScore = (foodService.calorieProgress <= 1.1 && foodService.calorieProgress >= 0.7 ? 30 : 20).toDouble();
        final compositeScore = (workoutScore + financeScore + nutritionScore).round();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Progress & Telemetry'),
            actions: [
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                tooltip: 'Weekly BMI Report',
                onPressed: () => WeeklyReportModal.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Body Photos',
                onPressed: () => BodyPhotoModal.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                tooltip: 'Performance AI Audit',
                onPressed: () => TitanAiSheet.show(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Weekly Report Generator Banner
              _buildWeeklyReportBanner(context, isDark),
              const SizedBox(height: 18),

              // Composite Discipline Score Card
              _buildCompositeScoreCard(isDark, compositeScore),
              const SizedBox(height: 18),

              // Body Transformation Photos Gallery Preview
              _buildBodyPhotosPreviewCard(context, profile, isDark),
              const SizedBox(height: 18),

              // Weight Progression History & Log
              _buildWeightTimelineCard(context, isDark, profile, profileService),
              const SizedBox(height: 18),

              // Muscle Distribution Matrix
              _buildMuscleDistributionCard(isDark, workoutService),
              const SizedBox(height: 18),

              // Financial Savings Efficiency
              _buildSavingsEfficiencyCard(isDark, curr, financeService),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Weekly Report Generator Quick Banner
  Widget _buildWeeklyReportBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Health & BMI Report',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review 7-day step compliance, active hours & AI discipline grade.',
                  style: TextStyle(color: Colors.black87, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => WeeklyReportModal.show(context),
            child: const Text('Generate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 1. Composite Discipline Score
  Widget _buildCompositeScoreCard(bool isDark, int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ThemeService.primaryCyan.withValues(alpha: isDark ? 0.4 : 0.6)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  color: ThemeService.primaryCyan,
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPOSITE DISCIPLINE INDEX',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: ThemeService.primaryCyan),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? 'Peak Performance 🔥'
                      : score >= 60
                          ? 'Consistent Progress ⚡'
                          : 'Needs Optimization 🛠️',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Synthesized from workout adherence, nutrition targets, and budget compliance.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Body Transformation Photos Preview Card
  Widget _buildBodyPhotosPreviewCard(BuildContext context, UserProfile profile, bool isDark) {
    final photos = profile.bodyPhotos;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BODY TRANSFORMATION TIMELINE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
                  ),
                ],
              ),
              InkWell(
                onTap: () => BodyPhotoModal.show(context),
                child: const Text(
                  'View All →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (photos.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No body check-in photos yet. Take a photo to track physical transformation.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => BodyPhotoModal.show(context),
                    child: const Text('Add Photo'),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final p = photos[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _renderBase64Thumb(p.imageBase64),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.black.withValues(alpha: 0.75),
                              child: Text(
                                '${p.weightKg}kg • BMI ${p.bmi.toStringAsFixed(1)}',
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Weight Progression Timeline Card
  Widget _buildWeightTimelineCard(BuildContext context, bool isDark, UserProfile profile, ProfileService profileService) {
    final history = profile.weightHistory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BODYWEIGHT & BMI PROGRESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Log Weight', style: TextStyle(fontSize: 12)),
                onPressed: () => _showWeightLogDialog(context, profileService),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current vs Target
          Row(
            children: [
              _subStat('Current Weight', '${profile.currentWeightKg} kg', isDark),
              const SizedBox(width: 8),
              _subStat('Target Weight', '${profile.targetWeightKg} kg', isDark),
              const SizedBox(width: 8),
              _subStat(
                'Current BMI',
                '${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory.split(" ").first})',
                isDark,
                color: ThemeService.primaryCyan,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Weight History Points
          const Text('Recent Logs:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...history.reversed.take(4).map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(entry.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${entry.weightKg} kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Muscle Group Distribution Card
  Widget _buildMuscleDistributionCard(bool isDark, WorkoutService workout) {
    final dist = workout.muscleDistribution;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY MUSCLE FOCUS DISTRIBUTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          if (dist.isEmpty)
            const Text('No muscle workouts scheduled.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...dist.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: ThemeService.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${e.value} sessions', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 4. Financial Savings Efficiency
  Widget _buildSavingsEfficiencyCard(bool isDark, String curr, FinanceService finance) {
    final savingsRatio = finance.totalIncome > 0 ? (finance.netSavings / finance.totalIncome) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FINANCIAL SAVINGS EFFICIENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          Row(
            children: [
              _subStat('Savings Rate', '${savingsRatio.toStringAsFixed(0)}%', isDark, color: ThemeService.primaryEmerald),
              const SizedBox(width: 10),
              _subStat('Budget Used', '${(finance.budgetUsageRatio * 100).toStringAsFixed(0)}%', isDark),
              const SizedBox(width: 10),
              _subStat('Net Retained', '$curr${finance.netSavings.toStringAsFixed(0)}', isDark),
            ],
          ),
        ],
      ),
    );
  }

  void _showWeightLogDialog(BuildContext context, ProfileService profileService) {
    final ctrl = TextEditingController(text: profileService.profile.currentWeightKg.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Today Weight'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ThemeService.primaryCyan, foregroundColor: Colors.black),
            onPressed: () {
              final w = double.tryParse(ctrl.text);
              if (w != null && w > 0) {
                profileService.logNewWeight(w);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }

  Widget _renderBase64Thumb(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.broken_image, size: 20));
    }
  }

  Widget _subStat(String label, String val, bool isDark, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 3),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
