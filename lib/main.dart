import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'notification_service.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/profile_service.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/food_tracking_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/study_screen.dart';
import 'screens/discipline_goals_screen.dart';
import 'widgets/account_cloud_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    tz.initializeTimeZones();
  } catch (_) {}
  try {
    await AuthService.instance.init();
  } catch (_) {}
  try {
    await GeminiService.instance.init();
  } catch (_) {}
  try {
    await CloudSyncService.instance.init();
  } catch (_) {}
  try {
    await ProfileService.instance.init();
  } catch (_) {}
  try {
    await ThemeService.instance.init();
  } catch (_) {}
  if (!kIsWeb) {
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDailyAlarms();
    } catch (_) {}
  }
  runApp(const GetSetGoApp());
}

class GetSetGoApp extends StatelessWidget {
  const GetSetGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'GET SET GO',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.instance.lightTheme,
          darkTheme: ThemeService.instance.darkTheme,
          themeMode: ThemeService.instance.flutterThemeMode,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    ProfileService.instance.addListener(_refreshState);
  }

  @override
  void dispose() {
    ProfileService.instance.removeListener(_refreshState);
    super.dispose();
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService.instance.isDarkMode(context);

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const WorkoutScreen(),
      const FoodTrackingScreen(),
      const ExpenseScreen(),
      const AiCoachScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Life Suite & Navigation',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentAmber),
                  SizedBox(width: 4),
                  Text(
                    'GET SET GO',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1, color: AppColors.primaryGlow),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Quick theme toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () {
              ThemeService.instance.setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
            },
          ),
          // Cloud Sync & Account
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined, size: 22),
            tooltip: 'Account & Cloud Sync',
            onPressed: () => showAccountCloudModal(context),
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryGlow),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded, color: AppColors.primaryGlow),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.accentGreen),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondary),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology_rounded, color: AppColors.accentAmber),
            label: 'AI Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.accentPurple),
            label: 'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile.userName.isNotEmpty ? profile.userName.substring(0, 1).toUpperCase() : 'G',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(profile.fitnessGoal, style: TextStyle(fontSize: 12, color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Main Dashboard',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.fitness_center_rounded,
                    title: '7-Day Workout Planner',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.restaurant_rounded,
                    title: 'AI Food Scanner & Nutrition',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Finance & Safe Daily Spend',
                    index: 3,
                  ),
                  _buildDrawerItem(
                    icon: Icons.psychology_rounded,
                    title: 'AI Life & Performance Coach',
                    index: 4,
                  ),
                  _buildDrawerItem(
                    icon: Icons.insights_rounded,
                    title: 'Progress & Analytics',
                    index: 5,
                  ),
                  const Divider(height: 24),

                  // Life Management Suite
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('MORE TOOLS & ARCHIVES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1.1)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.track_changes_rounded, color: AppColors.accentRose),
                    title: const Text('Strict Goals & Apology Archive', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineGoalsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school_rounded, color: AppColors.accentAmber),
                    title: const Text('Study Tracker & STT English', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAndEnglishScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.accentBlue),
                    title: const Text('Cloud Sync & Google Auth', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      showAccountCloudModal(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                    title: const Text('Settings & Preferences', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            // Drawer footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'GET SET GO • Version 3.0 Pro\nAI Fitness & Finance Ecosystem',
                style: TextStyle(fontSize: 11, color: theme.hintColor, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        _onTabSelected(index);
      },
    );
  }
}
