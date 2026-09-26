import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/gemini_service.dart';
import 'package:flutter_application_1/services/cloud_sync_service.dart';
import 'package:flutter_application_1/models/workout_template_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App renders branding header, dashboard metrics, and bottom navigation correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await AuthService.instance.init();
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);

    // Verify Titan AI button is present
    expect(find.text('TITAN AI'), findsOneWidget);

    // Verify mobile navigation destinations
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Modules Menu'), findsOneWidget);
  });

  test('WorkoutSplitTemplates generates 7 distinct days with weight & reps volume', () {
    final splits = WorkoutSplitTemplates.getWeeklySplits();
    expect(splits.length, 7);

    // Monday (Chest & Tri)
    final mon = splits.firstWhere((s) => s.dayOfWeek == 'Monday');
    expect(mon.exercises.isNotEmpty, true);
    expect(mon.exercises.first.name, contains('Bench Press'));
    expect(mon.totalTargetSets, greaterThan(10));

    // Verify Volume calculation
    final firstEx = mon.exercises.first;
    firstEx.sets.first.isCompleted = true;
    expect(firstEx.sets.first.volumeTonnage, equals(firstEx.sets.first.weightKg * firstEx.sets.first.reps));
  });

  test('GeminiService offline heuristic returns high-IQ coaching blueprints', () async {
    final workoutAdvice = await GeminiService.instance.generateDayWorkoutPlan(
      dayOfWeek: 'Monday',
      targetMuscles: 'Chest & Triceps',
      userWeightKg: 75.0,
      fitnessGoal: 'Hypertrophy & Strength',
      recentExerciseHistory: [],
    );
    expect(workoutAdvice, contains('TITAN AI WORKOUT BLUEPRINT'));
    expect(workoutAdvice, contains('Progressive Overload Rule'));

    final expenseAudit = await GeminiService.instance.auditExpenses(
      monthlyBudget: 30000,
      totalSpent: 8500,
      daysLeftInMonth: 22,
      recentExpenses: [],
    );
    expect(expenseAudit, contains('TITAN AI FINANCIAL MASTERY AUDIT'));
  });

  test('CloudSyncService exports valid JSON backup vault', () async {
    final jsonExport = await CloudSyncService.instance.exportFullJsonBackup();
    expect(jsonExport, contains('GET SET GO - Growth & Discipline Engine'));
    expect(jsonExport, contains('user'));
    expect(jsonExport, contains('goals'));
  });
}
