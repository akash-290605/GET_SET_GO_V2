import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders branding header, dashboard metrics, and bottom navigation correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsWidgets);

    // Verify bottom navigation destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('AI Coach'), findsOneWidget);

    // Verify dashboard metrics & sections
    expect(find.text('FITNESS & WORKOUT'), findsOneWidget);
    expect(find.text('DAILY NUTRITION'), findsOneWidget);
    expect(find.text('FINANCE & BUDGET'), findsOneWidget);
    expect(find.text('STUDY & ACADEMICS'), findsOneWidget);
  });
}
