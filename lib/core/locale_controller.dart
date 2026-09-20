import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language switch. The app listens to [locale] in exactly one
/// place (PlayvoApp), so switching language rebuilds MaterialApp and Flutter
/// handles text direction, date formats, and the built-in Material strings
/// for us — no screen wraps itself in a Directionality of its own.
///
/// The choice is persisted, so it survives a restart.
class LocaleController {
  LocaleController._();

  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static const String _prefsKey = 'playvo_locale';

  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(arabic);

  /// Reads the saved language. Called once from main() before runApp so the
  /// first frame is already in the right language.
  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_prefsKey);
    if (code != null) {
      locale.value = Locale(code);
    }
  }

  static Future<void> toggle() async {
    final Locale next = locale.value == arabic ? english : arabic;
    locale.value = next;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next.languageCode);
  }
}
