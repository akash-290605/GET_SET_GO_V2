import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders branding header and auth or navigation screen correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.continueAsGuest();

    await tester.pumpWidget(const GetSetGoApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsWidgets);
  });
}
