import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_router.dart';
import '../../core/booking_share.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/venue.dart';
import '../booking/booking_details_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/venue_photo.dart';

/// One reservation in full (SRS FR-14): the venue, the slot, the price,
/// and the actions that still apply to it.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.onCancel,
    required this.onRate,
  });

  final Booking booking;

  /// Both are performed by the list screen, which owns the data, so this
  /// screen only asks.
  final VoidCallback onCancel;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Venue? venue = booking.venue;
    final DateTime date = booking.date ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: <Widget>[
            AppScreenHeader(title: l10n.bookingDetailsTitle, centerTitle: true),
            const SizedBox(height: AppSpacing.lg),
            if (venue != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusField),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: VenuePhoto(url: venue.coverPhoto),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _StatusRow(status: booking.status),
            const SizedBox(height: AppSpacing.lg),
            _Row(label: l10n.venueLabel, value: venue?.name ?? ''),
            _Row(label: l10n.labelDate, value: BookingHeader.formatDayMonth(date)),
            _Row(
              label: l10n.labelTime,
              value: booking.slot?.range ?? '',
              isLtr: true,
            ),
            _Row(
              label: l10n.totalLabel,
              value: l10n.priceShekel(booking.totalPrice ?? 0),
            ),
            if (booking.score != null)
              _Row(label: l10n.matchResult, value: booking.score!),
            const SizedBox(height: AppSpacing.md),
            _ReferenceRow(reference: booking.reference),
            const SizedBox(height: AppSpacing.xl),
            if (booking.isUpcoming)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: Text(l10n.cancelBooking),
              )
            else if (booking.awaitsRating)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRate();
                },
                child: Text(l10n.rateVenue),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () async {
                final bool shared = await BookingShare.share(booking, l10n);
                if (!shared && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareUnavailable)),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.ios_share, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.shareBooking),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (venue != null)
              TextButton(
                onPressed: () => AppRouter.toVenueDetails(context, venue.id),
                child: Text(l10n.viewDetails),
              ),
          ],
        ),
      ),
    );
  }
}

/// The coloured status pill on its own line.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    late final String label;
    late final Color color;
    late final Color background;
    switch (status) {
      case BookingStatus.completed:
        label = l10n.statusCompleted;
        color = AppColors.statusCompleted;
        background = AppColors.statusCompletedBackground;
        break;
      case BookingStatus.cancelled:
        label = l10n.statusCancelled;
        color = AppColors.statusCancelled;
        background = AppColors.statusCancelledBackground;
        break;
      default:
        label = l10n.statusUpcoming;
        color = AppColors.statusUpcoming;
        background = AppColors.statusUpcomingBackground;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          l10n.bookingStatusLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// A label on one edge and its value on the other, divided from the next.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isLtr = false});

  final String label;
  final String value;

  /// Clock ranges read left to right even in Arabic.
  final bool isLtr;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: textTheme.labelMedium),
              Flexible(
                child: Text(
                  value,
                  textDirection: isLtr ? TextDirection.ltr : null,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// The reference with a copy button, as on the confirmation screen.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      ),
      child: Row(
        children: <Widget>[
          Text(
            l10n.bookingNumber,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reference,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
            ),
          ),
          IconButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: reference)),
            icon: const Icon(Icons.copy_outlined, size: 19),
            color: AppColors.navy500,
          ),
        ],
      ),
    );
  }
}
