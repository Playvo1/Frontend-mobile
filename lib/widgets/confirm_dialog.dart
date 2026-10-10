import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The confirmation dialog used before an action that cannot be undone.
///
/// Returns true when the player confirms, false or null when they back out,
/// so the caller can simply check for true.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDestructive = true,
  });

  final IconData icon;
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;

  /// Paints the confirm button red, for actions that lose something.
  final bool isDestructive;

  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = true,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: icon,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color accent =
        isDestructive ? AppColors.statusCancelled : AppColors.navy900;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.statusCancelledBackground
                    : AppColors.navy50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: textTheme.headlineSmall?.copyWith(fontSize: 19)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(height: 1.7),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Confirm first, so it lands on the right as the design has it.
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successAccent,
                      side: const BorderSide(color: AppColors.successAccent),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(cancelLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
