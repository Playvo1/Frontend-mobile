import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';

/// Every navigation in the app goes through one of these methods.
///
/// Named routes were dropped deliberately: half the screens need typed
/// arguments (the OTP screen needs a purpose and an email, the reset screen
/// needs an email and a code), and a route table passes those as
/// `Object?` that each screen then casts. Constructors give the compiler
/// the chance to catch a missing argument instead. Deep links are not a
/// requirement yet (YAGNI, Guidelines 2.1); when they are, this class is
/// the one place that changes.
class AppRouter {
  AppRouter._();

  /// Clears the whole stack — used after logout, after email verification,
  /// and after a password reset, so Back cannot return into a finished flow.
  static Future<void> toLoginAndClearStack(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toHomeAndClearStack(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toSignup(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
    );
  }

  static Future<void> toForgotPassword(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  static Future<void> toOtpVerification(
    BuildContext context, {
    required OtpPurpose purpose,
    required String email,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpVerificationScreen(purpose: purpose, email: email),
      ),
    );
  }

  /// The email and the verified code are carried in, because
  /// `POST /auth/reset-password` needs all three of email, code and the new
  /// password in one request (Guidelines 7.2).
  static Future<void> toResetPassword(
    BuildContext context, {
    required String email,
    required String code,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(email: email, code: code),
      ),
    );
  }
}
