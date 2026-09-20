import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable outlined text field used by every auth screen (and future
/// screens), so field styling only needs to change in one place. All visual
/// values come from the theme's InputDecorationTheme.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.leadingIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.hasError = false,
  });

  final String hint;
  final TextEditingController? controller;

  /// Rendered on the start side of the field, which RTL flips to the right
  /// automatically — matching the Arabic design.
  final IconData? leadingIcon;

  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  /// False greys the field out and blocks input — used while the account is
  /// locked out.
  final bool enabled;

  /// Paints the error border and tint without printing a message under the
  /// field. The login screen reports server-side failures in one shared
  /// message area instead of per field, as the design shows.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textAlign: TextAlign.start,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: leadingIcon == null
            ? null
            : Icon(
                leadingIcon,
                color: enabled ? AppColors.navy300 : AppColors.grey400,
                size: 20,
              ),
        suffixIcon: suffix,
        fillColor: _fillColor,
        enabledBorder: hasError ? _errorBorder(1) : null,
        focusedBorder: hasError ? _errorBorder(1.4) : null,
      ),
    );
  }

  Color? get _fillColor {
    if (!enabled) {
      return AppColors.fieldDisabled;
    }
    if (hasError) {
      return AppColors.errorBackground;
    }
    return null; // falls back to the theme
  }

  OutlineInputBorder _errorBorder(double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      borderSide: const BorderSide(color: AppColors.error).copyWith(
        width: width,
      ),
    );
  }
}

/// The show/hide eye button attached to every password field, so the three
/// screens that have one do not each rebuild it.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.isObscured,
    required this.onPressed,
  });

  final bool isObscured;

  /// Null greys the icon out and blocks the tap, matching a disabled field.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: onPressed == null ? AppColors.grey400 : AppColors.navy300,
        size: 20,
      ),
    );
  }
}
