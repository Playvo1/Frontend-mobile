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

  /// The same host without the `/api/v1` suffix. Uploaded images come
  /// back as server-relative paths ("/storage/venues/x.png"), so they need
  /// the origin prefixed before they can be fetched.
  static String get fileBaseUrl {
    final int apiIndex = apiBaseUrl.indexOf('/api/');
    return apiIndex == -1 ? apiBaseUrl : apiBaseUrl.substring(0, apiIndex);
  }

  /// Turns whatever the API gives for an image into something loadable:
  /// an absolute URL is returned as-is, a relative path gets the origin.
  static String resolveFileUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$fileBaseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  /// 60s rather than 20s because the deployment sleeps when idle and its
  /// first request after waking takes the best part of a minute. At 20s
  /// every cold start read as "the server is not responding".
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Uploading a receipt photo over a weak connection needs longer than a
  /// JSON call.
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// The Postman collection registers a player with a local number
  /// ("05971003855"), so the app sends what was typed. Flip this once the
  /// backend accepts E.164 and the dialling code will be prefixed instead.
  /// TODO(api): confirm which format the backend validates.
  static const bool sendInternationalPhone = false;

  /// How long the user waits before "resend code" becomes tappable. The
  /// code itself expires after 10 minutes server-side (Guidelines 2.4).
  static const Duration resendCooldown = Duration(seconds: 60);

  /// Length of the verification code sent by the backend.
  static const int verificationCodeLength = 6;

  /// Serves the home screen from [MockVenueService] instead of the API.
  /// On by default because `GET /venues` does not exist yet; build with
  /// `--dart-define=PLAYVO_MOCK_VENUES=false` to hit the real endpoint, and
  /// flip the default once the backend ships it.
  static const bool useMockVenues =
      bool.fromEnvironment('PLAYVO_MOCK_VENUES', defaultValue: true);

  /// Opens the dev screen gallery instead of the splash screen. Off unless
  /// the build passes `--dart-define=PLAYVO_GALLERY=true`, so it can never
  /// reach a release build.
  static const bool showScreenGallery = bool.fromEnvironment('PLAYVO_GALLERY');
}
