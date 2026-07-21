import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome screen renders with create identity and login buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Welcome to Hush'), findsOneWidget);
    expect(find.text('Create Identity'), findsOneWidget);
    expect(find.text('I have an identity'), findsOneWidget);
  });
}
