import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/fixed_chevron.dart';
import '../theme/app_spacing.dart';

/// A card with a tinted icon tile, a title and a body — the shape repeated
/// across the privacy and security screens.
///
/// Tapping is optional: the same card is used as a link on the security
/// screen and as plain copy on the policy screens.
class InfoRowCard extends StatelessWidget {
  const InfoRowCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusField),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                  ),
                  child: Icon(icon, size: 21, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: textTheme.labelSmall?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  const FixedChevron(size: 19, color: AppColors.navy300),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft blue note that closes the privacy screens.
class InfoNoteCard extends StatelessWidget {
  const InfoNoteCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.successAccent,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.successAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(body, style: textTheme.labelSmall?.copyWith(height: 1.7)),
        ],
      ),
    );
  }
}
