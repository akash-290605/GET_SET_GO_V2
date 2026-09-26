import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders branding header, dashboard metrics, and bottom navigation correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);

    // Verify BMI badge chip
    expect(find.text('BMI --'), findsOneWidget);

    // Verify bottom navigation destinations
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Modules Menu'), findsOneWidget);

    // Verify dashboard metrics & sections
    expect(find.text('DISCIPLINE & METRICS HUB'), findsOneWidget);
    expect(find.text('DISCIPLINE STREAKS'), findsOneWidget);
    expect(find.text('ACTIVE STREAKS'), findsOneWidget);
  });
}
