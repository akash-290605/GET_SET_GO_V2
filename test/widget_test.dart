import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/gemini_service.dart';
import 'package:flutter_application_1/screens/expense_screen.dart';
import 'package:flutter_application_1/screens/ai_coach_screen.dart';
import 'package:flutter_application_1/screens/workout_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.init();
    await GeminiService.instance.init();
    await AuthService.instance.signOut();
  });

  testWidgets('App launches with AuthScreen onboarding gate when not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    // Verify GET SET GO branding and Auth components
    expect(find.text('GET SET GO'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Firebase Cloud: get-set-go-ad19f'), findsOneWidget);
    expect(find.text('Continue as Guest / Offline Demo'), findsOneWidget);
  });

  testWidgets('Tapping Guest Mode transitions to MainNavigationShell and Master Dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    final guestBtn = find.text('Continue as Guest / Offline Demo');
    expect(guestBtn, findsOneWidget);
    await tester.ensureVisible(guestBtn);
    await tester.tap(guestBtn);
    await tester.pumpAndSettle();

    // Verify Dashboard is rendered with top branding and bottom navigation
    expect(find.text('GET SET GO'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Modules Menu'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsWidgets);
    expect(find.byIcon(Icons.cloud_sync_rounded), findsWidgets);
  });

  testWidgets('ExpenseScreen renders Credit/Debit tabs, Net Balance and Monthly Target Cap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpenseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FINANCE & CASHFLOW'), findsOneWidget);
    expect(find.text('📊 Overview'), findsOneWidget);
    expect(find.text('NET CASH BALANCE'), findsOneWidget);
    expect(find.text('Monthly Target Spend Cap'), findsOneWidget);
    expect(find.text('Safe Daily Spend Allowance'), findsOneWidget);
  });

  testWidgets('AiCoachScreen renders Titan AI intelligence interface and prompt chips', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiCoachScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TITAN AI COACH'), findsOneWidget);
    expect(find.text('Ask Titan about workouts, diets, expenses...'), findsOneWidget);
    expect(find.text('💰 Reduce Expenses'), findsOneWidget);
  });

  testWidgets('WorkoutScreen renders 7-day splits and exercise protocols', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7-DAY GYM SPLITS & VOLUME'), findsOneWidget);
    expect(find.text('EXERCISE PROTOCOLS'), findsOneWidget);
  });
}
