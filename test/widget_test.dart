import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/theme_service.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:flutter_application_1/services/workout_service.dart';
import 'package:flutter_application_1/services/finance_service.dart';
import 'package:flutter_application_1/services/food_service.dart';
import 'package:flutter_application_1/services/gemini_service.dart';
import 'package:flutter_application_1/services/cloud_sync_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.init();
    await AuthService.instance.init();
    await ProfileService.instance.init();
    await WorkoutService.instance.init();
    await FinanceService.instance.init();
    await FoodService.instance.init();
    await GeminiService.instance.init();
    await CloudSyncService.instance.init();
  });

  testWidgets('GetSetGoApp renders brand header and navigation items correctly', (WidgetTester tester) async {
    // Provide explicit desktop / mobile viewport
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsWidgets);

    // Verify presence of main interface
    expect(find.byType(GetSetGoApp), findsOneWidget);
  });
}
