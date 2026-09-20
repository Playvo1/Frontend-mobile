import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The "ليس لديك حساب؟ إنشاء حساب جديد" / "لديك حساب بالفعل؟ تسجيل الدخول"
/// line shown under the primary form on the login and signup screens.
class AuthFooterLink extends StatefulWidget {
  const AuthFooterLink({
    super.key,
    required this.leadingText,
    required this.actionText,
    required this.onTap,
  });

  final String leadingText;
  final String actionText;
  final VoidCallback onTap;

  @override
  State<AuthFooterLink> createState() => _AuthFooterLinkState();
}

class _AuthFooterLinkState extends State<AuthFooterLink> {
  // A TapGestureRecognizer holds native resources and must be disposed;
  // building one inline in build() leaks one per rebuild.
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = () => widget.onTap();
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Text.rich(
        TextSpan(
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.navy500,
            fontWeight: FontWeight.w400,
          ),
          children: <InlineSpan>[
            TextSpan(text: widget.leadingText),
            TextSpan(
              text: widget.actionText,
              style: const TextStyle(
                color: AppColors.linkText,
                fontWeight: FontWeight.w700,
              ),
              recognizer: _recognizer,
            ),
          ],
        ),
      ),
    );
  }
}
