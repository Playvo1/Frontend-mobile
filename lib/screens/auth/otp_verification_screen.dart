import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_config.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../l10n/l10n.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth_screen_scaffold.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/otp_box_input.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/resend_countdown.dart';

/// What this verification code is for. It decides which endpoint the code
/// is checked against and where the flow continues, so the one screen in
/// the design serves both flows.
enum OtpPurpose { signupVerification, passwordReset }

/// Six-digit code entry for email verification and for password reset.
///
/// For a password reset the code is NOT verified here: the backend checks
/// email + code + new password together in a single
/// `POST /auth/reset-password` call (Guidelines 7.2), so this screen carries
/// the code forward to the reset screen instead of spending it early.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.purpose,
    required this.email,
    this.authService,
  });

  final OtpPurpose purpose;
  final String email;
  final AuthService? authService;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  String _code = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isSignup => widget.purpose == OtpPurpose.signupVerification;

  Future<void> _handleSubmit() async {
    final AppLocalizations l10n = context.l10n;

    if (_code.length < AppConfig.verificationCodeLength) {
      setState(() => _errorMessage = l10n.otpIncomplete);
      return;
    }

    if (!_isSignup) {
      await AppRouter.toResetPassword(
        context,
        email: widget.email,
        code: _code,
      );
      return;
    }

    await _verifyEmail(l10n);
  }

  Future<void> _verifyEmail(AppLocalizations l10n) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<void> response = await _authService.verifyEmail(
        email: widget.email,
        code: _code,
      );

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toLoginAndClearStack(context);
        return;
      }
      setState(
        () => _errorMessage = response.errorFor('code') ?? response.message,
      );
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = FailureMessages.of(exception, l10n));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleResend() async {
    final AppLocalizations l10n = context.l10n;
    try {
      // Both flows re-issue a code through the same public endpoint.
      await _authService.forgotPassword(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.codeResent)),
        );
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _errorMessage = FailureMessages.of(exception, l10n));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AuthScreenScaffold(
      title: l10n.otpTitle,
      subtitle: l10n.otpSubtitle(widget.email),
      children: <Widget>[
        OtpBoxInput(
          onChanged: (String code) => _code = code,
        ),
        ErrorBanner(message: _errorMessage),
        const SizedBox(height: AppSpacing.md),
        Center(child: ResendCountdown(onResend: _handleResend)),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: _isSignup ? l10n.verifyButton : l10n.continueButton,
          isLoading: _isSubmitting,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
}
