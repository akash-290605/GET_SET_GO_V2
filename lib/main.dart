import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'notification_service.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/profile_service.dart';
import 'services/study_english_service.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/food_tracking_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/study_screen.dart';
import 'screens/english_learning_screen.dart';
import 'screens/discipline_goals_screen.dart';
import 'screens/vitals_activity_screen.dart';
import 'widgets/account_cloud_modal.dart';
import 'widgets/global_search_dialog.dart';

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
    await StudyEnglishService.instance.init();
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
  bool _isSidebarCollapsed = false;

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

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService.instance.isDarkMode(context);
    final profile = ProfileService.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const WorkoutScreen(),
      const FoodTrackingScreen(),
      const ExpenseScreen(),
      const StudyAndEnglishScreen(),
      const EnglishLearningScreen(),
      const AiCoachScreen(),
      const ProgressScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      // Desktop / Wide screen hybrid shell with collapsible sidebar
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(context, isDark),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(context, isDark, profile),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex.clamp(0, screens.length - 1),
                      children: screens,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet compact layout with top bar & bottom navigation
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Navigation Menu',
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
          // Search shortcut
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            tooltip: 'Global Search',
            onPressed: () => showGlobalSearchDialog(context, onNavigateTab: _onTabSelected),
          ),
          // AI Shortcut
          IconButton(
            icon: const Icon(Icons.psychology_rounded, color: AppColors.accentAmber, size: 22),
            tooltip: 'AI Life Coach',
            onPressed: () => _onTabSelected(6),
          ),
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
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex.clamp(0, 5),
        onDestinationSelected: (idx) {
          if (idx == 4) {
            _onTabSelected(4); // Study
          } else if (idx == 5) {
            _onTabSelected(6); // AI Coach
          } else {
            _onTabSelected(idx);
          }
        },
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: AppColors.accentAmber),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology_rounded, color: AppColors.primaryGlow),
            label: 'AI Coach',
          ),
        ],
      ),
    );
  }

  // ================= DESKTOP SIDEBAR =================
  Widget _buildDesktopSidebar(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final width = _isSidebarCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12))),
      ),
      child: Column(
        children: [
          // Logo & Collapse Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GET SET GO',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.1, color: AppColors.primaryGlow),
                      ),
                    ],
                  ),
                IconButton(
                  icon: Icon(_isSidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, size: 20),
                  tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                _buildSidebarNavTile(0, 'Dashboard', Icons.home_rounded),
                _buildSidebarNavTile(1, 'Fitness & Workouts', Icons.fitness_center_rounded),
                _buildSidebarNavTile(2, 'Food & Nutrition AI', Icons.restaurant_rounded),
                _buildSidebarNavTile(3, 'Finance & Budget', Icons.account_balance_wallet_rounded),
                _buildSidebarNavTile(4, 'Study & Academics', Icons.school_rounded),
                _buildSidebarNavTile(5, 'English Mastery', Icons.translate_rounded),
                _buildSidebarNavTile(6, 'AI Life Coach', Icons.psychology_rounded),
                _buildSidebarNavTile(7, 'Progress & Analytics', Icons.analytics_rounded),
                const Divider(height: 20),
                if (!_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text('MORE TOOLS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1.1)),
                  ),
                _buildSidebarActionTile('Vitals & Water', Icons.directions_walk_rounded, AppColors.accentBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen()));
                }),
                _buildSidebarActionTile('Strict Goals', Icons.track_changes_rounded, AppColors.accentRose, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineGoalsScreen()));
                }),
              ],
            ),
          ),

          const Divider(height: 1),
          _buildSidebarNavTile(8, 'Settings', Icons.settings_rounded),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSidebarNavTile(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primaryGlow : AppColors.textMuted),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryGlow : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 14, vertical: 10),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ================= DESKTOP TOP BAR =================
  Widget _buildDesktopTopBar(BuildContext context, bool isDark, ProfileService profile) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$_timeGreeting, ${profile.userName} 👋',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              // Global Search Bar Trigger
              InkWell(
                onTap: () => showGlobalSearchDialog(context, onNavigateTab: _onTabSelected),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Search anything...', style: TextStyle(fontSize: 12.5, color: theme.hintColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // AI Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _onTabSelected(6),
                icon: const Icon(Icons.psychology_rounded, size: 18),
                label: const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
              const SizedBox(width: 10),

              // Theme Switcher
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
                tooltip: isDark ? 'Light Theme' : 'Dark Theme',
                onPressed: () => ThemeService.instance.setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark),
              ),
              const SizedBox(width: 6),

              // Cloud Sync
              IconButton(
                icon: const Icon(Icons.cloud_sync_outlined, size: 22),
                tooltip: 'Account & Cloud Sync',
                onPressed: () => showAccountCloudModal(context),
              ),
              const SizedBox(width: 10),

              // Profile Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  profile.userName.isNotEmpty ? profile.userName.substring(0, 1).toUpperCase() : 'G',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= MOBILE DRAWER =================
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileService.instance;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(icon: Icons.dashboard_outlined, title: 'Main Dashboard', index: 0),
                  _buildDrawerItem(icon: Icons.fitness_center_rounded, title: '7-Day Workout Planner', index: 1),
                  _buildDrawerItem(icon: Icons.restaurant_rounded, title: 'Food Tracking & Nutrition AI', index: 2),
                  _buildDrawerItem(icon: Icons.account_balance_wallet_rounded, title: 'Finance & Budget', index: 3),
                  _buildDrawerItem(icon: Icons.school_rounded, title: 'Study Tracker & 7-Day Plan', index: 4),
                  _buildDrawerItem(icon: Icons.translate_rounded, title: 'English Mastery Suite', index: 5),
                  _buildDrawerItem(icon: Icons.psychology_rounded, title: 'AI Life & Performance Coach', index: 6),
                  _buildDrawerItem(icon: Icons.analytics_rounded, title: 'Progress & Analytics', index: 7),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('MORE TOOLS & ARCHIVES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1.1)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_walk_rounded, color: AppColors.accentAmber),
                    title: const Text('Steps, Active Hrs & Water Hub', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivityAndVitalsScreen()));
                    },
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
                      _onTabSelected(8);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required int index}) {
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
