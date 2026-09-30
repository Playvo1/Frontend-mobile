import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_config.dart';
import '../../core/country_codes.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../models/registration_result.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_footer_link.dart';
import '../../widgets/auth_screen_scaffold.dart';
import '../../widgets/country_code_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/google_button.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/primary_button.dart';
import 'otp_verification_screen.dart';

/// Player registration. On success the backend has already sent a
/// VERIFICATION_CODE, so the next stop is the OTP screen (Guidelines 7.2).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AuthService _authService = widget.authService ?? AuthService();

  CountryCode _country = CountryCodes.defaultCountry;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// The number as the backend wants it. By default that is exactly what
  /// the player typed, matching the API's own example; with
  /// [AppConfig.sendInternationalPhone] the dialling code is prefixed and
  /// the local leading zero dropped.
  String get _phoneForApi {
    final String typed = _phoneController.text.trim();
    if (typed.isEmpty || !AppConfig.sendInternationalPhone) {
      return typed;
    }
    return '${_country.dialCode}${typed.replaceFirst(RegExp(r'^0+'), '')}';
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();

    try {
      final ApiResponse<RegistrationResult> response =
          await _authService.register(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
        phone: _phoneForApi,
      );

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toOtpVerification(
          context,
          purpose: OtpPurpose.signupVerification,
          email: response.data?.email ?? email,
        );
        return;
      }
      // A 422 puts the detail in `errors`; the email field is the one that
      // usually fails (already registered), so show that when present.
      setState(
        () => _errorMessage = response.errorFor('email') ?? response.message,
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

  Future<void> _handleGoogleSignup() async {
    // TODO(auth): same google_sign_in flow as the login screen.
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AuthScreenScaffold(
      formKey: _formKey,
      title: l10n.signupTitle,
      subtitle: l10n.signupSubtitle,
      children: <Widget>[
        AppTextField(
          hint: l10n.fullNameHint,
          controller: _nameController,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.name],
          leadingIcon: Icons.person_outline,
          validator: (String? value) => Validators.fullName(value, l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: l10n.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          leadingIcon: Icons.mail_outline,
          validator: (String? value) => Validators.email(value, l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: l10n.phoneHint,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          leadingIcon: Icons.call_outlined,
          validator: (String? value) => Validators.optionalPhone(value, l10n),
          // The dialling code is a real picker, not a label: a player may
          // register with a number from any country.
          suffix: CountryCodeField(
            selected: _country,
            onChanged: (CountryCode country) =>
                setState(() => _country = country),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: l10n.passwordHint,
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
          hint: l10n.confirmPasswordHint,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          leadingIcon: Icons.lock_outline,
          onFieldSubmitted: (_) => _handleSignup(),
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
          label: l10n.createAccountButton,
          isLoading: _isSubmitting,
          onPressed: _handleSignup,
        ),
        const SizedBox(height: AppSpacing.lg),
        OrDivider(label: l10n.orLabel),
        const SizedBox(height: AppSpacing.lg),
        GoogleButton(
          label: l10n.continueWithGoogle,
          onPressed: _handleGoogleSignup,
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFooterLink(
          leadingText: l10n.haveAccount,
          actionText: l10n.loginLink,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
