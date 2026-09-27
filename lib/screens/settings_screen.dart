import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/finance_service.dart';
import '../services/food_service.dart';
import '../services/gemini_service.dart';
import '../services/theme_service.dart';
import '../services/workout_service.dart';
import '../models/food_models.dart';
import '../widgets/account_cloud_modal.dart';
import '../widgets/body_photo_modal.dart';
import '../widgets/weekly_report_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeService = ThemeService.instance;
    final authService = AuthService.instance;
    final profileService = ProfileService.instance;
    final geminiService = GeminiService.instance;
    final foodService = FoodService.instance;
    final financeService = FinanceService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([themeService, authService, profileService, geminiService, foodService, financeService]),
      builder: (context, _) {
        final profile = profileService.profile;
        final user = authService.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Configuration'),
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_sync_outlined),
                tooltip: 'Cloud Sync & Vault',
                onPressed: () => AccountCloudModal.show(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Account & Profile Header Card
              _buildProfileCard(user, profile, isDark, profileService),
              const SizedBox(height: 18),

              // 1.5 Strict Goal & Telemetry Settings
              _buildSectionHeader('STRICT GOALS & TELEMETRY PROTOCOL'),
              _buildStrictGoalsCard(profile, profileService, isDark),
              const SizedBox(height: 18),

              // 2. Appearance Section
              _buildSectionHeader('APPEARANCE & THEME'),
              _buildAppearanceCard(themeService, isDark),
              const SizedBox(height: 18),

              // 3. AI Preferences & Gemini API Key
              _buildSectionHeader('TITAN AI & GEMINI CONFIGURATION'),
              _buildAiConfigCard(geminiService, isDark),
              const SizedBox(height: 18),

              // 4. Fitness & Nutrition Targets
              _buildSectionHeader('NUTRITION & MACRO TARGETS'),
              _buildNutritionTargetsCard(foodService, isDark),
              const SizedBox(height: 18),

              // 5. Finance Preferences
              _buildSectionHeader('FINANCE & CURRENCY PREFERENCES'),
              _buildFinanceConfigCard(profile, financeService, profileService, isDark),
              const SizedBox(height: 18),

              // 6. Data Management & Reset
              _buildSectionHeader('DATA MANAGEMENT & BACKUP'),
              _buildDataManagementCard(context, isDark),
              const SizedBox(height: 36),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
      ),
    );
  }

  // 1. Profile Editor Card
  Widget _buildProfileCard(dynamic user, dynamic profile, bool isDark, ProfileService profileService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ThemeService.primaryCyan.withValues(alpha: 0.2),
                backgroundImage: user?.photoUrl.isNotEmpty == true ? NetworkImage(user.photoUrl) : null,
                child: user?.photoUrl.isEmpty == true ? const Icon(Icons.person, color: ThemeService.primaryCyan, size: 30) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.fitnessGoal} • ${profile.currentWeightKg}kg • ${profile.activityLevel}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showProfileEditor(context, profileService),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Edit Profile', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1.5 Strict Goals & Telemetry Card
  Widget _buildStrictGoalsCard(UserProfile profile, ProfileService profileService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.isStrictMode
              ? ThemeService.primaryCyan.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeService.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: ThemeService.primaryCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Strict Goal Protocol',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        if (profile.isStrictMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeService.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'STRICT ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: ThemeService.primaryCyan,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.strictGoalTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: profile.isStrictMode,
                activeTrackColor: ThemeService.primaryCyan,
                onChanged: (val) {
                  profileService.updateStrictGoal(isStrictMode: val);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Step Target', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.dailyStepTarget} steps',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThemeService.primaryCyan),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Active Target', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.dailyActiveTimeMinutesTarget} mins',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current BMI', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThemeService.primaryEmerald),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showStrictGoalEditor(context, profileService),
                icon: const Icon(Icons.tune, size: 14),
                label: const Text('Edit Targets & Goal', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              ),
              OutlinedButton.icon(
                onPressed: () => WeeklyReportModal.show(context),
                icon: const Icon(Icons.analytics_outlined, size: 14, color: ThemeService.primaryCyan),
                label: const Text('Weekly BMI Report', style: TextStyle(fontSize: 12, color: ThemeService.primaryCyan)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              ),
              OutlinedButton.icon(
                onPressed: () => BodyPhotoModal.show(context),
                icon: const Icon(Icons.camera_alt_outlined, size: 14, color: ThemeService.primaryEmerald),
                label: Text('Body Photos (${profile.bodyPhotos.length})', style: const TextStyle(fontSize: 12, color: ThemeService.primaryEmerald)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStrictGoalEditor(BuildContext context, ProfileService profileService) {
    final p = profileService.profile;
    final titleCtrl = TextEditingController(text: p.strictGoalTitle);
    final stepCtrl = TextEditingController(text: p.dailyStepTarget.toString());
    final activeCtrl = TextEditingController(text: p.dailyActiveTimeMinutesTarget.toString());
    bool isStrict = p.isStrictMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Strict Goal & Telemetry Target',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Strict Goal Heading Banner',
                        hintText: 'e.g. Strict 10,000 Steps & Lean Hypertrophy Protocol',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stepCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily Step Target',
                              prefixIcon: Icon(Icons.directions_walk_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: activeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Active Time (Mins)',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enforce Strict Mode Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Highlight strict discipline banners and target compliance badges', style: TextStyle(fontSize: 12)),
                      value: isStrict,
                      activeTrackColor: ThemeService.primaryCyan,
                      onChanged: (val) => setModalState(() => isStrict = val),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        final st = int.tryParse(stepCtrl.text.trim()) ?? p.dailyStepTarget;
                        final at = int.tryParse(activeCtrl.text.trim()) ?? p.dailyActiveTimeMinutesTarget;
                        profileService.updateStrictGoal(
                          strictGoalTitle: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : p.strictGoalTitle,
                          dailyStepTarget: st,
                          dailyActiveTimeMinutesTarget: at,
                          isStrictMode: isStrict,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Strict Goal Protocol updated successfully!')),
                        );
                      },
                      child: const Text('Save Strict Goal Protocol'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Appearance Selector
  Widget _buildAppearanceCard(ThemeService themeService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Theme Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
              ButtonSegment(value: AppThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 16)),
              ButtonSegment(value: AppThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android, size: 16)),
            ],
            selected: {themeService.mode},
            onSelectionChanged: (set) {
              themeService.setMode(set.first);
            },
          ),
        ],
      ),
    );
  }

  // 3. AI Config Card
  Widget _buildAiConfigCard(GeminiService gemini, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 20, color: ThemeService.primaryCyan),
              const SizedBox(width: 10),
              const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text(
                gemini.apiKey.isNotEmpty ? 'Active' : 'Offline Grounded Engine',
                style: TextStyle(fontSize: 12, color: gemini.apiKey.isNotEmpty ? ThemeService.primaryEmerald : Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            controller: TextEditingController(text: gemini.apiKey),
            onSubmitted: (val) => gemini.setApiKey(val),
            decoration: InputDecoration(
              hintText: 'Paste Google Gemini API Key...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API configuration updated!')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active AI Model', style: TextStyle(fontSize: 13)),
              DropdownButton<String>(
                value: gemini.selectedModel,
                items: const [
                  DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash')),
                  DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('Gemini 2.0 Flash')),
                ],
                onChanged: (val) {
                  if (val != null) gemini.setModel(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Nutrition Targets Card
  Widget _buildNutritionTargetsCard(FoodService food, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calorie Target', style: TextStyle(fontSize: 13)),
              Text('${food.macroTargets.calorieTarget.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Protein Target', style: TextStyle(fontSize: 13)),
              Text('${food.macroTargets.proteinTargetGrams.toStringAsFixed(0)} g', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Hydration Target', style: TextStyle(fontSize: 13)),
              Text('${(food.macroTargets.waterMlTarget / 1000).toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showMacroEditor(context, food),
            child: const Text('Update Nutrition Targets'),
          ),
        ],
      ),
    );
  }

  // 5. Finance Config Card
  Widget _buildFinanceConfigCard(dynamic profile, FinanceService finance, ProfileService profileService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Currency Symbol', style: TextStyle(fontSize: 13)),
              DropdownButton<String>(
                value: profile.currencySymbol,
                items: const [
                  DropdownMenuItem(value: '₹', child: Text('INR (₹)')),
                  DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                  DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                  DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                ],
                onChanged: (sym) {
                  if (sym != null) {
                    profileService.updateProfile(profile.copyWith(currencySymbol: sym));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Target Budget', style: TextStyle(fontSize: 13)),
              Text('${profile.currencySymbol}${finance.monthlyBudget.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Data Management Card
  Widget _buildDataManagementCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_sync, color: ThemeService.primaryCyan),
            title: const Text('Cloud Firestore & Portable Vault', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Backup or restore JSON vault', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
            onTap: () => AccountCloudModal.show(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
            title: const Text('Reset Workouts to Default Split', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              await WorkoutService.instance.resetAllToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset workout schedule to default science-backed split!')));
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign Out Session', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              await AuthService.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showProfileEditor(BuildContext context, ProfileService profileService) {
    final p = profileService.profile;
    final nameCtrl = TextEditingController(text: p.name);
    final ageCtrl = TextEditingController(text: p.age.toString());
    final heightCtrl = TextEditingController(text: p.heightCm.toString());
    final weightCtrl = TextEditingController(text: p.currentWeightKg.toString());
    final targetWeightCtrl = TextEditingController(text: p.targetWeightKg.toString());
    String goal = p.fitnessGoal;
    String activity = p.activityLevel;
    String equip = p.availableEquipment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Edit Profile & Biometrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display Name')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Weight (kg)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: targetWeightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Weight (kg)'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: goal,
                      decoration: const InputDecoration(labelText: 'Fitness Goal'),
                      items: ['Muscle Gain', 'Weight Loss', 'Endurance', 'Maintenance']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => goal = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: activity,
                      decoration: const InputDecoration(labelText: 'Activity Level'),
                      items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => activity = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: equip,
                      decoration: const InputDecoration(labelText: 'Available Equipment'),
                      items: ['Full Gym', 'Dumbbells & Bands', 'Home / Bodyweight']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => equip = val);
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        profileService.updateProfile(p.copyWith(
                          name: nameCtrl.text.trim(),
                          age: int.tryParse(ageCtrl.text) ?? p.age,
                          heightCm: double.tryParse(heightCtrl.text) ?? p.heightCm,
                          currentWeightKg: double.tryParse(weightCtrl.text) ?? p.currentWeightKg,
                          targetWeightKg: double.tryParse(targetWeightCtrl.text) ?? p.targetWeightKg,
                          fitnessGoal: goal,
                          activityLevel: activity,
                          availableEquipment: equip,
                        ));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMacroEditor(BuildContext context, FoodService food) {
    final calCtrl = TextEditingController(text: food.macroTargets.calorieTarget.toStringAsFixed(0));
    final proCtrl = TextEditingController(text: food.macroTargets.proteinTargetGrams.toStringAsFixed(0));
    final carbCtrl = TextEditingController(text: food.macroTargets.carbsTargetGrams.toStringAsFixed(0));
    final fatCtrl = TextEditingController(text: food.macroTargets.fatTargetGrams.toStringAsFixed(0));
    final waterCtrl = TextEditingController(text: food.macroTargets.waterMlTarget.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Configure Macro Targets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: proCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: waterCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Water Target (ml)')),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  food.updateTargets(MacroTargets(
                    calorieTarget: double.tryParse(calCtrl.text) ?? 2200.0,
                    proteinTargetGrams: double.tryParse(proCtrl.text) ?? 130.0,
                    carbsTargetGrams: double.tryParse(carbCtrl.text) ?? 250.0,
                    fatTargetGrams: double.tryParse(fatCtrl.text) ?? 65.0,
                    waterMlTarget: double.tryParse(waterCtrl.text) ?? 3000.0,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Update Targets'),
              ),
            ],
          ),
        );
      },
    );
  }
}
