import 'package:flutter/material.dart';

import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_text_field.dart';

/// "كلمة المرور" — changing the password from inside the account.
///
/// TODO(api): there is no change-password endpoint in the collection; the
/// reset flow is the only one that exists. Point [_submit] at it once the
/// backend adds one.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.passwordChanged)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: <Widget>[
              AppScreenHeader(
                title: l10n.changePasswordTitle,
                subtitle: l10n.changePasswordSubtitle,
                centerTitle: true,
              ),
              // The design leaves a clear gap between the heading block and
              // the first field.
              const SizedBox(height: 56),
              _Label(text: l10n.currentPasswordLabel),
              AppTextField(
                hint: l10n.currentPasswordHint,
                controller: _currentController,
                obscureText: _obscureCurrent,
                leadingIcon: Icons.lock_outline,
                suffix: PasswordVisibilityToggle(
                  isObscured: _obscureCurrent,
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (String? value) =>
                    Validators.requiredPassword(value, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.newPasswordLabel),
              AppTextField(
                hint: l10n.newPasswordPlaceholder,
                controller: _newController,
                obscureText: _obscureNew,
                leadingIcon: Icons.lock_outline,
                suffix: PasswordVisibilityToggle(
                  isObscured: _obscureNew,
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (String? value) =>
                    Validators.newPassword(value, l10n),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.passwordRuleHint,
                style: textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.confirmNewPasswordLabel),
              AppTextField(
                hint: l10n.confirmNewPasswordPlaceholder,
                controller: _confirmController,
                obscureText: _obscureConfirm,
                leadingIcon: Icons.lock_outline,
                suffix: PasswordVisibilityToggle(
                  isObscured: _obscureConfirm,
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (String? value) => Validators.confirmPassword(
                  value,
                  _newController.text,
                  l10n,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.changePasswordButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A required-field caption.
class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.navy900),
          ),
          const Text(
            ' *',
            style: TextStyle(color: AppColors.orange500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
