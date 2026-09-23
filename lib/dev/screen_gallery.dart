import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/reset_success_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';
import '../services/mock_venue_service.dart';
import '../screens/splash_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_selector.dart';
import 'preview_auth_service.dart';

/// A menu that opens every screen and every screen state directly, so the
/// team can review the UI without walking the flows or running a backend.
///
/// DEV ONLY. It is reachable only when the app is built with
/// `--dart-define=PLAYVO_GALLERY=true`, so it can never appear in a release
/// build, and `lib/dev/` is deleted once the real API is connected.
class ScreenGallery extends StatelessWidget {
  const ScreenGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen gallery'),
        backgroundColor: AppColors.navy900,
        foregroundColor: AppColors.white,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
            child: Center(child: LanguageSelector()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: <Widget>[
          const _SectionHeader('Login'),
          _GalleryEntry(
            title: 'Login — default',
            subtitle: 'The plain form, state 1 in the design',
            builder: (_) => const LoginScreen(),
          ),
          _GalleryEntry(
            title: 'Login — wrong credentials',
            subtitle: 'Type anything and press the button. State 2: red field, '
                '4 attempts remaining',
            builder: (_) =>
                LoginScreen(authService: PreviewAuthService.wrongCredentials),
          ),
          _GalleryEntry(
            title: 'Login — locked account',
            subtitle: 'Type anything and press the button. State 3: everything '
                'disabled, 15:00 counting down',
            builder: (_) =>
                LoginScreen(authService: PreviewAuthService.lockedAccount),
          ),

          const _SectionHeader('Registration'),
          _GalleryEntry(
            title: 'Signup',
            builder: (_) =>
                SignupScreen(authService: PreviewAuthService.alwaysOk),
          ),
          _GalleryEntry(
            title: 'OTP — email verification',
            subtitle: 'Verify button',
            builder: (_) => OtpVerificationScreen(
              purpose: OtpPurpose.signupVerification,
              email: 'omar@example.com',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),

          const _SectionHeader('Password reset'),
          _GalleryEntry(
            title: 'Forgot password',
            builder: (_) =>
                ForgotPasswordScreen(authService: PreviewAuthService.alwaysOk),
          ),
          _GalleryEntry(
            title: 'OTP — password reset',
            subtitle: 'Continue button; carries the code forward',
            builder: (_) => OtpVerificationScreen(
              purpose: OtpPurpose.passwordReset,
              email: 'omar@example.com',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),
          _GalleryEntry(
            title: 'Reset password',
            builder: (_) => ResetPasswordScreen(
              email: 'omar@example.com',
              // code: '482913',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),

          _GalleryEntry(
            title: 'Reset password — success',
            subtitle: 'Shown after the password is actually changed',
            builder: (_) => const ResetSuccessScreen(),
          ),

          const _SectionHeader('Home'),
          _GalleryEntry(
            title: 'Home',
            subtitle: 'Sample venues; the filter icon opens the filter sheet',
            builder: (_) => HomeScreen(venueService: MockVenueService()),
          ),

          const _SectionHeader('Other'),
          _GalleryEntry(
            title: 'Splash',
            subtitle: 'Moves on by itself after about a second',
            builder: (_) => const SplashScreen(),
          ),
        ],
      ),
    );
  }
}

/// A group label between sets of entries.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.orange500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

/// One tappable row that pushes the screen it describes.
class _GalleryEntry extends StatelessWidget {
  const _GalleryEntry({
    required this.title,
    required this.builder,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.navy300),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: builder),
      ),
    );
  }
}
