import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The shared failure message area under the form: an alert icon, the
/// sentence the server returned, and an optional second line carrying the
/// detail — how many attempts are left, or how long the lock still has to
/// run.
///
/// Renders nothing when [message] is null, so a screen can keep it in the
/// tree unconditionally.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.detail});

  final String? message;

  /// Second line, shown in a lighter tone beneath [message].
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    if (text == null) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.error_outline,
                  size: 15,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: AppColors.orange300),
            ),
          ],
        ],
      ),
    );
  }
}
