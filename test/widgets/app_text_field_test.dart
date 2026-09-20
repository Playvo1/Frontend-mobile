import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/widgets/app_text_field.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('shows the validator message when the form is validated',
        (WidgetTester tester) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();

      await tester.pumpApp(
        Form(
          key: formKey,
          child: AppTextField(
            hint: 'Email',
            validator: (String? value) =>
                (value == null || value.isEmpty) ? 'Please enter your email' : null,
          ),
        ),
      );

      expect(find.text('Please enter your email'), findsNothing);
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('hides the text when obscureText is set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const AppTextField(hint: 'Password', obscureText: true),
      );

      final EditableText field =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
    });
  });

  group('PasswordVisibilityToggle', () {
    testWidgets('shows the eye state matching isObscured',
        (WidgetTester tester) async {
      await tester.pumpApp(
        PasswordVisibilityToggle(isObscured: true, onPressed: () {}),
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.pumpApp(
        PasswordVisibilityToggle(isObscured: false, onPressed: () {}),
      );
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
