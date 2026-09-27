import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders branding header, dashboard metrics, and bottom navigation correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GetSetGoApp());
    await tester.pumpAndSettle();

    // Verify GET SET GO branding is present
    expect(find.text('GET SET GO'), findsOneWidget);

    // Verify bottom navigation destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('AI Coach'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);

    // Verify dashboard metrics & sections
    expect(find.text('FITNESS & WORKOUT'), findsOneWidget);
    expect(find.text('DAILY NUTRITION INTAKE'), findsOneWidget);
    expect(find.text('MONTHLY FINANCE'), findsOneWidget);
  });
}
