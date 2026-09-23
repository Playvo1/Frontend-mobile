import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'venue_photo.dart';

/// One venue in the home list: photo, availability badge, name, address,
/// rating, hourly price, the favourite toggle and the booking button
/// (SRS FR-05 and FR-17).
///
/// Every row inside is ordered for Arabic, where the first child of a Row
/// sits on the RIGHT — so the name comes before the badge, and the price
/// before the button, to land them on the sides the design shows.
class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    required this.onTap,
    required this.onBook,
    required this.onToggleFavorite,
  });

  final Venue venue;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
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
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.navy900.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            // The photo stretches to whatever height the text needs, so a
            // two-line venue name can never clip it or overflow the row.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Thumbnail(venue: venue, onToggleFavorite: onToggleFavorite),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _Details(venue: venue, onBook: onBook)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The inset photo with the favourite heart on it.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.venue, required this.onToggleFavorite});

  final Venue venue;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: VenuePhoto(
              url: venue.coverPhoto,
              borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
            ),
          ),
          PositionedDirectional(
            top: 6,
            end: 6,
            child: InkWell(
              onTap: onToggleFavorite,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  venue.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 15,
                  color: venue.isFavorite
                      ? AppColors.orange500
                      : AppColors.navy500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything beside the photo.
class _Details extends StatelessWidget {
  const _Details({required this.venue, required this.onBook});

  final Venue venue;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Name on the right, badge pushed to the far left.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                venue.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            if (venue.isAvailableNow) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              const _AvailableBadge(),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: AppColors.navy300,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                venue.shortAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Score on the right, star to its left, as drawn.
        Row(
          children: <Widget>[
            Text(
              venue.rating.toStringAsFixed(1),
              textDirection: TextDirection.ltr,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.navy900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5B400)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Price on the right, booking button on the left.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.schedule,
                    size: 13,
                    color: AppColors.navy300,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      l10n.pricePerHour(venue.hourlyPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.navy900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _BookButton(label: l10n.bookNow, onPressed: onBook),
          ],
        ),
      ],
    );
  }
}

/// The green "متاح الآن" pill: label on the right, dot on the left.
class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.l10n.availableNow,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The small orange "احجز الآن" button.
class _BookButton extends StatelessWidget {
  const _BookButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange500,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
