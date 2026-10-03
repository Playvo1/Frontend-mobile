import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/amenity.dart';
import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'venue_photo.dart';

/// The venue card used on the search results screen. Same data as the home
/// card but with the navy "عرض التفاصيل" button instead of the orange
/// booking one, since this list leads to the venue page.
class VenueResultCard extends StatelessWidget {
  const VenueResultCard({
    super.key,
    required this.venue,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Venue venue;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 130,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: VenuePhoto(
                            url: venue.coverPhoto,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.sm + 2),
                          ),
                        ),
                        // start is the right side in Arabic, where the
                        // design puts the heart.
                        PositionedDirectional(
                          top: 6,
                          start: 6,
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
                                venue.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.navy300,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                venue.shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    textTheme.labelSmall?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Reads left to right as "★ 4.8 (120)", so in Arabic
                        // the review count comes first.
                        Row(
                          children: <Widget>[
                            Text(
                              '(${venue.reviewCount})',
                              textDirection: TextDirection.ltr,
                              style:
                                  textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              textDirection: TextDirection.ltr,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF5B400),
                            ),
                          ],
                        ),
                        if (venue.amenities.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 5),
                          _AmenityRow(amenities: venue.amenities),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: <Widget>[
                            Flexible(child: _Price(price: venue.hourlyPrice)),
                            const SizedBox(width: AppSpacing.sm),
                            ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.sm),
                                ),
                                textStyle: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(l10n.viewDetails),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The amenity strip under the rating: a small icon and label for each of
/// the first few facilities.
class _AmenityRow extends StatelessWidget {
  const _AmenityRow({required this.amenities});

  final List<Amenity> amenities;

  static IconData _iconFor(String? key) {
    switch (key) {
      case 'parking':
        return Icons.local_parking_outlined;
      case 'wc':
        return Icons.wc_outlined;
      case 'lockers':
        return Icons.person_outline;
      case 'lighting':
        return Icons.bolt_outlined;
      case 'turf':
        return Icons.grass_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Three is what fits on one line at the narrowest supported width.
    final List<Amenity> shown = amenities.take(3).toList();

    return Row(
      children: <Widget>[
        for (final Amenity amenity in shown) ...<Widget>[
          Icon(_iconFor(amenity.icon), size: 12, color: AppColors.navy300),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              amenity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.navy500),
            ),
          ),
          if (amenity != shown.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// "50 ₪ / ساعة" with the number picked out in orange.
class _Price extends StatelessWidget {
  const _Price({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$price ',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.orange500,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '₪ / ساعة',
            style: textTheme.labelSmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
