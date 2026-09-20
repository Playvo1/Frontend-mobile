import '../l10n/l10n.dart';

/// Form validation rules shared by every screen, so "what counts as a valid
/// email" is defined once (DRY) and stays in step with the Laravel Form
/// Requests on the other side of the API.
class Validators {
  Validators._();

  /// Deliberately permissive: it rejects obvious typos without locking out
  /// valid but unusual addresses. The server stays the authority.
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Digits, optionally with a leading + and separators.
  static final RegExp _phone = RegExp(r'^\+?[\d\s-]{7,15}$');

  /// Must match the backend rule: at least 8 characters, one letter, one digit.
  static const int minPasswordLength = 8;

  static String? email(String? value, AppLocalizations l10n) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return l10n.emailRequired;
    }
    if (!_email.hasMatch(text)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  /// Used on the login screen, where the only client-side rule is "not
  /// empty" — judging an existing password's strength would be wrong.
  static String? requiredPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    return null;
  }

  /// Used when a new password is being chosen (signup, reset).
  static String? newPassword(String? value, AppLocalizations l10n) {
    final String text = value ?? '';
    if (text.length < minPasswordLength) {
      return l10n.passwordTooShort;
    }
    final bool hasLetter = RegExp(r'[A-Za-z]').hasMatch(text);
    final bool hasDigit = RegExp(r'\d').hasMatch(text);
    if (!hasLetter || !hasDigit) {
      return l10n.passwordNeedsLetterAndDigit;
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String original,
    AppLocalizations l10n,
  ) {
    if (value != original) {
      return l10n.passwordsDontMatch;
    }
    return null;
  }

  static String? fullName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fullNameRequired;
    }
    return null;
  }

  /// Phone is optional at signup (Guidelines 7.2), so an empty value passes.
  static String? optionalPhone(String? value, AppLocalizations l10n) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!_phone.hasMatch(text)) {
      return l10n.phoneInvalid;
    }
    return null;
  }
}
