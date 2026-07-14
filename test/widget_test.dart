import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/app.dart';

void main() {
  testWidgets('FirebaseErrorScreen shows connection message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FirebaseErrorScreen(message: 'Test init failure'),
      ),
    );

    expect(find.text('Unable to connect'), findsOneWidget);
    expect(find.textContaining('Test init failure'), findsOneWidget);
  });
}
