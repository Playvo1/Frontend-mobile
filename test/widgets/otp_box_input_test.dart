import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/otp_box_input.dart';

import '../helpers/pump_app.dart';

void main() {
  group('OtpBoxInput', () {
    testWidgets('renders one box per digit', (WidgetTester tester) async {
      await tester.pumpApp(OtpBoxInput(onChanged: (_) {}));
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('reports the joined code as digits are typed',
        (WidgetTester tester) async {
      String code = '';
      await tester.pumpApp(OtpBoxInput(onChanged: (String value) => code = value));

      await tester.enterText(find.byType(TextField).at(0), '4');
      await tester.enterText(find.byType(TextField).at(1), '8');

      expect(code, '48');
    });

    testWidgets('spreads a pasted code across the remaining boxes',
        (WidgetTester tester) async {
      String code = '';
      await tester.pumpApp(OtpBoxInput(onChanged: (String value) => code = value));

      await tester.enterText(find.byType(TextField).first, '482913');
      await tester.pump();

      expect(code, '482913');
    });
  });
}
