import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'venue_photo.dart';

/// The card repeated at the top of the booking steps: the venue, then the
/// date, time and price of the slot being booked.
///
/// [showFacts] hides the three-column strip on the payment step, where the
/// design keeps only the venue line.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.venue,
    required this.dateLabel,
    required this.dateCaption,
    required this.timeLabel,
    required this.price,
    this.showFacts = true,
    this.heading,
  });

  final Venue venue;
  /// The weekday, e.g. "الأحد".
  final String dateLabel;

  /// The day and month under it, e.g. "14 سبتمبر".
  final String dateCaption;

  final String timeLabel;
  final int price;
  final bool showFacts;

  /// Optional title drawn inside the card, above the venue — the design
  /// puts "ملخص الحجز" there rather than above the box.
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: <Widget>[
          if (heading != null) ...<Widget>[
            Row(
              children: <Widget>[
                Text(
                  heading!,
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.navy500,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            // The design puts the photo on the LEFT here, unlike the list
            // cards, so it is the last child of the row. It keeps a fixed
            // landscape size instead of stretching to the text's height,
            // which would crop it into a tall narrow strip.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Without IntrinsicHeight around the row, this column has
                    // no height to fill, so it must size to its content.
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        venue.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF5B400),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.reviewsCount(venue.reviewCount),
                            style: textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 158,
                height: 100,
                child: VenuePhoto(
                  url: venue.coverPhoto,
                  borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                ),
              ),
            ],
          ),
          if (showFacts) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  _Fact(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.labelDate,
                    value: dateLabel,
                    caption: dateCaption,
                  ),
                  const VerticalDivider(width: 1),
                  _Fact(
                    icon: Icons.schedule,
                    label: l10n.labelTime,
                    value: timeLabel,
                    valueIsLtr: true,
                  ),
                  const VerticalDivider(width: 1),
                  _Fact(
                    icon: Icons.payments_outlined,
                    label: l10n.labelPrice,
                    value: l10n.priceShekel(price),
                    caption: l10n.perHourShort,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the three columns under the divider.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.valueIsLtr = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final bool valueIsLtr;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 13, color: AppColors.navy300),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            textDirection: valueIsLtr ? TextDirection.ltr : null,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (caption != null)
            Text(
              caption!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
