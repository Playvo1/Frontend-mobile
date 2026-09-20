import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_screen_scaffold.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import 'otp_verification_screen.dart';

/// Asks for the account's email and requests a reset code.
///
/// The endpoint answers identically whether or not the email is registered
/// (Guidelines 7.2), so this screen must not branch on the result — any
/// success response moves on to code entry.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  late final AuthService _authService = widget.authService ?? AuthService();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();

    try {
      final ApiResponse<void> response =
          await _authService.forgotPassword(email);

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toOtpVerification(
          context,
          purpose: OtpPurpose.passwordReset,
          email: email,
        );
        return;
      }
      setState(() => _errorMessage = response.message);
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorMessage = FailureMessages.of(exception, context.l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AuthScreenScaffold(
      formKey: _formKey,
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
      children: <Widget>[
        AppTextField(
          hint: l10n.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.email],
          leadingIcon: Icons.mail_outline,
          onFieldSubmitted: (_) => _handleSendCode(),
          validator: (String? value) => Validators.email(value, l10n),
        ),
        ErrorBanner(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.sendCodeButton,
          isLoading: _isSubmitting,
          onPressed: _handleSendCode,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToLogin),
          ),
        ),
      ],
    );
  }
}
