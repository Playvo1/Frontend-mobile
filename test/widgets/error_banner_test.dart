import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/error_banner.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ErrorBanner', () {
    testWidgets('renders nothing when there is no message',
        (WidgetTester tester) async {
      await tester.pumpApp(const ErrorBanner(message: null));
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows the message it is given', (WidgetTester tester) async {
      await tester.pumpApp(
        const ErrorBanner(message: 'Incorrect email or password'),
      );
      expect(find.text('Incorrect email or password'), findsOneWidget);
    });
  });
}
