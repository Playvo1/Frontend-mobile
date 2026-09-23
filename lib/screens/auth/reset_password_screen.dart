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

/// Final step of the password-reset flow.
///
/// [email] and [code] are handed in by the OTP screen because
/// `POST /auth/reset-password` takes all three of email, code and the new
/// password in one request (Guidelines 7.2) — the code is single-use and is
/// consumed here, not earlier.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
  super.key,
  required this.email,
  this.authService,
});

final String email;
final AuthService? authService;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AuthService _authService = widget.authService ?? AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<void> response = await _authService.resetPassword(
       email: widget.email,
      password: _passwordController.text,
   );

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toResetSuccess(context);
        return;
      }
      // An expired or already-used code comes back on the `code` field.
     setState(
       () => _errorMessage =
      response.errorFor('password') ?? response.message,
    );
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
      title: l10n.resetTitle,
      subtitle: l10n.resetSubtitle,
      children: <Widget>[
        AppTextField(
          hint: l10n.newPasswordHint,
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newPassword],
          leadingIcon: Icons.lock_outline,
          suffix: PasswordVisibilityToggle(
            isObscured: _obscurePassword,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (String? value) => Validators.newPassword(value, l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: l10n.confirmNewPasswordHint,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          leadingIcon: Icons.lock_outline,
          onFieldSubmitted: (_) => _handleReset(),
          suffix: PasswordVisibilityToggle(
            isObscured: _obscureConfirmPassword,
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (String? value) => Validators.confirmPassword(
            value,
            _passwordController.text,
            l10n,
          ),
        ),
        ErrorBanner(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.resetButton,
          isLoading: _isSubmitting,
          onPressed: _handleReset,
        ),
      ],
    );
  }
}
