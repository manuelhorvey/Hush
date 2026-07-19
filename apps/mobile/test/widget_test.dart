import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/app.dart';

void main() {
  testWidgets('app navigates from splash to welcome', (WidgetTester tester) async {
    await tester.pumpWidget(const HushApp());

    expect(find.text('Hush'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Welcome to Hush'), findsOneWidget);
  });
}
