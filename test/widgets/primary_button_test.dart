import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/primary_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('shows its label and calls onPressed when tapped',
        (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpApp(
        PrimaryButton(label: 'Log in', onPressed: () => taps++),
      );

      expect(find.text('Log in'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
    });

    testWidgets('swaps the label for a spinner and blocks taps while loading',
        (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpApp(
        PrimaryButton(
          label: 'Log in',
          isLoading: true,
          onPressed: () => taps++,
        ),
      );

      expect(find.text('Log in'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0, reason: 'a loading button must not submit twice');
    });
  });
}
