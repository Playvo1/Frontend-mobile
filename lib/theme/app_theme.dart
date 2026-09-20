import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Central theme so typography, colors, and spacing stay consistent across
/// every screen (Guidelines 4.1). Per Brand_Guidelines.pdf the font is
/// Cairo at weights 400/500/600/700.
class AppTheme {
  AppTheme._();

  /// The family name used everywhere in the app. Exposed so widgets that
  /// need the family directly (e.g. the wordmark) stay in sync with the
  /// theme instead of hardcoding the string 'Cairo'.
  static String get fontFamily => GoogleFonts.cairo().fontFamily!;

  static ThemeData get light {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy900,
        primary: AppColors.navy900,
        secondary: AppColors.orange500,
        surface: AppColors.white,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      inputDecorationTheme: _inputDecorationTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return GoogleFonts.cairoTextTheme(base).copyWith(
      // Screen titles, e.g. "مرحباً بعودتك!".
      headlineSmall: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.navy900,
      ),
      // The Playvo wordmark.
      displaySmall: GoogleFonts.cairo(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.navy900,
      ),
      // Screen subtitles and helper text.
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.navy500,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // Inline links and footer links, e.g. "نسيت كلمة المرور؟".
      labelMedium: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navy900,
      ),
      // Error and countdown text.
      labelSmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.navy500,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme() {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldBackground,
      // Applied automatically when a field's `enabled` is false.
      disabledBorder: border(AppColors.fieldBorder),
      hintStyle: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.hintText,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: border(AppColors.fieldBorder),
      enabledBorder: border(AppColors.fieldBorder),
      focusedBorder: border(AppColors.navy300, width: 1.4),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, width: 1.4),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryButton,
        foregroundColor: AppColors.primaryButtonText,
        disabledBackgroundColor: AppColors.primaryButtonDisabled,
        disabledForegroundColor: AppColors.primaryButtonText,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy900,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        side: const BorderSide(color: AppColors.fieldBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy900,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
