import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_ready/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DisasterReadyApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DisasterReadyApp), findsOneWidget);
  });
}
