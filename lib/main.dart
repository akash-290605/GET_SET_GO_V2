import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/workout_service.dart';
import 'services/finance_service.dart';
import 'services/food_service.dart';
import 'services/gemini_service.dart';
import 'services/cloud_sync_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_planner_screen.dart';
import 'screens/food_tracking_screen.dart';
import 'screens/finance_dashboard_screen.dart';
import 'screens/progress_analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/titan_ai_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all core services in parallel / safely
  try {
    await ThemeService.instance.init();
  } catch (e) {
    debugPrint('ThemeService init: $e');
  }

  try {
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('AuthService init: $e');
  }

  try {
    await ProfileService.instance.init();
  } catch (e) {
    debugPrint('ProfileService init: $e');
  }

  try {
    await WorkoutService.instance.init();
  } catch (e) {
    debugPrint('WorkoutService init: $e');
  }

  try {
    await FinanceService.instance.init();
  } catch (e) {
    debugPrint('FinanceService init: $e');
  }

  try {
    await FoodService.instance.init();
  } catch (e) {
    debugPrint('FoodService init: $e');
  }

  try {
    await GeminiService.instance.init();
  } catch (e) {
    debugPrint('GeminiService init: $e');
  }

  try {
    await CloudSyncService.instance.init();
  } catch (e) {
    debugPrint('CloudSyncService init: $e');
  }

  runApp(const GetSetGoApp());
}

class GetSetGoApp extends StatelessWidget {
  const GetSetGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final authService = AuthService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([themeService, authService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'GET SET GO',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: themeService.themeMode,
          home: authService.isAuthenticated
              ? const MainNavigationShell()
              : AuthScreen(
                  onAuthenticated: () {
                    // Triggers navigation through authService state update
                  },
                ),
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

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: _navigateToTab),
      const WorkoutPlannerScreen(),
      const FoodTrackingScreen(),
      const FinanceDashboardScreen(),
      const ProgressAnalyticsScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      // Desktop / Tablet layout with responsive NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.black, size: 24),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                      tooltip: 'Ask Titan AI',
                      onPressed: () => TitanAiSheet.show(context),
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: ThemeService.primaryCyan),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center, color: ThemeService.primaryCyan),
                  label: Text('Workout'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant, color: ThemeService.primaryCyan),
                  label: Text('Food AI'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet, color: ThemeService.primaryCyan),
                  label: Text('Finance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights, color: ThemeService.primaryCyan),
                  label: Text('Progress'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: ThemeService.primaryCyan),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Layout with sleek NavigationBar
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Food AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
