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
import 'widgets/live_animated_background.dart';

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
    final isDark = ThemeService.instance.isDarkMode(context);
    final profile = ProfileService.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const WorkoutScreen(),
      const FoodTrackingScreen(),
      const DailyActivityAndVitalsScreen(),
      const DisciplineGoalsScreen(),
      const ExpenseScreen(),
      const StudyAndEnglishScreen(),
      const EnglishLearningScreen(),
      const AiCoachScreen(),
      const ProgressScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      // Desktop / Wide screen hybrid shell with collapsible sidebar & live animated background
      return LiveAnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
        ),
      );
    }

    // Mobile / Tablet compact layout with top bar & bottom navigation
    return LiveAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF11182B).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.90),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary(isDark)),
              tooltip: 'Navigation Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentAmber),
                    SizedBox(width: 5),
                    Text(
                      'GET SET GO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.1,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Search shortcut
            IconButton(
              icon: Icon(Icons.search_rounded, size: 22, color: AppColors.textPrimary(isDark)),
              tooltip: 'Global Search',
              onPressed: () => showGlobalSearchDialog(context, onNavigateTab: _onTabSelected),
            ),
            // AI Shortcut (Tab 8)
            IconButton(
              icon: const Icon(Icons.psychology_rounded, color: AppColors.accentAmber, size: 22),
              tooltip: 'AI Life Coach',
              onPressed: () => _onTabSelected(8),
            ),
            // Quick theme toggle
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20, color: AppColors.textPrimary(isDark)),
              tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
              onPressed: () {
                ThemeService.instance.setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
              },
            ),
            // Cloud Sync & Account
            IconButton(
              icon: Icon(Icons.cloud_sync_outlined, size: 22, color: AppColors.textPrimary(isDark)),
              tooltip: 'Account & Cloud Sync',
              onPressed: () => showAccountCloudModal(context),
            ),
          ],
        ),
        drawer: _buildDrawer(context, isDark),
        body: IndexedStack(
          index: _currentIndex.clamp(0, screens.length - 1),
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF11182B).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: () {
              if (_currentIndex == 0) return 0;
              if (_currentIndex == 1) return 1;
              if (_currentIndex == 2) return 2;
              if (_currentIndex == 3) return 3;
              if (_currentIndex == 4) return 4;
              if (_currentIndex == 8) return 5;
              return 0;
            }(),
            onDestinationSelected: (idx) {
              if (idx == 0) _onTabSelected(0);
              if (idx == 1) _onTabSelected(1);
              if (idx == 2) _onTabSelected(2);
              if (idx == 3) _onTabSelected(3);
              if (idx == 4) _onTabSelected(4);
              if (idx == 5) _onTabSelected(8); // AI Coach
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primary.withValues(alpha: 0.18),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center_rounded, color: AppColors.primary),
                label: 'Workout',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant_rounded, color: AppColors.accentGreen),
                label: 'Nutrition',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_walk_outlined),
                selectedIcon: Icon(Icons.directions_walk_rounded, color: AppColors.accentBlue),
                label: 'Vitals',
              ),
              NavigationDestination(
                icon: Icon(Icons.track_changes_outlined),
                selectedIcon: Icon(Icons.track_changes_rounded, color: AppColors.accentRose),
                label: 'Goals',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology_rounded, color: AppColors.primary),
                label: 'AI Coach',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DESKTOP SIDEBAR =================
  Widget _buildDesktopSidebar(BuildContext context, bool isDark) {
    final width = _isSidebarCollapsed ? 78.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF11182B).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.88),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF1E40AF).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & Collapse Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'GET SET GO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    size: 20,
                    color: AppColors.textSecondary(isDark),
                  ),
                  tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

          // Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                _buildSidebarNavTile(0, 'Dashboard', Icons.home_rounded, isDark),
                _buildSidebarNavTile(1, 'Fitness & Workouts', Icons.fitness_center_rounded, isDark),
                _buildSidebarNavTile(2, 'Food & Nutrition AI', Icons.restaurant_rounded, isDark),
                _buildSidebarNavTile(3, 'Daily Activity & Vitals', Icons.directions_walk_rounded, isDark),
                _buildSidebarNavTile(4, 'Strict Goals & Habits', Icons.track_changes_rounded, isDark),
                _buildSidebarNavTile(5, 'Finance & Budget', Icons.account_balance_wallet_rounded, isDark),
                _buildSidebarNavTile(6, 'Study & Academics', Icons.school_rounded, isDark),
                _buildSidebarNavTile(7, 'English Mastery', Icons.translate_rounded, isDark),
                _buildSidebarNavTile(8, 'AI Life Coach', Icons.psychology_rounded, isDark),
                _buildSidebarNavTile(9, 'Progress & Analytics', Icons.analytics_rounded, isDark),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          _buildSidebarNavTile(10, 'Settings', Icons.settings_rounded, isDark),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSidebarNavTile(int index, String title, IconData icon, bool isDark) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary(isDark),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary(isDark),
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

  // ================= DESKTOP TOP BAR =================
  Widget _buildDesktopTopBar(BuildContext context, bool isDark, ProfileService profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF11182B).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$_timeGreeting, ${profile.userName} 👋',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
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
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary(isDark)),
                      const SizedBox(width: 8),
                      Text(
                        'Search anything...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
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
                  elevation: 0,
                ),
                onPressed: () => _onTabSelected(8),
                icon: const Icon(Icons.psychology_rounded, size: 18),
                label: const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
              const SizedBox(width: 10),

              // Theme Switcher
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: AppColors.textPrimary(isDark),
                ),
                tooltip: isDark ? 'Light Theme' : 'Dark Theme',
                onPressed: () => ThemeService.instance.setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark),
              ),
              const SizedBox(width: 6),

              // Cloud Sync
              IconButton(
                icon: Icon(Icons.cloud_sync_outlined, size: 22, color: AppColors.textPrimary(isDark)),
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
  Widget _buildDrawer(BuildContext context, bool isDark) {
    final profile = ProfileService.instance;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF11182B).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.90),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
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
                        Text(
                          profile.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        Text(
                          profile.fitnessGoal,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  _buildDrawerItem(icon: Icons.dashboard_outlined, title: 'Main Dashboard', index: 0, isDark: isDark),
                  _buildDrawerItem(icon: Icons.fitness_center_rounded, title: '7-Day Workout Planner', index: 1, isDark: isDark),
                  _buildDrawerItem(icon: Icons.restaurant_rounded, title: 'Food Tracking & Nutrition AI', index: 2, isDark: isDark),
                  _buildDrawerItem(icon: Icons.directions_walk_rounded, title: 'Steps, Vitals & Water Hub', index: 3, isDark: isDark),
                  _buildDrawerItem(icon: Icons.track_changes_rounded, title: 'Strict Goals & Discipline', index: 4, isDark: isDark),
                  _buildDrawerItem(icon: Icons.account_balance_wallet_rounded, title: 'Finance & Budget', index: 5, isDark: isDark),
                  _buildDrawerItem(icon: Icons.school_rounded, title: 'Study Tracker & 7-Day Plan', index: 6, isDark: isDark),
                  _buildDrawerItem(icon: Icons.translate_rounded, title: 'English Mastery Suite', index: 7, isDark: isDark),
                  _buildDrawerItem(icon: Icons.psychology_rounded, title: 'AI Life & Performance Coach', index: 8, isDark: isDark),
                  _buildDrawerItem(icon: Icons.analytics_rounded, title: 'Progress & Analytics', index: 9, isDark: isDark),
                  Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildDrawerItem(icon: Icons.settings_outlined, title: 'Settings & Preferences', index: 10, isDark: isDark),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.accentBlue),
                    title: Text(
                      'Cloud Sync & Google Auth',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary(isDark)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showAccountCloudModal(context);
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

  Widget _buildDrawerItem({required IconData icon, required String title, required int index, required bool isDark}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary(isDark)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary(isDark),
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
