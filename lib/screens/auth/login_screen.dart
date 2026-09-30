import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../models/auth_session.dart';
import '../../models/login_failure.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_footer_link.dart';
import '../../widgets/auth_screen_scaffold.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/google_button.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/primary_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../models/auth_session.dart';

/// Email + password sign-in, plus the Google entry point.
///
/// The screen has three states from the design: the plain form, a rejected
/// attempt (red fields, message, attempts left), and a locked account
/// (everything disabled, counting down to when the lock lifts).
///
/// Which state applies is the server's decision, taken from
/// USER.failed_login_attempts and USER.locked_until (Guidelines 2.4). This
/// screen only renders what the response says; it never counts attempts
/// itself, because a local counter resets with the app and would lie to the
/// player. The countdown ticks locally, but it is anchored to the
/// `locked_until` timestamp, so it cannot be cheated by a restart either.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AuthService _authService = widget.authService ?? AuthService();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  /// The sentence the server returned, or a connectivity message.
  String? _errorMessage;

  /// How many tries are left, as reported by the server.
  int? _remainingAttempts;

  /// When the lock lifts. Null means the account is not locked.
  DateTime? _lockedUntil;
  Duration _lockRemaining = Duration.zero;
  Timer? _lockTimer;

  /// True only when the server rejected the credentials, so a connectivity
  /// message does not paint the password field red.
  bool _credentialsRejected = false;

  bool get _isLocked =>
      _lockedUntil != null && _lockRemaining > Duration.zero;

  /// True whenever the form should be greyed out: mid-request, or locked.
  bool get _isInputDisabled => _isSubmitting || _isLocked;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLocked || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _remainingAttempts = null;
      _credentialsRejected = false;
    });

    try {
      final ApiResponse<AuthSession> response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toHomeAndClearStack(context);
        return;
      }
      _applyFailure(response);
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

  void _applyFailure(ApiResponse<AuthSession> response) {
    final LoginFailure failure = LoginFailure.fromResponse(response);
    final AppLocalizations l10n = context.l10n;

    // The server localizes `message` via the Accept-Language header we send;
    // the l10n strings are the fallback if it comes back empty.
    if (failure.isLocked) {
      _passwordController.clear();
      setState(() {
        _errorMessage =
            response.message.isEmpty ? l10n.accountLocked : response.message;
        _remainingAttempts = null;
        _credentialsRejected = false;
      });
      _startLockCountdown(failure.lockedUntil!);
      return;
    }

    setState(() {
      _errorMessage = response.message.isEmpty
          ? l10n.invalidCredentials
          : response.message;
      _remainingAttempts = failure.remainingAttempts;
      _credentialsRejected = true;
    });
  }

  void _startLockCountdown(DateTime lockedUntil) {
    _lockTimer?.cancel();
    setState(() {
      _lockedUntil = lockedUntil;
      _lockRemaining = lockedUntil.difference(DateTime.now());
    });

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final Duration left = lockedUntil.difference(DateTime.now());
      if (left <= Duration.zero) {
        timer.cancel();
        setState(() {
          _lockedUntil = null;
          _lockRemaining = Duration.zero;
          _errorMessage = null;
        });
        return;
      }
      setState(() => _lockRemaining = left);
    });
  }

  /// mm:ss, the format the design shows.
  String get _formattedLockRemaining {
    final int totalSeconds = _lockRemaining.inSeconds;
    final String minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String? _errorDetail(AppLocalizations l10n) {
    if (_isLocked) {
      return l10n.tryAgainIn(_formattedLockRemaining);
    }
    final int? attempts = _remainingAttempts;
    return attempts == null ? null : l10n.attemptsRemaining(attempts);
  }

Future<void> _handleGoogleLogin() async {
  setState(() {
    _isSubmitting = true;
    _errorMessage = null;
  });

  try {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();

    final GoogleSignInAccount account =
        await googleSignIn.authenticate();

    final GoogleSignInAuthentication authentication =
        account.authentication;

    final String? idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not get Google ID token.';
      });
      return;
    }

    final ApiResponse<AuthSession> response =
        await _authService.loginWithGoogle(idToken);

    if (!mounted) return;

    if (response.success) {
      await AppRouter.toHomeAndClearStack(context);
      return;
    }

    setState(() {
      _errorMessage = response.message;
    });
  } on ApiException catch (exception) {
    if (!mounted) return;

    setState(() {
      _errorMessage =
          FailureMessages.of(exception, context.l10n);
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool showFieldError = _credentialsRejected;

    return AuthScreenScaffold(
      formKey: _formKey,
      title: l10n.loginWelcome,
      subtitle: l10n.loginSubtitle,
      children: <Widget>[
        AppTextField(
          hint: l10n.emailHint,
          controller: _emailController,
          enabled: !_isInputDisabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          leadingIcon: Icons.mail_outline,
          validator: (String? value) => Validators.email(value, l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: l10n.passwordHint,
          controller: _passwordController,
          enabled: !_isInputDisabled,
          // Only the password is tinted red on a rejected attempt: we must
          // not hint that the email itself was wrong.
          hasError: showFieldError,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          leadingIcon: Icons.lock_outline,
          onFieldSubmitted: (_) => _handleLogin(),
          suffix: PasswordVisibilityToggle(
            isObscured: _obscurePassword,
            onPressed: _isInputDisabled
                ? null
                : () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (String? value) =>
              Validators.requiredPassword(value, l10n),
        ),
        const SizedBox(height: AppSpacing.sm),
        // The design puts this link on the left, which in Arabic is the
        // END of the line, not the start.
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => AppRouter.toForgotPassword(context),
            child: Text(l10n.forgotPassword),
          ),
        ),
        ErrorBanner(message: _errorMessage, detail: _errorDetail(l10n)),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.loginButton,
          isLoading: _isSubmitting,
          onPressed: _isLocked ? null : _handleLogin,
        ),
        const SizedBox(height: AppSpacing.lg),
        OrDivider(label: l10n.orLabel),
        const SizedBox(height: AppSpacing.xxl),
      GoogleButton(
     label: l10n.continueWithGoogle,
  isLoading: _isSubmitting,
  onPressed: _handleGoogleLogin,
),
        const SizedBox(height: AppSpacing.xl),
        AuthFooterLink(
          leadingText: l10n.noAccount,
          actionText: l10n.createAccountLink,
          onTap: () => AppRouter.toSignup(context),
        ),
      ],
    );
  }
}
