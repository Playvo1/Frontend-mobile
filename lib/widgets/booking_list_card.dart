import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/booking.dart';
import '../models/venue.dart';
import '../screens/booking/booking_details_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'venue_photo.dart';

/// One reservation in "حجوزاتي": its status badge and reference, the venue,
/// the date/time/price strip, and the actions.
///
/// Only an upcoming booking shows "إلغاء الحجز"; a completed or cancelled
/// one is history and cannot be changed.
class BookingListCard extends StatelessWidget {
  const BookingListCard({
    super.key,
    required this.booking,
    required this.onViewDetails,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onViewDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Venue? venue = booking.venue;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _StatusBadge(status: booking.status),
              // Reads right to left: label, number, then the icon.
              Row(
                children: <Widget>[
                  Text(
                    l10n.bookingNumber,
                    style: textTheme.labelSmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    booking.reference,
                    textDirection: TextDirection.ltr,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.navy900,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 15,
                    color: AppColors.navy300,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      venue?.name ?? '',
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
                          size: 13,
                          color: AppColors.navy300,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            venue?.shortAddress ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 120,
                height: 78,
                child: VenuePhoto(
                  url: venue?.coverPhoto,
                  borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Facts(booking: booking),
          const SizedBox(height: AppSpacing.md),
          if (booking.isUpcoming)
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(l10n.viewDetails),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(l10n.cancelBooking),
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(l10n.viewDetails),
            ),
        ],
      ),
    );
  }
}

/// The coloured status pill: upcoming, completed, or cancelled.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    late final String label;
    late final Color color;
    late final Color background;
    late final IconData icon;

    switch (status) {
      case BookingStatus.completed:
        label = l10n.statusCompleted;
        color = AppColors.statusCompleted;
        background = AppColors.statusCompletedBackground;
        icon = Icons.check;
        break;
      case BookingStatus.cancelled:
        label = l10n.statusCancelled;
        color = AppColors.statusCancelled;
        background = AppColors.statusCancelledBackground;
        icon = Icons.close;
        break;
      default:
        label = l10n.statusUpcoming;
        color = AppColors.statusUpcoming;
        background = AppColors.statusUpcomingBackground;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 13, color: color),
        ],
      ),
    );
  }
}

/// The date, time and price strip inside the card.
class _Facts extends StatelessWidget {
  const _Facts({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime date = booking.date ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            _Fact(
              icon: Icons.calendar_today_outlined,
              label: l10n.labelDate,
              value: BookingHeader.formatWeekday(date),
              caption: BookingHeader.formatDayMonth(date),
            ),
            const VerticalDivider(width: 1),
            _Fact(
              icon: Icons.schedule,
              label: l10n.labelTime,
              value: booking.slot?.range ?? '',
              caption: _dayPart(context, booking),
              valueIsLtr: true,
            ),
            const VerticalDivider(width: 1),
            _Fact(
              icon: Icons.payments_outlined,
              label: l10n.labelPrice,
              value: l10n.priceShekel(booking.totalPrice ?? 0),
              caption: l10n.perHourShort,
            ),
          ],
        ),
      ),
    );
  }

  /// "صباحاً" or "مساءً" under the hour range, as the design shows.
  static String _dayPart(BuildContext context, Booking booking) {
    final String start = booking.slot?.startTime ?? '00:00';
    final int hour = int.tryParse(start.split(':').first) ?? 0;
    return hour < 12 ? context.l10n.morningShort : context.l10n.eveningShort;
  }
}

/// One column of the strip.
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
              Icon(icon, size: 12, color: AppColors.navy300),
              const SizedBox(width: 4),
              Text(label, style: textTheme.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 3),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
