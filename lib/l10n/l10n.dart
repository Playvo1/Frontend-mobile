import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Shorthand for the generated localizations, so screens read
/// `context.l10n.loginButton` instead of `AppLocalizations.of(context)`.
extension LocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
