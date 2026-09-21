/// Environment-dependent configuration. Values come from `--dart-define`
/// so no host or key is ever committed to Git (Guidelines 2.4), and each
/// environment (local / staging / production) builds with its own values.
///
/// Example:
///   flutter run --dart-define=PLAYVO_API_BASE_URL=https://staging.playvo.app/api/v1
class AppConfig {
  AppConfig._();

  /// Always includes the `/api/v1` version prefix (Guidelines 2.2).
  static const String apiBaseUrl = String.fromEnvironment(
    'PLAYVO_API_BASE_URL',
  defaultValue: 'http://10.166.0.178:8000/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  /// How long the user waits before "resend code" becomes tappable. The
  /// code itself expires after 10 minutes server-side (Guidelines 2.4).
  static const Duration resendCooldown = Duration(seconds: 60);

  /// Length of the verification code sent by the backend.
  static const int verificationCodeLength = 6;
}
