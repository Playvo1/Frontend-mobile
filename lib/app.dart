import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/locale_controller.dart';
import 'l10n/l10n.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Root of the application.
///
/// This is the only place that listens to [LocaleController]. Setting
/// `locale` on MaterialApp makes Flutter handle text direction, number and
/// date formatting, and the built-in Material strings for Arabic — which is
/// why no screen wraps itself in a Directionality of its own.
class PlayvoApp extends StatelessWidget {
  const PlayvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (BuildContext context, Locale locale, Widget? child) {
        return MaterialApp(
          onGenerateTitle: (BuildContext context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
