import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton displays text and triggers callback when pressed', (
    WidgetTester tester,
  ) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Submit Assignment',
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Submit Assignment'), findsOneWidget);
    await tester.tap(find.text('Submit Assignment'));
    await tester.pump();

    expect(wasPressed, isTrue);
  });

  testWidgets('AppButton shows loading spinner when isLoading is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(text: 'Save Note', isLoading: true)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
