import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/device_token_service.dart';

/// Handles a push that arrives while the app is terminated or backgrounded.
///
/// It must be a top-level function: Flutter spins up a separate isolate for
/// it, which cannot reach anything from the running app.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Nothing to draw here — the system tray shows the notification itself.
  // This exists so the isolate starts cleanly and the payload is delivered.
}

/// Sets up Firebase Cloud Messaging and keeps the device token registered
/// with the backend (SRS FR-28, and the DEVICE_TOKEN entity in the ERD).
class PushNotifications {
  PushNotifications({DeviceTokenService? tokenService})
      : _tokenService = tokenService ?? DeviceTokenService();

  final DeviceTokenService _tokenService;

  /// The notification the player tapped to open the app, if any. The home
  /// screen reads it once and routes from there.
  static RemoteMessage? initialMessage;

  /// True once Firebase started successfully. While it is false the app
  /// runs normally and simply cannot receive pushes.
  static bool isAvailable = false;

  /// Called from main() before runApp.
  ///
  /// Never throws. A missing or malformed `google-services.json` is a
  /// configuration problem, not a reason the player cannot open the app —
  /// so the failure is recorded and swallowed here rather than taking the
  /// whole launch down.
  static Future<void> initialiseFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      isAvailable = true;
    } on Object catch (error) {
      isAvailable = false;
      debugPrint(
        'Firebase is not configured, so push notifications are off: $error',
      );
    }
  }

  /// Asks for permission and registers the token.
  ///
  /// Called after sign-in rather than on launch: a token is only useful
  /// once it can be tied to an account, and asking before the player has
  /// seen the app is the fastest way to a refusal.
  Future<void> start() async {
    if (!isAvailable) {
      return;
    }

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    final NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Not an error: the app works, it just cannot notify.
      return;
    }

    final String? token = await messaging.getToken();
    if (token != null) {
      await _register(token);
    }

    // Firebase rotates tokens; a stale one silently stops delivering.
    messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String token) async {
    try {
      await _tokenService.register(token);
    } on Exception catch (error) {
      // A failed registration must not block the app; the next refresh or
      // the next launch tries again.
      debugPrint('Device token registration failed: $error');
    }
  }

  /// Removes the token so a signed-out device stops receiving the previous
  /// player's notifications.
  Future<void> stop() async {
    if (!isAvailable) {
      return;
    }

    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      try {
        await _tokenService.unregister(token);
      } on Exception {
        // The local token is deleted either way.
      }
    }
    await FirebaseMessaging.instance.deleteToken();
  }

  /// Pushes that arrive while the app is open and in front. The system does
  /// not draw these, so the screen decides what to show.
  static Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// Taps on a notification while the app was in the background.
  static Stream<RemoteMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp;
}
