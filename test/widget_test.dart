import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App presents LoginScreen when unauthenticated and MainNavigationShell upon authentication', (WidgetTester tester) async {
    // 1. Launch App in unauthenticated state
    await AuthService.instance.signOut();
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify LoginScreen branding and action triggers
    expect(find.text('GET SET GO'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);

    // 2. Authenticate user
    await AuthService.instance.signInWithGoogle();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify MainNavigationShell is rendered with all primary destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Vitals'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('AI Coach'), findsOneWidget);
  });
}
