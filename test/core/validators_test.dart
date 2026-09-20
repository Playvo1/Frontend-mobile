import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/core/validators.dart';
import 'package:playvo/l10n/l10n.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('Validators.email', () {
    test('rejects an empty value', () {
      expect(Validators.email('  ', l10n), l10n.emailRequired);
    });

    test('rejects an address with no domain dot', () {
      expect(Validators.email('omar@example', l10n), l10n.emailInvalid);
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('omar@example.com', l10n), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('rejects anything shorter than the agreed minimum', () {
      expect(Validators.newPassword('Str0ng', l10n), l10n.passwordTooShort);
    });

    test('rejects letters with no digit', () {
      expect(
        Validators.newPassword('StrongPassword', l10n),
        l10n.passwordNeedsLetterAndDigit,
      );
    });

    test('accepts a password meeting the backend rule', () {
      expect(Validators.newPassword('Str0ngPass', l10n), isNull);
    });
  });

  group('Validators.optionalPhone', () {
    test('accepts an empty value, because phone is optional at signup', () {
      expect(Validators.optionalPhone('', l10n), isNull);
    });

    test('rejects letters', () {
      expect(Validators.optionalPhone('05991abcd', l10n), l10n.phoneInvalid);
    });

    test('accepts a local number', () {
      expect(Validators.optionalPhone('0599123456', l10n), isNull);
    });
  });
}
