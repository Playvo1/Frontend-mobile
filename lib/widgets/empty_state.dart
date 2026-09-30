import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The illustration-plus-message block shown when a list has nothing in it
/// — bookings, favourites, and any list added later.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 170,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navy50,
                  ),
                ),
                Icon(icon, size: 66, color: AppColors.navy300),
                // The small magnifier the design tucks against the icon.
                PositionedDirectional(
                  bottom: 26,
                  start: 34,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 22,
                      color: AppColors.navy500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, textAlign: TextAlign.center, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
