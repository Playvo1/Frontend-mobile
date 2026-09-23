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

 enum OtpPurpose { signupVerification, passwordReset }

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
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  late final AuthService _authService =
      widget.authService ?? AuthService();

  String _code = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isSignup =>
      widget.purpose == OtpPurpose.signupVerification;

  Future<void> _handleSubmit() async {
    final AppLocalizations l10n = context.l10n;

    if (_code.length < AppConfig.verificationCodeLength) {
      setState(() => _errorMessage = l10n.otpIncomplete);
      return;
    }

    if (!_isSignup) {
      await _verifyResetOtp(l10n);
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
      final ApiResponse<void> response =
          await _authService.verifyEmail(
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
        () => _errorMessage =
            response.errorFor('code') ?? response.message,
      );
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

      setState(
        () => _errorMessage =
            FailureMessages.of(exception, l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyResetOtp(AppLocalizations l10n) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<void> response =
          await _authService.verifyResetOtp(
        email: widget.email,
        code: _code,
      );

      if (!mounted) {
        return;
      }

      if (response.success) {
        await AppRouter.toResetPassword(
          context,
          email: widget.email,
        );
        return;
      }

      setState(
        () => _errorMessage =
            response.errorFor('otp_code') ?? response.message,
      );
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

      setState(
        () => _errorMessage =
            FailureMessages.of(exception, l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleResend() async {
  final AppLocalizations l10n = context.l10n;

  try {
    if (_isSignup) {
      await _authService.sendOtp(widget.email);
    } else {
      await _authService.forgotPassword(widget.email);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeResent)),
      );
    }
  } on ApiException catch (exception) {
    if (mounted) {
      setState(
        () => _errorMessage =
            FailureMessages.of(exception, l10n),
      );
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
     onChanged: (String code) {
    _code = code.trim();
      print('OTP LENGTH: ${_code.length}');
    },
),
        ErrorBanner(message: _errorMessage),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ResendCountdown(
            onResend: _handleResend,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: _isSignup
              ? l10n.verifyButton
              : l10n.continueButton,
          isLoading: _isSubmitting,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
} 