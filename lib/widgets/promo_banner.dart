import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'venue_photo.dart';

/// The "احجز ملعبك الآن" banner under the search box.
///
/// Two halves, as the design draws it: the photo shows through untouched on
/// the outer side, and a solid navy panel carries the text on the reading
/// side. The navy is a gradient only across the short seam between them, so
/// there is no hard vertical line over the picture.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.onPressed,
    this.imageUrl = defaultImage,
  });

  /// Bundled so the banner still looks right with no network.
  static const String defaultImage = 'assets/venues/promo.jpg';

  final VoidCallback onPressed;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: VenuePhoto(url: imageUrl)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  // Starts on the reading side: solid navy over the text,
                  // gone by the time it reaches the photo.
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  stops: <double>[0, 0.52, 0.70],
                  colors: <Color>[
                    AppColors.navy900,
                    AppColors.navy900,
                    Color(0x0001213D),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                // Keeps the wrapped subtitle inside the navy area instead of
                // running across the photo.
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.promoTitle,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.promoSubtitle,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.navy100,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StartBookingButton(
                        label: l10n.promoCta,
                        onPressed: onPressed,
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 45, child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The orange call to action, with the chevron trailing the label.
class _StartBookingButton extends StatelessWidget {
  const _StartBookingButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange500,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_left, size: 18),
        ],
      ),
    );
  }
}
