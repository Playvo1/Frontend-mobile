import 'package:flutter/material.dart';

import 'app.dart';
import 'core/locale_controller.dart';
import 'core/offline_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved language before the first frame, so the app never opens
  // in the wrong language for a moment and then flips.
  await LocaleController.load();
  // Reads the last sync time so the offline banner has something to show
  // before the first request finishes.
  await OfflineState.load();
  runApp(const PlayvoApp());
}
