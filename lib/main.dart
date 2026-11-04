import 'package:flutter/material.dart';

import 'app.dart';
import 'core/locale_controller.dart';
import 'core/offline_state.dart';
import 'core/push_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved language before the first frame, so the app never opens
  // in the wrong language for a moment and then flips.
  await LocaleController.load();
  // Reads the last sync time so the offline banner has something to show
  // before the first request finishes.
  await OfflineState.load();
  // Firebase has to be ready before any push can be handled, including the
  // one that may have opened the app.
  await PushNotifications.initialiseFirebase();
  runApp(const PlayvoApp());
}
