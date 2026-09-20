import 'package:flutter/material.dart';

import 'app.dart';
import 'core/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved language before the first frame, so the app never opens
  // in the wrong language for a moment and then flips.
  await LocaleController.load();
  runApp(const PlayvoApp());
}
