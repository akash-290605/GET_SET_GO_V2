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
