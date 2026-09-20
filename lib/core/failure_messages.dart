import '../l10n/l10n.dart';
import 'api_exception.dart';

/// Turns an [ApiException] into a message a player can read, in their own
/// language. Kept out of the screens so error wording is consistent and
/// error handling stays separate from the flow logic (Guidelines 2.1).
class FailureMessages {
  FailureMessages._();

  static String of(ApiException exception, AppLocalizations l10n) {
    switch (exception.kind) {
      case ApiFailureKind.noInternet:
        return l10n.errorNoInternet;
      case ApiFailureKind.timeout:
        return l10n.errorTimeout;
      case ApiFailureKind.server:
        return l10n.errorServer;
      case ApiFailureKind.malformedResponse:
      case ApiFailureKind.unexpected:
        return l10n.errorUnexpected;
    }
  }
}
