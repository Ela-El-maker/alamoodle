import 'package:alarmmaster/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('My Alarms'), findsOneWidget);
    expect(find.text('Add Alarm'), findsOneWidget);
  });
}
