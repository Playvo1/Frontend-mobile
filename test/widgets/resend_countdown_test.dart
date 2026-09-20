import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/resend_countdown.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ResendCountdown', () {
    testWidgets('counts down, then offers the resend action',
        (WidgetTester tester) async {
      int resends = 0;

      await tester.pumpApp(
        ResendCountdown(
          onResend: () => resends++,
          cooldown: const Duration(seconds: 3),
        ),
      );

      expect(find.text('You can request a new code in 00:03'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('You can request a new code in 00:02'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resend code'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(resends, 1);
      expect(find.text('You can request a new code in 00:03'), findsOneWidget);

      // Let the restarted timer finish so the test ends with no pending timer.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('cancels its timer when removed from the tree',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ResendCountdown(onResend: () {}, cooldown: const Duration(seconds: 30)),
      );
      await tester.pumpApp(const SizedBox.shrink());
      // The test framework fails on a leaked Timer, so reaching here is the
      // assertion.
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
