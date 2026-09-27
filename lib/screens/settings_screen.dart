import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../services/gemini_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_refresh);
    ProfileService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_refresh);
    ProfileService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // Edit Profile Modal
  void _openProfileEditor() {
    final nameCtrl = TextEditingController(text: ProfileService.instance.userName);
    final ageCtrl = TextEditingController(text: ProfileService.instance.age.toString());
    final heightCtrl = TextEditingController(text: ProfileService.instance.heightCm.toStringAsFixed(0));
    final weightCtrl = TextEditingController(text: ProfileService.instance.weightKg.toStringAsFixed(1));
    final targetWeightCtrl = TextEditingController(text: ProfileService.instance.targetWeightKg.toStringAsFixed(1));
    String goal = ProfileService.instance.fitnessGoal;
    String activity = ProfileService.instance.activityLevel;
    String equip = ProfileService.instance.availableEquipment;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Edit Profile & Body Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Current Weight (kg)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: targetWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Target Weight (kg)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: goal,
                  decoration: const InputDecoration(labelText: 'Fitness Goal', border: OutlineInputBorder()),
                  items: ['Muscle Gain & Hypertrophy', 'Fat Loss & Shred', 'Athletic Endurance', 'Maintenance & Mobility'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12.5)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => goal = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                  items: ['Sedentary', 'Lightly Active (1-3 days)', 'Moderately Active (3-5 days)', 'Very Active (6-7 days)'].map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12.5)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => activity = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: equip),
                  decoration: const InputDecoration(labelText: 'Available Equipment', border: OutlineInputBorder()),
                  onChanged: (v) => equip = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                await ProfileService.instance.updateProfile(
                  name: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text),
                  heightCm: double.tryParse(heightCtrl.text),
                  weightKg: double.tryParse(weightCtrl.text),
                  targetWeightKg: double.tryParse(targetWeightCtrl.text),
                  fitnessGoal: goal,
                  activityLevel: activity,
                  availableEquipment: equip,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Strict Goal Protocol Modal
  void _openStrictGoalEditor() {
    final p = ProfileService.instance;
    final titleCtrl = TextEditingController(text: p.strictGoalTitle);
    final stepCtrl = TextEditingController(text: p.dailyStepTarget.toString());
    final activeCtrl = TextEditingController(text: p.dailyActiveTimeMinutesTarget.toString());
    final weightTargetCtrl = TextEditingController(text: p.targetWeightKg.toStringAsFixed(1));
    bool strictMode = p.isStrictMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Row(
            children: [
              Icon(Icons.track_changes_rounded, color: AppColors.primaryGlow),
              SizedBox(width: 8),
              Text('Strict Goal Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Goal Headline', border: OutlineInputBorder(), prefixIcon: Icon(Icons.fitness_center)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stepCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Step Target', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_walk_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: activeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Active Minutes Target', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightTargetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target Weight (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight_outlined)),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict Discipline Mode', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enforce daily compliance badges & banners', style: TextStyle(fontSize: 11)),
                  value: strictMode,
                  activeThumbColor: AppColors.primaryGlow,
                  onChanged: (v) => setDlgState(() => strictMode = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final newTitle = titleCtrl.text.trim();
                final newSteps = int.tryParse(stepCtrl.text.trim()) ?? p.dailyStepTarget;
                final newActive = int.tryParse(activeCtrl.text.trim()) ?? p.dailyActiveTimeMinutesTarget;
                final newTargetW = double.tryParse(weightTargetCtrl.text.trim()) ?? p.targetWeightKg;

                await p.updateStrictGoal(
                  strictGoalTitle: newTitle.isNotEmpty ? newTitle : p.strictGoalTitle,
                  isStrictMode: strictMode,
                  dailyStepTarget: newSteps,
                  dailyActiveTimeMinutesTarget: newActive,
                  targetWeightKg: newTargetW,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Save Protocol', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Finance Preferences Modal
  void _openFinanceSettings() {
    final currencyCtrl = TextEditingController(text: ProfileService.instance.currencySymbol);
    final budgetCtrl = TextEditingController(text: ProfileService.instance.monthlyBudgetCap.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Finance & Budget Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currencyCtrl,
              decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. ₹, \$, €, £)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Budget Cap', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () async {
              await ProfileService.instance.updateFinance(
                currencySymbol: currencyCtrl.text.trim().isEmpty ? '₹' : currencyCtrl.text.trim(),
                monthlyBudgetCap: double.tryParse(budgetCtrl.text) ?? 50000.0,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Save Finance', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit Nutrition Targets Modal
  void _openNutritionSettings() {
    final target = ProfileService.instance.nutritionTarget;
    final calCtrl = TextEditingController(text: target.calorieTarget.toStringAsFixed(0));
    final proCtrl = TextEditingController(text: target.proteinTargetGrams.toStringAsFixed(0));
    final carbCtrl = TextEditingController(text: target.carbTargetGrams.toStringAsFixed(0));
    final fatCtrl = TextEditingController(text: target.fatTargetGrams.toStringAsFixed(0));
    final fiberCtrl = TextEditingController(text: target.fiberTargetGrams.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Daily Nutrition Targets', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Calories (kcal)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fats (g)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fiberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiber (g)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            onPressed: () async {
              final newTarget = DailyNutritionTarget(
                calorieTarget: double.tryParse(calCtrl.text) ?? 2200.0,
                proteinTargetGrams: double.tryParse(proCtrl.text) ?? 140.0,
                carbTargetGrams: double.tryParse(carbCtrl.text) ?? 250.0,
                fatTargetGrams: double.tryParse(fatCtrl.text) ?? 65.0,
                fiberTargetGrams: double.tryParse(fiberCtrl.text) ?? 30.0,
              );
              await ProfileService.instance.updateNutritionTarget(newTarget);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Save Targets', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit Gemini API Key Modal
  void _openGeminiApiKeyDialog() {
    final keyCtrl = TextEditingController(text: GeminiService.instance.customApiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Google Gemini API Key', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Gemini API Key for online multimodal food vision and advanced reasoning:', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API Key (AIzaSy...)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await GeminiService.instance.setCustomApiKey(keyCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API key updated!'), backgroundColor: AppColors.accentGreen),
                );
              }
            },
            child: const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Backup / Export Data Dialog
  Future<void> _exportDataDialog() async {
    final expenses = await DBHelper.instance.getExpenses();
    final meals = await DBHelper.instance.getMeals();
    final workouts = await DBHelper.instance.getWorkoutPlans();

    final backupJson = jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'profile': {
        'name': ProfileService.instance.userName,
        'weight': ProfileService.instance.weightKg,
        'targetWeight': ProfileService.instance.targetWeightKg,
        'budget': ProfileService.instance.monthlyBudgetCap,
      },
      'expenses': expenses,
      'meals': meals.map((m) => m.toMap()).toList(),
      'workouts': workouts.map((w) => w.toMap()).toList(),
    });

    await Clipboard.setData(ClipboardData(text: backupJson));

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Backup Copied to Clipboard', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Your entire application data (Profile, Fitness, Nutrition, and Finance logs) has been formatted as JSON and copied to your clipboard.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService.instance;
    final currentThemeMode = ThemeService.instance.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile & Body Metrics Section
          _buildSectionHeader('Profile & Fitness Metrics'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  title: Text(profile.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${profile.fitnessGoal} • ${profile.weightKg} kg (Target: ${profile.targetWeightKg} kg)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openProfileEditor,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryGlow,
                    child: Icon(Icons.track_changes_rounded, color: Colors.black),
                  ),
                  title: const Text('Strict Goal Protocol & Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${profile.strictGoalTitle}\nTarget: ${profile.dailyStepTarget} Steps • ${profile.dailyActiveTimeMinutesTarget} Active Mins', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openStrictGoalEditor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance & Theme Mode Section
          _buildSectionHeader('Appearance & Theme'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    currentThemeMode == AppThemeMode.dark ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                    color: currentThemeMode == AppThemeMode.dark ? AppColors.primary : null,
                  ),
                  title: const Text('Dark Mode (Deep Slate)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Optimized for low-light & OLED screens', style: TextStyle(fontSize: 12)),
                  trailing: currentThemeMode == AppThemeMode.dark ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => ThemeService.instance.setThemeMode(AppThemeMode.dark),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    currentThemeMode == AppThemeMode.light ? Icons.light_mode_rounded : Icons.light_mode_outlined,
                    color: currentThemeMode == AppThemeMode.light ? AppColors.primary : null,
                  ),
                  title: const Text('Light Mode (Crisp Snow)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Clean daytime contrast', style: TextStyle(fontSize: 12)),
                  trailing: currentThemeMode == AppThemeMode.light ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => ThemeService.instance.setThemeMode(AppThemeMode.light),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    currentThemeMode == AppThemeMode.system ? Icons.settings_system_daydream_rounded : Icons.settings_system_daydream_outlined,
                    color: currentThemeMode == AppThemeMode.system ? AppColors.primary : null,
                  ),
                  title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Follows operating system preferences', style: TextStyle(fontSize: 12)),
                  trailing: currentThemeMode == AppThemeMode.system ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => ThemeService.instance.setThemeMode(AppThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Finance & Nutrition Section
          _buildSectionHeader('Finance & Nutrition Preferences'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondary),
                  title: const Text('Currency & Budget Cap', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${profile.currencySymbol} • Monthly Budget: ${profile.currencySymbol} ${profile.monthlyBudgetCap.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openFinanceSettings,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restaurant_outlined, color: AppColors.accentGreen),
                  title: const Text('Daily Macro Targets', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${profile.nutritionTarget.calorieTarget.toStringAsFixed(0)} kcal • ${profile.nutritionTarget.proteinTargetGrams.toStringAsFixed(0)}g Protein'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openNutritionSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Coach Configuration
          _buildSectionHeader('AI Intelligence & Keys'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber),
              title: const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(GeminiService.instance.customApiKey != null && GeminiService.instance.customApiKey!.isNotEmpty ? 'Configured (Active)' : 'Default Antigravity Neural Engine'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openGeminiApiKeyDialog,
            ),
          ),
          const SizedBox(height: 16),

          // Data Management & Backup
          _buildSectionHeader('Data Management'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: AppColors.accentBlue),
                  title: const Text('Export / Backup Data', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Copy full JSON backup to clipboard', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.copy_rounded),
                  onTap: _exportDataDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
