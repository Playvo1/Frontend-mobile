import 'package:flutter/material.dart';

/// Playvo brand color system — the single Source of Truth for color
/// (Guidelines 4). No screen or widget may define a color literal of its
/// own; if a shade is missing here, it is added here first.
class AppColors {
  AppColors._();

  // ---- Primary brand colors ----
  static const Color navy = navy900;
  static const Color orange = orange500;

  // ---- Navy scale (light -> dark) ----
  static const Color navy50 = Color(0xFFEDF1F5);
  static const Color navy100 = Color(0xFFC7D3DF);
  static const Color navy300 = Color(0xFF7E96AC);
  static const Color navy500 = Color(0xFF3D5C79);
  static const Color navy900 = Color(0xFF01213D);

  // ---- Orange scale (light -> dark), derived from brand orange #FC4B01 ----
  static const Color orange50 = Color(0xFFFFF1EB);
  static const Color orange100 = Color(0xFFFEDCCE);
  static const Color orange300 = Color(0xFFFDA078);
  static const Color orange500 = Color(0xFFFC4B01);
  static const Color orange700 = Color(0xFFC03901);

  // ---- Neutrals ----
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF4F4F4);
  static const Color grey200 = Color(0xFFDFDFDF);
  static const Color grey400 = Color(0xFFB9B9B9);
  static const Color black = Color(0xFF000000);

  // ---- Semantic aliases ----
  static const Color scaffoldBackground = white;
  static const Color fieldBackground = white;
  static const Color fieldBorder = grey200;
  static const Color hintText = grey400;
  static const Color primaryButton = navy900;
  static const Color primaryButtonText = white;
  static const Color linkText = navy900;
  static const Color divider = grey200;

  // Disabled / locked state, used while the account is locked out.
  // TODO(design): confirm these two against the Figma Source of Truth.
  static const Color primaryButtonDisabled = Color(0xFF9AA5B1);
  static const Color fieldDisabled = grey100;

  // ---- Status colors ----
  // Reserved for the fixed status values in Guidelines 3.1 (booking,
  // payment receipt, venue, user) so the same state never gets two
  // different colors on two different screens.
  static const Color error = orange700;
  static const Color errorBackground = orange50;
  static const Color warning = Color(0xFFB77400);
  static const Color success = Color(0xFF1B7F4B);
  static const Color successBackground = Color(0xFFE8F5EE);

  // The confirmation mark on the "password updated" screen.
  // TODO(design): confirm against the Figma Source of Truth.
  static const Color successAccent = Color(0xFF2E7DF6);

  /// The filled heart on the favourites screen, measured from the design.
  static const Color favoriteRed = Color(0xFFEF4444);

  /// Booking status colours, also measured from the design.
  static const Color statusUpcoming = orange500;
  static const Color statusUpcomingBackground = orange50;
  static const Color statusCompleted = Color(0xFF059669);
  static const Color statusCompletedBackground = Color(0xFFE8F5EE);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledBackground = Color(0xFFFDECEC);
  static const Color successAccentHalo = Color(0xFFD9E7FD);
}
