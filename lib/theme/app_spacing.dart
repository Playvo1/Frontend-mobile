/// Spacing and radius scale — part of the Source of Truth (Guidelines 4).
/// Screens use these named steps instead of raw numbers, so a change to
/// the rhythm of the app happens in one file.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 28;

  /// Horizontal padding applied to the body of every screen.
  static const double screenHorizontal = 16;

  /// Vertical padding applied to the body of every screen.
  static const double screenVertical = 16;

  static const double radiusField = 14;
  static const double radiusButton = 14;

  static const double buttonHeight = 54;
  static const double otpBoxWidth = 44;
  static const double otpBoxHeight = 52;
}
