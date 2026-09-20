import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/or_divider.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('OrDivider shows its label between two rules',
      (WidgetTester tester) async {
    await tester.pumpApp(const OrDivider(label: 'or'));

    expect(find.text('or'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
