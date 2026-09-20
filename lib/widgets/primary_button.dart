import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The solid navy call-to-action button ("إنشاء حساب" / "تسجيل الدخول").
/// While [isLoading] it shows a spinner and refuses taps, so a slow network
/// cannot produce a double submission.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primaryButtonText,
              ),
            )
          : Text(label),
    );
  }
}
