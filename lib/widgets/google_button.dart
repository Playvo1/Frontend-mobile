import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "المتابعة باستخدام Google" outlined button. Falls back to an icon if the
/// asset is missing, so a packaging mistake never shows a broken image.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
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
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label),
          const SizedBox(width: AppSpacing.sm),
          Image.asset(
            'assets/logo/google_logo.png',
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.g_mobiledata,
              size: 22,
              color: AppColors.navy500,
            ),
          ),
        ],
      ),
    );
  }
}
